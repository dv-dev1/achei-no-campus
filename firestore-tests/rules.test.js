import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';

let env;
const item = {
  tipo: 'achado', titulo: 'Garrafa azul', descricao: '', categoria: 'Garrafa/Copo',
  local: 'Biblioteca', fotoUrl: '', autorId: 'ana', autorNome: 'Ana',
  status: 'aberto', criadoEm: new Date('2026-10-06T12:00:00Z'),
};
const conversa = {
  itemId: 'garrafa', participantes: ['ana', 'bruno'], ultimaMensagem: '',
  atualizadoEm: new Date(), naoLidas: { ana: 0, bruno: 0 },
};
const db = (uid = 'ana', claims = {}) => env.authenticatedContext(uid, {
  email: `${uid}@cs.unipe.edu.br`, email_verified: true, ...claims,
}).firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-achei-no-campus',
    firestore: { rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});
after(async () => env?.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const store = context.firestore();
    await setDoc(doc(store, 'itens/garrafa'), item);
    await setDoc(doc(store, 'usuarios/ana'), { nome: 'Ana', curso: '', criadoEm: new Date() });
    await setDoc(doc(store, 'conversas/garrafa_bruno'), conversa);
    await setDoc(doc(store, 'conversas/garrafa_bruno/mensagens/ola'), {
      autorId: 'ana', texto: 'Olá', criadoEm: new Date(),
    });
  });
});

for (const [nome, usuario] of [
  ['sem login', () => env.unauthenticatedContext().firestore()],
  ['e-mail não verificado', () => db('ana', { email_verified: false })],
  ['domínio externo', () => db('ana', { email: 'ana@gmail.com' })],
  ['sufixo malicioso', () => db('ana', { email: 'ana@cs.unipe.edu.br.evil.com' })],
  ['domínio sem arroba', () => db('ana', { email: 'cs.unipe.edu.br' })],
]) {
  test(`${nome}: nega leitura e escrita de itens, perfis, conversas e mensagens`, async () => {
    const store = usuario();
    for (const path of ['itens/garrafa', 'usuarios/ana', 'conversas/garrafa_bruno', 'conversas/garrafa_bruno/mensagens/ola']) {
      await assertFails(getDoc(doc(store, path)));
      await assertFails(updateDoc(doc(store, path), { titulo: 'Invadido' }));
    }
    await assertFails(setDoc(doc(store, 'itens/novo'), { ...item, criadoEm: serverTimestamp() }));
    await assertFails(deleteDoc(doc(store, 'itens/garrafa')));
  });
}

test('aluno verificado lê itens e perfis', async () => {
  await assertSucceeds(getDoc(doc(db('bruno'), 'itens/garrafa')));
  await assertSucceeds(getDocs(collection(db('bruno'), 'itens')));
  await assertSucceeds(getDoc(doc(db('bruno'), 'usuarios/ana')));
});
test('cria item próprio com foto opcional', async () => {
  await assertSucceeds(setDoc(doc(db(), 'itens/novo'), { ...item, criadoEm: serverTimestamp() }));
});
test('não cria item em nome de outro usuário', async () => {
  await assertFails(setDoc(doc(db('bruno'), 'itens/novo'), { ...item, criadoEm: serverTimestamp() }));
});
test('dono edita, marca devolvido e apaga', async () => {
  const ref = doc(db(), 'itens/garrafa');
  await assertSucceeds(updateDoc(ref, { titulo: 'Garrafa verde', descricao: 'Na mesa' }));
  await assertSucceeds(updateDoc(ref, { status: 'devolvido' }));
  await assertSucceeds(deleteDoc(ref));
});
test('outro aluno não edita nem apaga', async () => {
  const ref = doc(db('bruno'), 'itens/garrafa');
  await assertFails(updateDoc(ref, { titulo: 'Invadido' }));
  await assertFails(updateDoc(ref, { status: 'devolvido' }));
  await assertFails(deleteDoc(ref));
});
test('dono não transfere autoria, nome nem data de criação', async () => {
  for (const change of [{ autorId: 'bruno' }, { autorNome: 'Bruno' }, { criadoEm: serverTimestamp() }]) {
    await assertFails(updateDoc(doc(db(), 'itens/garrafa'), change));
  }
});
test('nega item incompleto e valores fora do schema', async () => {
  for (const change of [
    { titulo: '' }, { titulo: '   ' }, { tipo: 'vendido' }, { categoria: '' },
    { local: '' }, { status: 'inexistente' }, { campoExtra: true }, { fotoUrl: 42 },
  ]) {
    await assertFails(setDoc(doc(db(), 'itens/novo'), { ...item, ...change, criadoEm: serverTimestamp() }));
  }
});
test('cada aluno cria e edita somente seu perfil', async () => {
  const bruno = db('bruno');
  await assertSucceeds(setDoc(doc(bruno, 'usuarios/bruno'), { nome: 'Bruno', curso: '', criadoEm: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(bruno, 'usuarios/bruno'), { nome: 'Bruno Silva', curso: 'Computação' }));
  await assertFails(updateDoc(doc(bruno, 'usuarios/ana'), { nome: 'Invadido' }));
  await assertFails(updateDoc(doc(bruno, 'usuarios/bruno'), { nome: ' ' }));
  await assertFails(updateDoc(doc(bruno, 'usuarios/bruno'), { criadoEm: serverTimestamp() }));
});
test('participante lê e atualiza a conversa', async () => {
  for (const uid of ['ana', 'bruno']) {
    const ref = doc(db(uid), 'conversas/garrafa_bruno');
    await assertSucceeds(getDoc(ref));
    await assertSucceeds(updateDoc(ref, { ultimaMensagem: 'Tudo certo', atualizadoEm: serverTimestamp() }));
  }
});
test('terceiro não lê, escreve nem se inclui na conversa', async () => {
  const ref = doc(db('carla'), 'conversas/garrafa_bruno');
  await assertFails(getDoc(ref));
  await assertFails(updateDoc(ref, { ultimaMensagem: 'Invadido' }));
  await assertFails(updateDoc(ref, { participantes: ['ana', 'carla'] }));
  await assertFails(deleteDoc(ref));
});
test('participantes não mudam item nem participantes da conversa', async () => {
  const ref = doc(db(), 'conversas/garrafa_bruno');
  await assertFails(updateDoc(ref, { participantes: ['ana', 'carla'] }));
  await assertFails(updateDoc(ref, { itemId: 'outro' }));
});
test('conversa nova precisa do dono real e interessado distintos', async () => {
  await assertSucceeds(setDoc(doc(db('carla'), 'conversas/garrafa_carla'), {
    ...conversa, participantes: ['ana', 'carla'], naoLidas: { ana: 0, carla: 0 }, atualizadoEm: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(db('carla'), 'conversas/garrafa_fake'), {
    ...conversa, participantes: ['bruno', 'carla'], atualizadoEm: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(db(), 'conversas/garrafa_ana'), {
    ...conversa, participantes: ['ana', 'ana'], atualizadoEm: serverTimestamp(),
  }));
});
test('mensagens: participantes leem e enviam com autoria própria', async () => {
  for (const uid of ['ana', 'bruno']) {
    const store = db(uid);
    await assertSucceeds(getDoc(doc(store, 'conversas/garrafa_bruno/mensagens/ola')));
    await assertSucceeds(setDoc(doc(store, `conversas/garrafa_bruno/mensagens/${uid}`), {
      autorId: uid, texto: 'Encontrei', criadoEm: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(store, `conversas/garrafa_bruno/mensagens/falso-${uid}`), {
      autorId: 'carla', texto: 'Invadido', criadoEm: serverTimestamp(),
    }));
  }
});
test('terceiro não lê nem envia mensagens', async () => {
  const store = db('carla');
  await assertFails(getDoc(doc(store, 'conversas/garrafa_bruno/mensagens/ola')));
  await assertFails(setDoc(doc(store, 'conversas/garrafa_bruno/mensagens/carla'), {
    autorId: 'carla', texto: 'Invadido', criadoEm: serverTimestamp(),
  }));
});
test('mensagem não altera autoria e não aceita texto vazio', async () => {
  const store = db();
  await assertFails(updateDoc(doc(store, 'conversas/garrafa_bruno/mensagens/ola'), { autorId: 'bruno' }));
  await assertFails(setDoc(doc(store, 'conversas/garrafa_bruno/mensagens/vazia'), {
    autorId: 'ana', texto: '', criadoEm: serverTimestamp(),
  }));
});
test('coleção fora do escopo permanece negada', async () => {
  await assertFails(setDoc(doc(db(), 'segredos/novo'), { texto: 'teste' }));
});
