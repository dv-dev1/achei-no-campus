// Confere, contra as regras de verdade (firestore.rules), a sequência exata
// de leituras e gravações que o app faz no chat (lib/conversas.dart).
// O Firestore de mentira dos testes Flutter não aplica regras; este teste
// aplica.

import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import {
  addDoc, collection, doc, getDoc, getDocs, increment, orderBy, query,
  serverTimestamp, setDoc, updateDoc, where, writeBatch,
} from 'firebase/firestore';

let env;
const db = (uid) => env.authenticatedContext(uid, {
  email: `${uid}@cs.unipe.edu.br`, email_verified: true,
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
    await setDoc(doc(context.firestore(), 'itens/fone'), {
      tipo: 'perdido', titulo: 'Fone', descricao: '', categoria: 'Eletrônicos',
      local: 'Biblioteca', fotoUrl: '', autorId: 'ana', autorNome: 'Ana',
      status: 'aberto', criadoEm: new Date(),
    });
  });
});

// Primeira mensagem do Bruno, como Conversas.enviar(jaExiste: false):
// cria a conversa e, depois, a mensagem.
async function primeiraMensagemDoBruno() {
  const store = db('bruno');
  const conversa = doc(store, 'conversas/fone_bruno');
  await setDoc(conversa, {
    itemId: 'fone', participantes: ['ana', 'bruno'], ultimaMensagem: 'Oi',
    atualizadoEm: serverTimestamp(), naoLidas: { bruno: 0, ana: 1 },
  });
  await addDoc(collection(conversa, 'mensagens'), {
    autorId: 'bruno', texto: 'Oi', criadoEm: serverTimestamp(),
  });
}

// Mensagem seguinte, como Conversas.enviar(jaExiste: true): lote único.
async function responder(uid, outro, texto) {
  const store = db(uid);
  const conversa = doc(store, 'conversas/fone_bruno');
  const lote = writeBatch(store);
  lote.update(conversa, {
    ultimaMensagem: texto, atualizadoEm: serverTimestamp(),
    [`naoLidas.${outro}`]: increment(1),
  });
  lote.set(doc(collection(conversa, 'mensagens')), {
    autorId: uid, texto, criadoEm: serverTimestamp(),
  });
  await lote.commit();
}

test('a conversa nova não pode ser lida antes de existir (por isso o app usa a lista)', async () => {
  await assertFails(getDoc(doc(db('bruno'), 'conversas/fone_bruno')));
  // A lista de conversas do usuário é permitida mesmo vazia.
  await assertSucceeds(getDocs(query(
    collection(db('bruno'), 'conversas'), where('participantes', 'array-contains', 'bruno'),
  )));
});

test('primeira mensagem: criar a conversa e depois a mensagem', async () => {
  await assertSucceeds(primeiraMensagemDoBruno());
});

test('primeira mensagem num lote só é negada (por isso são dois passos)', async () => {
  const store = db('bruno');
  const conversa = doc(store, 'conversas/fone_bruno');
  const lote = writeBatch(store);
  lote.set(conversa, {
    itemId: 'fone', participantes: ['ana', 'bruno'], ultimaMensagem: 'Oi',
    atualizadoEm: serverTimestamp(), naoLidas: { bruno: 0, ana: 1 },
  });
  lote.set(doc(collection(conversa, 'mensagens')), {
    autorId: 'bruno', texto: 'Oi', criadoEm: serverTimestamp(),
  });
  await assertFails(lote.commit());
});

test('respostas em lote, contador e leitura, dos dois lados', async () => {
  await primeiraMensagemDoBruno();
  await assertSucceeds(responder('bruno', 'ana', 'Ainda está aí?'));

  // A Ana lista as conversas dela, lê as mensagens e zera o contador.
  const daAna = db('ana');
  const lista = await assertSucceeds(getDocs(query(
    collection(daAna, 'conversas'), where('participantes', 'array-contains', 'ana'),
  )));
  if (lista.docs[0].data().naoLidas.ana !== 2) throw new Error('contador da Ana deveria ser 2');
  await assertSucceeds(getDocs(query(
    collection(daAna, 'conversas/fone_bruno/mensagens'), orderBy('criadoEm'),
  )));
  await assertSucceeds(updateDoc(doc(daAna, 'conversas/fone_bruno'), { 'naoLidas.ana': 0 }));

  await assertSucceeds(responder('ana', 'bruno', 'Está comigo sim'));
  const final = await getDoc(doc(daAna, 'conversas/fone_bruno'));
  const { naoLidas } = final.data();
  if (naoLidas.ana !== 0 || naoLidas.bruno !== 1) throw new Error(`contadores errados: ${JSON.stringify(naoLidas)}`);
});

test('critério de pronto: um terceiro não lista, não lê e não envia', async () => {
  await primeiraMensagemDoBruno();
  const daCarla = db('carla');
  const lista = await getDocs(query(
    collection(daCarla, 'conversas'), where('participantes', 'array-contains', 'carla'),
  ));
  if (!lista.empty) throw new Error('a Carla não deveria ver conversas');
  await assertFails(getDoc(doc(daCarla, 'conversas/fone_bruno')));
  await assertFails(getDocs(collection(daCarla, 'conversas/fone_bruno/mensagens')));
  await assertFails(responder('carla', 'ana', 'Invadindo'));
});
