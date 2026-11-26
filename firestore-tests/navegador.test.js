import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import test from 'node:test';

import { abrirApp, caminhoDoNavegador } from './driver.mjs';

const windows = { PROGRAMFILES: 'C:/Program Files', 'PROGRAMFILES(X86)': 'C:/Program Files (x86)' };
const edge = join(windows['PROGRAMFILES(X86)'], 'Microsoft/Edge/Application/msedge.exe');

test('CHROME_BIN vence qualquer caminho conhecido', () => {
  assert.equal(caminhoDoNavegador('win32', { ...windows, CHROME_BIN: 'D:/chrome.exe' }, () => false), 'D:/chrome.exe');
});

test('Windows sem Chrome cai no Edge', () => {
  assert.equal(caminhoDoNavegador('win32', windows, (caminho) => caminho === edge), edge);
});

test('sem navegador, o erro diz como apontar um', () => {
  assert.throws(() => caminhoDoNavegador('win32', windows, () => false), /CHROME_BIN/);
});

test('CHROME_BIN inexistente faz o abrirApp falhar logo, citando CHROME_BIN', { timeout: 20000 }, async () => {
  const anterior = process.env.CHROME_BIN;
  process.env.CHROME_BIN = join(tmpdir(), 'achei-sem-navegador', 'chrome-que-nao-existe');
  const inicio = Date.now();
  try {
    await assert.rejects(abrirApp(), (erro) => {
      assert.match(erro.message, /CHROME_BIN/);
      return true;
    });
    assert.ok(Date.now() - inicio < 5000, `levou ${Date.now() - inicio} ms para falhar`);
  } finally {
    if (anterior === undefined) delete process.env.CHROME_BIN;
    else process.env.CHROME_BIN = anterior;
  }
});

function motivoParaPular() {
  try {
    const caminho = caminhoDoNavegador();
    if (process.env.CHROME_BIN && !existsSync(caminho)) return `CHROME_BIN não existe: ${caminho}`;
    return false;
  } catch (erro) {
    return erro.message;
  }
}

test('abrirApp que estoura o prazo fecha o navegador e o servidor, e o processo sai sozinho', { timeout: 60000, skip: motivoParaPular() }, async () => {
  const raiz = await mkdtemp(join(tmpdir(), 'achei-raiz-vazia-'));
  const driver = pathToFileURL(fileURLToPath(new URL('./driver.mjs', import.meta.url))).href;
  const roteiro = `
    const { abrirApp } = await import(${JSON.stringify(driver)});
    try {
      await abrirApp({ raiz: process.env.RAIZ_VAZIA, limite: 2000 });
      console.log('ABRIU');
    } catch (erro) {
      console.log('ERRO: ' + erro.message);
    }
  `;
  const filho = spawn(process.execPath, ['--input-type=module', '-e', roteiro], {
    env: { ...process.env, RAIZ_VAZIA: raiz },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  let saida = '';
  filho.stdout.on('data', (pedaco) => { saida += pedaco; });
  filho.stderr.on('data', (pedaco) => { saida += pedaco; });
  const inicio = Date.now();
  let travou = false;
  const prazo = setTimeout(() => { travou = true; filho.kill(); }, 30000);
  try {
    await new Promise((pronto) => filho.once('close', pronto));
    assert.ok(!travou, `o processo filho não saiu em 30 s; saída: ${saida}`);
    assert.match(saida, /ERRO: Tempo esgotado esperando o Firebase do app carregar/, saida);
    assert.ok(Date.now() - inicio < 30000, `levou ${Date.now() - inicio} ms para sair`);
  } finally {
    clearTimeout(prazo);
    await rm(raiz, { recursive: true, force: true });
  }
});
