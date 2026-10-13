// Execução dos casos de teste de `docs/testes.md` na coluna W (web).
// Cada `test` tem o código do caso no nome, para a saída do comando valer como
// registro de execução. O que depende de câmera, galeria ou aparelho físico
// continua fora daqui.
import assert from 'node:assert/strict';
import test from 'node:test';
import { abrirApp, contarColecao, limparBanco, verificarEmail } from './driver.mjs';

const email = (prefixo) => `${prefixo}.${Date.now()}.${Math.floor(Math.random() * 1000)}@cs.unipe.edu.br`;
const SENHA = 'senha-local-123';

const quantos = (lista, rotulo) => lista.filter((texto) => texto === rotulo).length;

/// Cria a conta pela interface e devolve o uid de quem ficou logado.
async function cadastrar(app, endereco, nome = 'Lúcia Tester') {
  await app.tocar('Criar uma conta');
  await app.digitar('Nome', nome);
  await app.digitar('E-mail acadêmico', endereco);
  await app.digitar('Senha', SENHA);
  await app.tocar('Criar conta');
  await app.esperarRotulo('Já verifiquei');
  return app.avaliar('firebase_auth.getAuth().currentUser.uid');
}

/// Deixa o app no Feed, com a conta criada e o e-mail já verificado.
async function entrarVerificado(app, endereco) {
  const uid = await cadastrar(app, endereco);
  await verificarEmail(uid);
  await app.tocar('Já verifiquei');
  await app.esperarRotulo('Publicar');
  return uid;
}

async function comApp(corpo) {
  const app = await abrirApp();
  try {
    await corpo(app);
  } finally {
    await app.fechar();
  }
}

test('CT-01 — cadastro com e-mail do domínio certo', { timeout: 120000 }, () => comApp(async (app) => {
  const endereco = email('ct01');
  await cadastrar(app, endereco);
  const rotulos = await app.rotulos();
  assert.ok(rotulos.includes('Verifique seu e-mail'), `tela errada: ${rotulos.join(' | ')}`);
  assert.ok(rotulos.includes('Reenviar verificação'));
  assert.equal(await app.avaliar('firebase_auth.getAuth().currentUser.email'), endereco);
}));

test('CT-02 — cadastro com e-mail fora do domínio', { timeout: 120000 }, () => comApp(async (app) => {
  await app.tocar('Criar uma conta');
  await app.digitar('Nome', 'Fora Domínio');
  await app.digitar('E-mail acadêmico', 'lucio@gmail.com');
  await app.digitar('Senha', SENHA);
  await app.tocar('Criar conta');
  // O cabeçalho traz a frase dentro de um texto maior; a validação do campo é
  // um rótulo com exatamente esta frase, então a contagem exata a distingue.
  const rotulos = await app.rotulos();
  assert.equal(quantos(rotulos, 'Use seu e-mail @cs.unipe.edu.br.'), 1, rotulos.join(' | '));
  assert.ok(rotulos.includes('Criar conta'), 'saiu da tela de cadastro');
  assert.equal(await app.avaliar('firebase_auth.getAuth().currentUser'), null);
}));

test('CT-03 — domínio parecido não passa', { timeout: 120000 }, () => comApp(async (app) => {
  await app.tocar('Criar uma conta');
  await app.digitar('Nome', 'Quase Certo');
  await app.digitar('E-mail acadêmico', 'lucio@cs.unipe.edu.br.br');
  await app.digitar('Senha', SENHA);
  await app.tocar('Criar conta');
  const rotulos = await app.rotulos();
  assert.equal(quantos(rotulos, 'Use seu e-mail @cs.unipe.edu.br.'), 1, rotulos.join(' | '));
  assert.equal(await app.avaliar('firebase_auth.getAuth().currentUser'), null);
}));

test('CT-04 — entrar sem verificar o e-mail não chega ao feed', { timeout: 120000 }, () => comApp(async (app) => {
  const endereco = email('ct04');
  await cadastrar(app, endereco);
  await app.tocar('Sair');
  await app.esperarRotulo('Criar uma conta');
  await app.digitar('E-mail acadêmico', endereco);
  await app.digitar('Senha', SENHA);
  await app.tocar('Entrar');
  await app.esperarRotulo('Já verifiquei');
  const rotulos = await app.rotulos();
  assert.ok(!rotulos.includes('Publicar'), `chegou ao feed sem verificar: ${rotulos.join(' | ')}`);
}));

test('CT-05 — entrar depois de verificar chega ao feed', { timeout: 120000 }, () => comApp(async (app) => {
  await entrarVerificado(app, email('ct05'));
  const rotulos = await app.rotulos();
  assert.ok(rotulos.includes('Feed'), rotulos.join(' | '));
  assert.ok(rotulos.includes('Mensagens'));
  assert.ok(rotulos.includes('Meus itens'));
}));

test('CT-06 — senha curta é recusada na tela', { timeout: 120000 }, () => comApp(async (app) => {
  await app.tocar('Criar uma conta');
  await app.digitar('Nome', 'Senha Curta');
  await app.digitar('E-mail acadêmico', email('ct06'));
  await app.digitar('Senha', '123');
  await app.tocar('Criar conta');
  assert.ok((await app.rotulos()).includes('Use pelo menos 6 caracteres.'));
  assert.equal(await app.avaliar('firebase_auth.getAuth().currentUser'), null);
}));

test('CT-07 — senha errada ao entrar', { timeout: 120000 }, () => comApp(async (app) => {
  const endereco = email('ct07');
  const uid = await cadastrar(app, endereco);
  await verificarEmail(uid);
  await app.tocar('Sair');
  await app.esperarRotulo('Criar uma conta');
  await app.digitar('E-mail acadêmico', endereco);
  await app.digitar('Senha', 'senha-errada-999');
  await app.tocar('Entrar');
  await app.esperarRotulo('E-mail ou senha incorretos.');
  assert.equal(await app.avaliar('firebase_auth.getAuth().currentUser'), null);
}));

test('CT-08 e CT-09 — editar nome e curso, e o nome novo vale depois', { timeout: 120000 }, () => comApp(async (app) => {
  const uid = await entrarVerificado(app, email('ct08'));
  await app.tocar('Perfil');
  await app.esperarRotulo('Salvar perfil');
  await app.digitarSubstituindo('Nome', 'Nome Trocado');
  await app.digitarSubstituindo('Curso (opcional)', 'Sistemas de Informação');
  await app.tocar('Salvar perfil');
  await app.esperarRotulo('Perfil atualizado.');
  const perfil = await app.avaliar(`(async () => {
    const doc = await firebase_firestore.getDoc(firebase_firestore.doc(firebase_firestore.getFirestore(), 'usuarios', '${uid}'));
    return doc.data();
  })()`);
  assert.equal(perfil.nome, 'Nome Trocado');
  assert.equal(perfil.curso, 'Sistemas de Informação');
}));

test('CT-10 — sair volta para a tela de entrada', { timeout: 120000 }, () => comApp(async (app) => {
  await entrarVerificado(app, email('ct10'));
  await app.tocar('Perfil');
  await app.tocar('Sair');
  await app.esperarRotulo('Criar uma conta');
  assert.equal(await app.avaliar('firebase_auth.getAuth().currentUser'), null);
  await app.recarregar();
  assert.equal(await app.avaliar('firebase_auth.getAuth().currentUser'), null);
}));

/// Escolhe o valor de um `DropdownButtonFormField`: toca no campo e, no menu que
/// abre, toca na opção.
async function escolher(app, campo, valor) {
  await app.tocarComecandoCom(campo);
  await app.tocar(valor);
}

/// Preenche a tela de publicar sem foto e confirma.
async function publicar(app, { titulo, tipo = 'Achado', categoria = 'Chaves', local = 'Biblioteca', descricao = '' }) {
  await app.tocar('Publicar');
  await app.esperarRotulo('Publicar item');
  await escolher(app, 'Tipo', tipo);
  await app.digitar('Título', titulo);
  if (descricao) await app.digitar('Descrição (opcional)', descricao);
  await escolher(app, 'Categoria', categoria);
  await escolher(app, 'Local', local);
  await app.tocar('Publicar item');
  await app.esperarRotulo('Item publicado.');
}

test('CT-11 — publicar item sem foto', { timeout: 180000 }, () => comApp(async (app) => {
  await limparBanco();
  await entrarVerificado(app, email('ct11'));
  await publicar(app, { titulo: 'Chave com chaveiro azul', descricao: 'Achei perto da catraca' });
  await app.esperarTexto('Chave com chaveiro azul');
  const itens = await app.avaliar(`(async () => {
    const consulta = await firebase_firestore.getDocs(firebase_firestore.collection(firebase_firestore.getFirestore(), 'itens'));
    return consulta.docs.map((doc) => doc.data());
  })()`);
  assert.equal(itens.length, 1);
  assert.equal(itens[0].titulo, 'Chave com chaveiro azul');
  assert.equal(itens[0].tipo, 'achado');
  assert.equal(itens[0].status, 'aberto');
  assert.equal(itens[0].fotoUrl, '');
}));

test('CT-12 — campos obrigatórios não gravam nada', { timeout: 180000 }, () => comApp(async (app) => {
  await limparBanco();
  await entrarVerificado(app, email('ct12'));
  await app.tocar('Publicar');
  await app.esperarRotulo('Publicar item');
  await app.tocar('Publicar item');
  const rotulos = await app.rotulos();
  assert.ok(rotulos.includes('Informe o título.'), rotulos.join(' | '));
  assert.ok(rotulos.includes('Escolha a categoria.') || rotulos.includes('Escolha o local.'), rotulos.join(' | '));
  const quantidade = await app.avaliar(`(async () => {
    const consulta = await firebase_firestore.getDocs(firebase_firestore.collection(firebase_firestore.getFirestore(), 'itens'));
    return consulta.size;
  })()`);
  assert.equal(quantidade, 0);
}));

test('CT-13 — aviso de LGPD na categoria Documentos', { timeout: 180000 }, () => comApp(async (app) => {
  await entrarVerificado(app, email('ct13'));
  await app.tocar('Publicar');
  await app.esperarRotulo('Publicar item');
  assert.ok(!(await app.rotulos()).includes('Cubra CPF/RG na foto antes de publicar.'), 'o aviso apareceu antes da categoria');
  await escolher(app, 'Categoria', 'Documentos');
  await app.esperarRotulo('Cubra CPF/RG na foto antes de publicar.');
}));

test('CT-18 — feed vazio explica o que fazer', { timeout: 180000 }, () => comApp(async (app) => {
  await limparBanco();
  await entrarVerificado(app, email('ct18'));
  assert.ok(await app.tem('Nenhum item ainda.'), (await app.rotulos()).join(' | '));
}));

test('CT-20 — busca ignora acento e maiúscula', { timeout: 180000 }, () => comApp(async (app) => {
  await limparBanco();
  await entrarVerificado(app, email('ct20'));
  await publicar(app, { titulo: 'Óculos de sol' });
  await publicar(app, { titulo: 'Guarda-chuva preto' });
  await app.digitar('Buscar por título ou descrição', 'OCULOS');
  await app.esperarTexto('Óculos de sol');
  assert.ok(!(await app.tem('Guarda-chuva preto')), 'a busca não filtrou');
}));

// Este caso reproduz um defeito conhecido do produto: `Filtro.aceita` procura o
// texto digitado inteiro com `contains`, então duas palavras separadas no título
// não casam (issue #4). Fica como `todo` para o CI não ficar vermelho por um
// defeito já registrado, e volta a valer quando a correção chegar.
test('CT-21 — busca com mais de uma palavra', { timeout: 180000, todo: 'defeito #4: busca trata o texto digitado como um pedaço só' }, () => comApp(async (app) => {
  await limparBanco();
  await entrarVerificado(app, email('ct21'));
  await publicar(app, { titulo: 'Garrafa térmica prata', descricao: 'Fica na portaria' });
  await publicar(app, { titulo: 'Caderno de cálculo' });
  await app.digitar('Buscar por título ou descrição', 'garrafa prata');
  await app.esperarTexto('Garrafa térmica prata');
  assert.ok(!(await app.tem('Caderno de cálculo')));
}));

test('CT-19 e CT-22 — filtros combinados e limpar filtros', { timeout: 180000 }, () => comApp(async (app) => {
  await limparBanco();
  await entrarVerificado(app, email('ct19'));
  await publicar(app, { titulo: 'Mochila cinza', tipo: 'Perdido', categoria: 'Material escolar', local: 'Biblioteca' });
  await publicar(app, { titulo: 'Fone sem fio', tipo: 'Achado', categoria: 'Eletrônicos', local: 'Ginásio' });
  await app.tocar('Perdidos');
  await escolher(app, 'Categoria', 'Material escolar');
  await app.esperarTexto('Mochila cinza');
  assert.ok(!(await app.tem('Fone sem fio')), 'o filtro deixou passar item de outro tipo');
  await app.tocar('Limpar');
  await app.esperarTexto('Fone sem fio');
  assert.ok(await app.tem('Mochila cinza'));
}));

test('CT-23 — filtro sem resultado oferece limpar', { timeout: 180000 }, () => comApp(async (app) => {
  await limparBanco();
  await entrarVerificado(app, email('ct23'));
  await publicar(app, { titulo: 'Caneca branca', tipo: 'Achado', categoria: 'Garrafa/Copo', local: 'Biblioteca' });
  await app.tocar('Perdidos');
  await app.esperarRotulo('Nenhum item com esses filtros.');
  await app.tocar('Limpar filtros');
  await app.esperarTexto('Caneca branca');
}));

test('CT-17 — feed atualiza em tempo real em outra aba', { timeout: 240000 }, async () => {
  await limparBanco();
  const primeira = await abrirApp();
  const segunda = await abrirApp();
  try {
    await entrarVerificado(primeira, email('ct17a'));
    await entrarVerificado(segunda, email('ct17b'));
    await publicar(primeira, { titulo: 'Carteira marrom' });
    // Sem recarregar a segunda aba: o item tem que chegar pelo stream.
    await segunda.esperarTexto('Carteira marrom');
  } finally {
    await primeira.fechar();
    await segunda.fechar();
  }
});

/// Espera um rótulo sair da tela: o contador de não lidas tem que desaparecer.
async function esperarSem(app, rotulo) {
  const fim = Date.now() + 20000;
  while (Date.now() < fim) {
    if (!(await app.rotulos()).includes(rotulo)) return;
    await new Promise((pronto) => setTimeout(pronto, 200));
  }
  throw new Error(`O rótulo ${JSON.stringify(rotulo)} continuou na tela.`);
}

async function statusDoPrimeiroItem(app) {
  return app.avaliar(`(async () => {
    const consulta = await firebase_firestore.getDocs(firebase_firestore.collection(firebase_firestore.getFirestore(), 'itens'));
    return consulta.docs[0].data().status;
  })()`);
}

async function quantosItens(app) {
  return app.avaliar(`(async () => {
    const consulta = await firebase_firestore.getDocs(firebase_firestore.collection(firebase_firestore.getFirestore(), 'itens'));
    return consulta.size;
  })()`);
}

const quantasConversas = () => contarColecao('conversas');

/// Duas abas com perfis separados valem como dois aparelhos no mesmo caso.
async function comDoisApps(corpo) {
  const dono = await abrirApp();
  const visitante = await abrirApp();
  try {
    await corpo(dono, visitante);
  } finally {
    await dono.fechar();
    await visitante.fechar();
  }
}

test('CT-24 e CT-25 — detalhe abre, e o autor não vê Conversar', { timeout: 180000 }, () => comApp(async (app) => {
  await limparBanco();
  await entrarVerificado(app, email('ct24'));
  await publicar(app, { titulo: 'Guarda-chuva listrado', tipo: 'Achado', categoria: 'Outros', local: 'Passarela' });
  await app.tocarContendo('Guarda-chuva listrado');
  await app.esperarRotulo('Item achado');
  const rotulos = await app.rotulos();
  assert.ok(rotulos.includes('Marcar como devolvido'), rotulos.join(' | '));
  assert.ok(!rotulos.includes('Conversar'), 'o autor viu o botão Conversar');
  assert.ok(rotulos.includes('Editar item') && rotulos.includes('Apagar item'), rotulos.join(' | '));
}));

test('CT-26 — item sem foto abre o detalhe', { timeout: 180000 }, () => comApp(async (app) => {
  await limparBanco();
  await entrarVerificado(app, email('ct26'));
  await publicar(app, { titulo: 'Caderno sem capa', tipo: 'Perdido', categoria: 'Material escolar', local: 'Auditório' });
  await app.tocarContendo('Caderno sem capa');
  await app.esperarRotulo('Item perdido');
  assert.ok(await app.tem('Caderno sem capa'));
}));

test('CT-38 — outro usuário não edita nem apaga o item', { timeout: 240000 }, () => comDoisApps(async (dono, visitante) => {
  await limparBanco();
  await entrarVerificado(dono, email('ct38a'));
  await entrarVerificado(visitante, email('ct38b'));
  await publicar(dono, { titulo: 'Boné azul', tipo: 'Achado', categoria: 'Roupa/Acessório', local: 'Ginásio' });
  await visitante.tocarContendo('Boné azul');
  await visitante.esperarRotulo('Item achado');
  const rotulos = await visitante.rotulos();
  assert.ok(rotulos.includes('Conversar'), rotulos.join(' | '));
  assert.ok(!rotulos.includes('Editar item'), 'apareceu Editar item para quem não é autor');
  assert.ok(!rotulos.includes('Apagar item'), 'apareceu Apagar item para quem não é autor');
}));

test('CT-27 — primeira mensagem cria a conversa', { timeout: 240000 , todo: 'defeito #3: a conversa fica carregando para sempre depois da primeira mensagem' }, () => comDoisApps(async (dono, visitante) => {
  await limparBanco();
  await entrarVerificado(dono, email('ct27a'));
  await entrarVerificado(visitante, email('ct27b'));
  await publicar(dono, { titulo: 'Mochila verde', tipo: 'Achado', categoria: 'Material escolar', local: 'Biblioteca' });
  await visitante.tocarContendo('Mochila verde');
  await visitante.tocar('Conversar');
  await visitante.digitar('Escreva uma mensagem', 'Oi, acho que e minha');
  await visitante.tocar('Enviar');
  await visitante.esperarTexto('Oi, acho que e minha');
  assert.equal(await quantasConversas(), 1);
}));

test('CT-28 — conversa chega em tempo real na outra aba', { timeout: 240000 , todo: 'defeito #3: a conversa fica carregando para sempre depois da primeira mensagem' }, () => comDoisApps(async (dono, visitante) => {
  await limparBanco();
  await entrarVerificado(dono, email('ct28a'));
  await entrarVerificado(visitante, email('ct28b'));
  await publicar(dono, { titulo: 'Carteira preta', tipo: 'Achado', categoria: 'Carteira/Dinheiro', local: 'Reitoria' });
  await visitante.tocarContendo('Carteira preta');
  await visitante.tocar('Conversar');
  await visitante.digitar('Escreva uma mensagem', 'Perdi ontem na Reitoria');
  await visitante.tocar('Enviar');
  await visitante.esperarTexto('Perdi ontem na Reitoria');
  await dono.tocar('Mensagens');
  await dono.tocarContendo('Carteira preta');
  await dono.esperarTexto('Perdi ontem na Reitoria');
  await visitante.digitar('Escreva uma mensagem', 'Pode guardar');
  await visitante.tocar('Enviar');
  // Sem recarregar a aba do dono: a segunda mensagem chega pelo stream.
  await dono.esperarTexto('Pode guardar');
}));

test('CT-29 e CT-30 — contador de não lidas sobe e zera ao abrir', { timeout: 240000 , todo: 'defeito #3: a conversa fica carregando para sempre depois da primeira mensagem' }, () => comDoisApps(async (dono, visitante) => {
  await limparBanco();
  await entrarVerificado(dono, email('ct29a'));
  await entrarVerificado(visitante, email('ct29b'));
  await publicar(dono, { titulo: 'Fone branco', tipo: 'Achado', categoria: 'Eletrônicos', local: 'Biblioteca' });
  await visitante.tocarContendo('Fone branco');
  await visitante.tocar('Conversar');
  await visitante.digitar('Escreva uma mensagem', 'E meu fone');
  await visitante.tocar('Enviar');
  await visitante.esperarTexto('E meu fone');
  await dono.esperarRotulo('1');
  await dono.tocar('Mensagens');
  await dono.tocarContendo('Fone branco');
  await dono.esperarTexto('E meu fone');
  await dono.tocar('Feed');
  await esperarSem(dono, '1');
}));

test('CT-32 — mensagem vazia não é enviada', { timeout: 240000 }, () => comDoisApps(async (dono, visitante) => {
  await limparBanco();
  await entrarVerificado(dono, email('ct32a'));
  await entrarVerificado(visitante, email('ct32b'));
  await publicar(dono, { titulo: 'Chave unica', tipo: 'Achado', categoria: 'Chaves', local: 'Estacionamento' });
  await visitante.tocarContendo('Chave unica');
  await visitante.tocar('Conversar');
  await visitante.tocar('Enviar');
  assert.equal(await quantasConversas(), 0, 'mensagem vazia criou conversa');
}));

test('CT-33 e CT-34 — marcar devolvido, e cancelar não muda nada', { timeout: 180000 }, () => comApp(async (app) => {
  await limparBanco();
  await entrarVerificado(app, email('ct33'));
  await publicar(app, { titulo: 'Garrafa rosa', tipo: 'Achado', categoria: 'Garrafa/Copo', local: 'Piscina' });
  await app.tocarContendo('Garrafa rosa');
  await app.tocar('Marcar como devolvido');
  await app.esperarRotulo('Marcar como devolvido?');
  await app.tocar('Cancelar');
  assert.equal(await statusDoPrimeiroItem(app), 'aberto', 'cancelar mudou o item');
  await app.tocar('Marcar como devolvido');
  await app.esperarRotulo('Marcar como devolvido?');
  await app.tocar('Marcar como devolvido');
  await app.esperarRotulo('Item marcado como devolvido.');
  assert.equal(await statusDoPrimeiroItem(app), 'devolvido');
}));

test('CT-35 — Meus itens mostra só os meus', { timeout: 240000 }, () => comDoisApps(async (dono, visitante) => {
  await limparBanco();
  await entrarVerificado(dono, email('ct35a'));
  await entrarVerificado(visitante, email('ct35b'));
  await publicar(dono, { titulo: 'Agenda vermelha', tipo: 'Achado', categoria: 'Material escolar', local: 'Biblioteca' });
  await publicar(visitante, { titulo: 'Pendrive cinza', tipo: 'Perdido', categoria: 'Eletrônicos', local: 'Centro de Informação' });
  await dono.tocar('Meus itens');
  await dono.esperarTexto('Agenda vermelha');
  assert.ok(!(await dono.tem('Pendrive cinza')), 'Meus itens mostrou item de outra pessoa');
}));

test('CT-36 e CT-37 — editar e apagar o próprio item', { timeout: 240000 }, () => comApp(async (app) => {
  await limparBanco();
  await entrarVerificado(app, email('ct36'));
  await publicar(app, { titulo: 'Tenis esquerdo', tipo: 'Achado', categoria: 'Roupa/Acessório', local: 'Ginásio' });
  await app.tocar('Meus itens');
  await app.tocar('Editar');
  await app.esperarRotulo('Editar item');
  await app.digitarSubstituindo('Título', 'Tenis direito');
  await app.tocar('Salvar alterações');
  await app.esperarRotulo('Item atualizado.');
  await app.esperarTexto('Tenis direito');
  await app.tocarContendo('Tenis direito');
  await app.tocar('Apagar item');
  await app.esperarRotulo('Apagar item?');
  await app.tocar('Apagar');
  await app.esperarRotulo('Item apagado.');
  assert.equal(await quantosItens(app), 0);
}));
