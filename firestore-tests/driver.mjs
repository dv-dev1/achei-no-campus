// Dirige o build web pelo CDP do navegador, falando com a árvore de semantics
// do Flutter: é o único DOM que o CanvasKit expõe, e ela só nasce depois do
// clique no `flt-semantics-placeholder`.
import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import { dirname, extname, join, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const raiz = resolve(dirname(fileURLToPath(import.meta.url)), '../build/web');
const tipos = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
};

const pausa = (ms = 100) => new Promise((pronto) => setTimeout(pronto, ms));

export async function esperarPor(verificar, descricao, limite = 20000) {
  const fim = Date.now() + limite;
  let ultimo;
  while (Date.now() < fim) {
    ultimo = await verificar();
    if (ultimo) return ultimo;
    await pausa();
  }
  throw new Error(`Tempo esgotado esperando ${descricao}.`);
}

function servir() {
  const servidor = createServer(async (pedido, resposta) => {
    const caminho = new URL(pedido.url, 'http://localhost').pathname;
    const arquivo = resolve(raiz, `.${caminho === '/' ? '/index.html' : caminho}`);
    try {
      if (!arquivo.startsWith(`${raiz}${sep}`)) throw new Error('fora da raiz');
      const corpo = await readFile(arquivo);
      resposta.writeHead(200, { 'Content-Type': tipos[extname(arquivo)] ?? 'application/octet-stream' });
      resposta.end(corpo);
    } catch {
      resposta.writeHead(404).end();
    }
  });
  return new Promise((pronto) => servidor.listen(0, '127.0.0.1', () => pronto(servidor)));
}

// O Edge vem instalado no Windows e fala o mesmo CDP: serve quando falta o Chrome.
function candidatos(plataforma, env) {
  if (plataforma === 'darwin') {
    return ['Google Chrome', 'Microsoft Edge', 'Chromium'].map((nome) => `/Applications/${nome}.app/Contents/MacOS/${nome}`);
  }
  if (plataforma === 'win32') {
    return [env.PROGRAMFILES, env['PROGRAMFILES(X86)'], env.LOCALAPPDATA].filter(Boolean).flatMap((base) => [
      join(base, 'Google/Chrome/Application/chrome.exe'),
      join(base, 'Microsoft/Edge/Application/msedge.exe'),
    ]);
  }
  return null;
}

export function caminhoDoNavegador(plataforma = process.platform, env = process.env, existe = existsSync) {
  if (env.CHROME_BIN) return env.CHROME_BIN;
  const lista = candidatos(plataforma, env);
  if (!lista) return 'google-chrome';
  const achado = lista.find((caminho) => existe(caminho));
  if (achado) return achado;
  throw new Error(`Nenhum Chrome ou Edge encontrado em: ${lista.join(', ')}. Defina CHROME_BIN com o caminho do navegador.`);
}

async function conectar(perfil) {
  const porta = await esperarPor(
    async () => (await readFile(join(perfil, 'DevToolsActivePort'), 'utf8').catch(() => '')).split('\n')[0],
    'o navegador abrir a porta de depuração',
  );
  const alvos = await (await fetch(`http://127.0.0.1:${porta}/json/list`)).json();
  const socket = new WebSocket(alvos.find((alvo) => alvo.type === 'page').webSocketDebuggerUrl);
  await new Promise((pronto) => socket.addEventListener('open', pronto, { once: true }));
  return socket;
}

/// Abre uma aba com o app servido do `build/web`. Cada aba tem perfil próprio,
/// então duas abas valem como dois aparelhos diferentes no mesmo teste.
export async function abrirApp() {
  const servidor = await servir();
  const perfil = await mkdtemp(join(tmpdir(), 'achei-web-'));
  const navegador = spawn(caminhoDoNavegador(), [
    '--headless=new', '--remote-debugging-address=127.0.0.1', '--remote-debugging-port=0',
    `--user-data-dir=${perfil}`, '--no-first-run', '--no-default-browser-check',
    '--window-size=1280,900',
    ...(process.env.CI ? ['--no-sandbox'] : []), 'about:blank',
  ], { stdio: 'ignore' });
  let erroDeInicio;
  navegador.on('error', (erro) => { erroDeInicio = erro; });

  let socket;
  try {
    socket = await conectar(perfil);
  } catch (erro) {
    navegador.kill();
    await new Promise((pronto) => servidor.close(pronto));
    throw erroDeInicio ?? erro;
  }

  const pendentes = new Map();
  const pedidosRemotos = [];
  // Erro no console é a única pista quando a tela fica num spinner e nada diz
  // o motivo: a regra negada aparece aqui, não na árvore de semantics.
  const errosDoConsole = [];
  let proximo = 0;
  socket.addEventListener('message', (evento) => {
    const mensagem = JSON.parse(evento.data);
    if (mensagem.method === 'Network.requestWillBeSent') {
      const url = new URL(mensagem.params.request.url);
      if (/^(identitytoolkit|securetoken|firestore)\.googleapis\.com$/.test(url.hostname)) pedidosRemotos.push(url.origin);
    }
    if (mensagem.method === 'Runtime.consoleAPICalled' && ['error', 'warning'].includes(mensagem.params.type)) {
      errosDoConsole.push(mensagem.params.args.map((arg) => arg.value ?? arg.description ?? '').join(' '));
    }
    if (mensagem.method === 'Runtime.exceptionThrown') {
      errosDoConsole.push(mensagem.params.exceptionDetails.exception?.description ?? 'exceção sem descrição');
    }
    if (!mensagem.id) return;
    const chamada = pendentes.get(mensagem.id);
    pendentes.delete(mensagem.id);
    mensagem.error ? chamada.reject(new Error(JSON.stringify(mensagem.error))) : chamada.resolve(mensagem.result);
  });

  const enviar = (metodo, parametros = {}) => new Promise((pronto, falhou) => {
    pendentes.set(++proximo, { resolve: pronto, reject: falhou });
    socket.send(JSON.stringify({ id: proximo, method: metodo, params: parametros }));
  });

  const avaliar = async (expressao) => {
    const resultado = await enviar('Runtime.evaluate', { expression: expressao, returnByValue: true, awaitPromise: true });
    if (resultado.exceptionDetails) {
      throw new Error(resultado.exceptionDetails.exception?.description ?? JSON.stringify(resultado.exceptionDetails));
    }
    return resultado.result.value;
  };

  // Sem isto o Flutter nunca monta o DOM de semantics, e não há o que clicar.
  const ligarSemantics = async () => {
    await esperarPor(() => avaliar(`!!document.querySelector('flt-semantics-placeholder')`), 'o placeholder de semantics');
    await avaliar(`document.querySelector('flt-semantics-placeholder').click()`);
    await esperarPor(() => avaliar(`document.querySelectorAll('flt-semantics').length > 0`), 'a árvore de semantics');
  };

  const pronto = async () => {
    await esperarPor(
      () => avaliar('typeof firebase_auth !== "undefined" && firebase_core.getApps().length > 0'),
      'o Firebase do app carregar',
    );
    await avaliar('firebase_auth.getAuth().authStateReady()');
    if (pedidosRemotos.length > 0) throw new Error(`O app acessou Firebase real: ${pedidosRemotos.join(', ')}`);
    await ligarSemantics();
  };

  // Rótulo de um nó é o `aria-label`, ou o texto quando ele é folha: nó pai
  // concatena o texto de todos os filhos e nunca bate com um rótulo só.
  const comoRotulo = `((no) => (no.getAttribute('aria-label') || (no.childElementCount === 0 ? no.textContent : '') || '').trim())`;

  const todos = `[...(document.querySelector('flt-semantics-host') ?? document.body).querySelectorAll('*')]`;

  const rotulos = () => avaliar(`${todos}.map(${comoRotulo}).filter((texto) => texto.length > 0)`);

  const achar = (rotulo) => `${todos}.find((no) => ${comoRotulo}(no) === ${JSON.stringify(rotulo)})`;

  // O título da AppBar costuma repetir o texto do botão. Clicar no primeiro nó
  // que casa acerta o título e não faz nada: botão primeiro, resto depois.
  const acharClicavel = (rotulo) => `(() => {
    const casam = ${todos}.filter((no) => ${comoRotulo}(no) === ${JSON.stringify(rotulo)});
    return casam.find((no) => no.getAttribute('role') === 'button' || no.getAttribute('flt-tappable') !== null) ?? casam[0];
  })()`;

  const esperarRotulo = (rotulo) => esperarPor(
    async () => (await rotulos()).includes(rotulo),
    `o rótulo ${JSON.stringify(rotulo)} aparecer na tela`,
  );

  const tocar = async (rotulo) => {
    await esperarRotulo(rotulo);
    await esperarPor(
      () => avaliar(`(() => { const no = ${acharClicavel(rotulo)}; if (!no) return false; no.click(); return true; })()`),
      `clicar no rótulo ${JSON.stringify(rotulo)}`,
    );
    await pausa(400);
  };

  /// Um `DropdownButtonFormField` expõe o rótulo e o valor escolhido no mesmo
  /// texto, em duas linhas, então casar o texto inteiro falha: basta o começo.
  const tocarComecandoCom = async (prefixo) => {
    await esperarPor(
      async () => (await rotulos()).some((texto) => texto.startsWith(prefixo)),
      `um rótulo começando com ${JSON.stringify(prefixo)}`,
    );
    await avaliar(`(() => {
      const casam = ${todos}.filter((no) => ${comoRotulo}(no).startsWith(${JSON.stringify(prefixo)}));
      const alvo = casam.find((no) => no.getAttribute('role') === 'button') ?? casam[0];
      alvo.click();
      return true;
    })()`);
    await pausa(400);
  };

  // O `<input>` de um campo de busca pode ficar fora do host de semantics, então
  // procurar o campo de texto no documento inteiro é o que acha os dois casos.
  const acharCampo = (rotulo) => `(() => {
    const direto = document.querySelector('input[aria-label=' + ${JSON.stringify(JSON.stringify(rotulo))} + '], textarea[aria-label=' + ${JSON.stringify(JSON.stringify(rotulo))} + ']');
    if (direto) return direto;
    const no = ${achar(rotulo)};
    if (!no) return null;
    return no.querySelector('input, textarea') ?? no;
  })()`;

  /// O card do feed vira um rótulo só, com tipo, título, categoria e tempo em
  /// linhas diferentes. Casar por trecho é o que funciona nele.
  const textos = async (trecho) => (await rotulos()).filter((texto) => texto.includes(trecho));

  const esperarTexto = (trecho) => esperarPor(
    async () => (await textos(trecho)).length > 0,
    `um rótulo contendo ${JSON.stringify(trecho)} aparecer na tela`,
  );

  const tem = async (trecho) => (await textos(trecho)).length > 0;

  const tocarContendo = async (trecho) => {
    await esperarTexto(trecho);
    await avaliar(`(() => {
      const casam = ${todos}.filter((no) => ${comoRotulo}(no).includes(${JSON.stringify(trecho)}));
      const alvo = casam.find((no) => no.getAttribute('role') === 'button') ?? casam[casam.length - 1];
      alvo.click();
      return true;
    })()`);
    await pausa(500);
  };

  // Ao focar um campo, o Flutter troca o elemento de edição e o `aria-label` sai
  // com ele: o campo em edição é o `activeElement`, não mais o do rótulo.
  const valorDe = (rotulo) => avaliar(`(() => {
    const entrada = ${acharCampo(rotulo)};
    if (entrada && typeof entrada.value === 'string') return entrada.value;
    const ativo = document.activeElement;
    return ativo && (ativo.tagName === 'INPUT' || ativo.tagName === 'TEXTAREA') ? ativo.value : null;
  })()`);

  // O evento `input` sintético e o `Input.insertText` não chegam ao Flutter: ele
  // só lê o campo que ele mesmo focou. Clicar no `<input>` da árvore de
  // semantics e mandar evento `char` por caractere é o caminho que funciona.
  // Só `char`: somar `keyDown` com `text` insere cada letra duas vezes.
  const digitar = async (rotulo, texto) => {
    await esperarRotulo(rotulo);
    await esperarPor(
      () => avaliar(`(() => {
        const entrada = ${acharCampo(rotulo)};
        if (!entrada) return false;
        entrada.click();
        entrada.focus();
        return true;
      })()`),
      `focar o campo ${JSON.stringify(rotulo)}`,
    );
    await pausa(600);
    // A primeira tecla depois do clique é gasta ligando a edição no Flutter.
    // Shift não insere nada e serve de isca para a letra seguinte valer.
    await enviar('Input.dispatchKeyEvent', { type: 'rawKeyDown', key: 'Shift', windowsVirtualKeyCode: 16 });
    await enviar('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Shift', windowsVirtualKeyCode: 16 });
    await pausa(150);
    for (const letra of texto) {
      await enviar('Input.dispatchKeyEvent', { type: 'char', text: letra, unmodifiedText: letra, key: letra });
    }
    await pausa(300);
    const escrito = await valorDe(rotulo);
    if (escrito !== texto) throw new Error(`Campo ${JSON.stringify(rotulo)} ficou com ${JSON.stringify(escrito)}, não com ${JSON.stringify(texto)}.`);
  };

  /// Apaga o que já estava no campo antes de digitar: a tela de perfil abre com
  /// o nome salvo, e digitar por cima concatenaria os dois.
  const digitarSubstituindo = async (rotulo, texto) => {
    await esperarRotulo(rotulo);
    await esperarPor(
      () => avaliar(`(() => {
        const entrada = ${acharCampo(rotulo)};
        if (!entrada) return false;
        entrada.click();
        entrada.focus();
        return true;
      })()`),
      `focar o campo ${JSON.stringify(rotulo)}`,
    );
    await pausa(600);
    await enviar('Input.dispatchKeyEvent', { type: 'keyDown', key: 'a', code: 'KeyA', windowsVirtualKeyCode: 65, modifiers: 2 });
    await enviar('Input.dispatchKeyEvent', { type: 'keyUp', key: 'a', code: 'KeyA', windowsVirtualKeyCode: 65, modifiers: 2 });
    await enviar('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Delete', code: 'Delete', windowsVirtualKeyCode: 46 });
    await enviar('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Delete', code: 'Delete', windowsVirtualKeyCode: 46 });
    await pausa(200);
    for (const letra of texto) {
      await enviar('Input.dispatchKeyEvent', { type: 'char', text: letra, unmodifiedText: letra, key: letra });
    }
    await pausa(300);
    const escrito = await valorDe(rotulo);
    if (escrito !== texto) throw new Error(`Campo ${JSON.stringify(rotulo)} ficou com ${JSON.stringify(escrito)}, não com ${JSON.stringify(texto)}.`);
  };

  const fechar = async () => {
    socket.close();
    navegador.kill();
    await new Promise((resolvido) => navegador.exitCode !== null ? resolvido() : navegador.once('exit', resolvido));
    await new Promise((resolvido) => servidor.close(resolvido));
    await rm(perfil, { recursive: true, force: true, maxRetries: 3, retryDelay: 100 });
  };

  await enviar('Network.enable');
  await enviar('Runtime.enable');
  await enviar('Page.navigate', { url: `http://127.0.0.1:${servidor.address().port}` });
  await pronto();

  return { avaliar, enviar, rotulos, esperarRotulo, esperarTexto, tem, tocar, tocarComecandoCom, tocarContendo, digitar, digitarSubstituindo, valorDe, fechar, pedidosRemotos, errosDoConsole,
    recarregar: async () => { await enviar('Page.reload', { ignoreCache: true }); await pronto(); } };
}

/// Marca o e-mail como verificado pelo endpoint de administrador do emulador de
/// Auth: o e-mail de verificação não sai de verdade, então é o único caminho.
export async function verificarEmail(uid) {
  const projeto = 'demo-achei-no-campus';
  const resposta = await fetch(
    `http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/projects/${projeto}/accounts:update`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: 'Bearer owner' },
      body: JSON.stringify({ localId: uid, emailVerified: true }),
    },
  );
  if (!resposta.ok) throw new Error(`Falha ao verificar o e-mail: ${resposta.status} ${await resposta.text()}`);
}

/// Apaga todos os documentos do emulador de Firestore. O feed mostra o que
/// qualquer pessoa publicou, então um caso de filtro só é previsível com o
/// banco limpo antes dele.
export async function limparBanco() {
  const projeto = 'demo-achei-no-campus';
  const resposta = await fetch(
    `http://127.0.0.1:8080/emulator/v1/projects/${projeto}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  if (!resposta.ok) throw new Error(`Falha ao limpar o Firestore: ${resposta.status} ${await resposta.text()}`);
}

/// Conta documentos de uma coleção pelo REST do emulador, como administrador.
/// Pelo cliente não dá: as regras negam listar `conversas` inteira, e é isso
/// que elas devem fazer.
export async function contarColecao(nome) {
  const projeto = 'demo-achei-no-campus';
  const resposta = await fetch(
    `http://127.0.0.1:8080/v1/projects/${projeto}/databases/(default)/documents/${nome}`,
    { headers: { Authorization: 'Bearer owner' } },
  );
  if (!resposta.ok) throw new Error(`Falha ao ler ${nome}: ${resposta.status} ${await resposta.text()}`);
  const corpo = await resposta.json();
  return corpo.documents?.length ?? 0;
}
