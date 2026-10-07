import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import { dirname, extname, join, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../build/web');
const pause = () => new Promise((resolve) => setTimeout(resolve, 100));
async function waitFor(check) {
  const end = Date.now() + 30000;
  while (Date.now() < end) {
    const result = await check();
    if (result) return result;
    await pause();
  }
  throw new Error('Tempo esgotado ao iniciar o Chrome ou restaurar a sessão.');
}

test('Auth permanece no emulador e restaura o usuário após recarregar o build web', { timeout: 90000 }, async () => {
  const mime = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm' };
  const server = createServer(async (request, response) => {
    const path = new URL(request.url, 'http://localhost').pathname;
    const file = resolve(root, `.${path === '/' ? '/index.html' : path}`);
    try {
      assert.ok(file.startsWith(`${root}${sep}`));
      const body = await readFile(file);
      response.writeHead(200, { 'Content-Type': mime[extname(file)] ?? 'application/octet-stream' });
      response.end(body);
    } catch {
      response.writeHead(404).end();
    }
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const profile = await mkdtemp(join(tmpdir(), 'achei-chrome-'));
  const chromePath = process.env.CHROME_BIN ?? (process.platform === 'darwin'
    ? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
    : process.platform === 'win32'
      ? join(process.env.PROGRAMFILES, 'Google/Chrome/Application/chrome.exe')
      : 'google-chrome');
  const chrome = spawn(chromePath, [
    '--headless=new', '--remote-debugging-address=127.0.0.1', '--remote-debugging-port=0',
    `--user-data-dir=${profile}`, '--no-first-run', '--no-default-browser-check',
    ...(process.env.CI ? ['--no-sandbox'] : []), 'about:blank',
  ], { stdio: 'ignore' });
  let startupError;
  chrome.on('error', (error) => { startupError = error; });
  let socket;
  try {
    const port = await waitFor(async () => {
      if (startupError) throw startupError;
      return (await readFile(join(profile, 'DevToolsActivePort'), 'utf8').catch(() => '')).split('\n')[0];
    });
    const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
    socket = new WebSocket(targets.find((target) => target.type === 'page').webSocketDebuggerUrl);
    await new Promise((resolve) => socket.addEventListener('open', resolve, { once: true }));
    const pending = new Map();
    const remoteRequests = [];
    let id = 0;
    socket.addEventListener('message', (event) => {
      const message = JSON.parse(event.data);
      if (message.method === 'Network.requestWillBeSent') {
        const url = new URL(message.params.request.url);
        if (/^(identitytoolkit|securetoken|firestore)\.googleapis\.com$/.test(url.hostname)) remoteRequests.push(url.origin);
      }
      if (!message.id) return;
      const call = pending.get(message.id);
      pending.delete(message.id);
      message.error ? call.reject(message.error) : call.resolve(message.result);
    });
    const send = (method, params = {}) => new Promise((resolve, reject) => {
      pending.set(++id, { resolve, reject });
      socket.send(JSON.stringify({ id, method, params }));
    });
    const evaluate = async (expression) => {
      const result = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
      assert.equal(result.exceptionDetails, undefined, JSON.stringify(result.exceptionDetails));
      return result.result.value;
    };
    const ready = async () => {
      await waitFor(() => evaluate('typeof firebase_auth !== "undefined" && firebase_core.getApps().length > 0'));
      await evaluate('firebase_auth.getAuth().authStateReady()');
      assert.deepEqual(remoteRequests, [], 'O app tentou acessar Firebase real.');
      assert.equal(await evaluate('firebase_auth.getAuth().emulatorConfig?.port'), 9099);
    };
    await send('Network.enable');
    await send('Page.navigate', { url: `http://127.0.0.1:${server.address().port}` });
    await ready();
    const uid = await evaluate(`(async () => {
      const credential = await firebase_auth.createUserWithEmailAndPassword(firebase_auth.getAuth(), 'reload.${Date.now()}@cs.unipe.edu.br', 'senha-local-123');
      return credential.user.uid;
    })()`);
    await send('Page.reload', { ignoreCache: true });
    await ready();
    assert.equal(await evaluate('firebase_auth.getAuth().currentUser?.uid'), uid);
    assert.deepEqual(remoteRequests, [], 'O app tentou acessar Firebase real.');
    await evaluate('firebase_auth.signOut(firebase_auth.getAuth())');
  } finally {
    socket?.close();
    chrome.kill();
    await new Promise((resolve) => chrome.exitCode !== null || startupError ? resolve() : chrome.once('exit', resolve));
    await new Promise((resolve) => server.close(resolve));
    await rm(profile, { recursive: true, force: true, maxRetries: 3, retryDelay: 100 });
  }
});
