# Chat e aba Mensagens

O chat é como quem achou e quem perdeu combinam a devolução, sem expor telefone. Toda conversa nasce de um item: não existe conversa solta entre duas pessoas.

## Como funciona para quem usa

1. Bruno vê no feed o fone que a Ana publicou, abre o detalhe e toca em **Conversar**.
2. Abre a tela da conversa, com o título do item no topo. Se for a primeira vez, ela diz "Mande a primeira mensagem sobre 'Fone de ouvido'. Combine onde e quando devolver."
3. Bruno escreve e toca em **Enviar** (o aviãozinho). A mensagem aparece num balão azul à direita.
4. No celular da Ana, a aba **Mensagens**, na barra de baixo, ganha um número: **1**.
5. Na aba, a conversa aparece com o título do item, "com Bruno", a última mensagem, a hora e o número de não lidas.
6. A Ana abre a conversa: o número some. Ela responde, e agora é o Bruno que vê **1**.

As mensagens chegam em tempo real, sem recarregar. Com a conversa aberta, o que chega já conta como lido.

## A barra de abas

Depois do login, o app abre a tela de início (`lib/telas/inicio.dart`), com três abas embaixo:

| Aba | Tela |
| --- | --- |
| **Feed** | Os itens abertos, com busca e filtros |
| **Mensagens** | As conversas do usuário, com o total de não lidas em cima do ícone |
| **Meus itens** | O que o usuário publicou. Antes era um ícone no topo do feed |

As três ficam vivas ao mesmo tempo (`IndexedStack`): trocar de aba não perde a rolagem nem os filtros.

## Como os dados ficam no Firestore

Exatamente como na spec. As regras do Daniel (`firestore.rules`) não aceitam nenhum campo a mais:

```text
conversas/{itemId}_{interessadoUid}
  itemId, participantes: [donoUid, interessadoUid]
  ultimaMensagem, atualizadoEm
  naoLidas: { <uid>: n }

conversas/{id}/mensagens/{id}
  autorId, texto, criadoEm
```

- **O ID é fixo**, item + interessado (`fone_bruno`). Se o Bruno tocar em Conversar de novo no mesmo item, cai na mesma conversa, sem duplicar.
- **Contador de não lidas:** quem envia soma 1 no `naoLidas` do outro (`FieldValue.increment(1)`, que soma sem precisar ler antes). Quem abre a conversa zera o seu.
- **O título do item e o nome do outro não ficam na conversa**, porque a regra não deixa. A aba Mensagens busca os dois em `itens/{itemId}` e `usuarios/{uid}` e guarda o resultado, para não buscar de novo a cada redesenho. Se o item foi apagado, aparece "Item removido".

## Três cuidados por causa das regras

As regras protegem as conversas (só os participantes leem e escrevem), e isso pede três cuidados no app:

1. **Ninguém consegue ler uma conversa que ainda não existe.** A regra confere os participantes do documento, e um documento que não existe não tem participantes. Por isso a tela da conversa não lê o documento direto: ela escuta **a lista de conversas do usuário** (`where('participantes', arrayContains: uid)`), que é permitida, e procura a conversa nela. Se não está lá, é conversa nova.
2. **A primeira mensagem vai em dois passos:** primeiro cria a conversa, depois a mensagem. A regra da mensagem confere a conversa *que já existe*, então as duas juntas num lote só são negadas. A partir da segunda mensagem, o update da conversa e a mensagem nova vão juntos num lote (`batch`).
3. **As mensagens só são escutadas depois que a conversa existe**, pelo mesmo motivo do item 1.

Esses três pontos estão testados contra as regras de verdade em `firestore-tests/chat.test.js`.

## Sem índice novo

Nenhuma consulta do chat precisa de índice composto:

- a lista de conversas só filtra por participante, e a ordem (mais recentes primeiro) é feita no app;
- as mensagens só ordenam por `criadoEm`, um campo só.

## Onde está cada coisa

| Arquivo | O que faz |
| --- | --- |
| `lib/modelos/conversa.dart` | Os modelos `Conversa` e `Mensagem`, e `Conversa.nova` (a conversa que nasce no Conversar) |
| `lib/conversas.dart` | Tudo o que o chat lê e grava: `minhas`, `mensagens`, `enviar`, `marcarComoLida`, `totalNaoLidas`, `item`, `nomeDe` |
| `lib/telas/conversa.dart` | A tela da conversa: balões, campo de texto e enviar |
| `lib/telas/mensagens.dart` | A aba Mensagens |
| `lib/telas/inicio.dart` | A barra de abas, com o contador em cima de Mensagens |
| `lib/telas/detalhe.dart` | O botão Conversar, que abre a conversa |

`lib/conversas.dart` segue o mesmo estilo do `lib/itens.dart` do Daniel: recebe a `Sessao` e as telas só chamam os métodos dele.

## Testes

```bash
flutter test test/conversas_test.dart test/chat_telas_test.dart
```

E as regras, no emulador (precisa de Node 22+ e Java 11+):

```bash
cd firestore-tests
npm ci
npx --no-install firebase emulators:exec --config ../firebase.json --project demo-achei-no-campus --only auth,firestore "npm test"
```

| Teste | Confere |
| --- | --- |
| `conversas_test.dart` | O ID fixo, o formato que as regras exigem, o contador subindo e zerando, cada um vendo só as suas conversas, mensagem vazia ou longa demais recusada, título do item e nome |
| `chat_telas_test.dart` | **O critério de pronto da tarefa de ponta a ponta:** Bruno conversa pelo detalhe, o número aparece na aba da Ana, ela abre e o número some, ela responde e o contador do Bruno sobe. Também: Conversar duas vezes não duplica, mensagem em branco não sai, aba vazia, troca de abas |
| `firestore-tests/chat.test.js` | A mesma sequência do app contra as **regras reais**, incluindo a outra parte do critério de pronto: **um terceiro não lista, não lê e não envia** |
