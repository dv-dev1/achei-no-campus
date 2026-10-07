# Marcar como devolvido

Quando o objeto volta para o dono, quem publicou o item marca ele como **devolvido**. É o final feliz do app: o item sai do feed e para de aparecer para todo mundo.

## Como funciona para quem usa

1. O dono do item abre o detalhe. No rodapé, no lugar do **Conversar**, aparece **Marcar como devolvido**. Em "Meus itens", o mesmo botão aparece embaixo de cada card aberto, como **Marcar devolvido** (ver [`meus-itens.md`](meus-itens.md)).
2. Ao tocar, o app pergunta antes: *"Marcar como devolvido? 'Chave do carro' vai sair do feed para todo mundo. Confirme só quando o objeto já estiver com o dono."*
3. **Cancelar**, ou tocar fora da janela, não muda nada.
4. Confirmado, o app grava, volta ao feed e mostra o aviso **"Item marcado como devolvido."**. O item já não está mais lá.

Se der erro (sem internet, por exemplo), aparece "Não foi possível marcar. Confira a conexão e tente de novo." e a pessoa continua no detalhe, podendo tentar outra vez.

Um item já devolvido, quando aberto a partir de "Meus itens", mostra a faixa amarela **"Este item já foi devolvido."** e nenhum botão no rodapé.

## Quem pode marcar

Só quem publicou. A tela esconde o botão para os outros, mas **quem garante isso de verdade são as regras do Firestore** (tarefa do Daniel): "edita só o dono". Esconder o botão é só conveniência, porque alguém mal-intencionado poderia chamar a API direto.

## Como o item some do feed

O botão só grava uma coisa no Firestore:

```dart
FirebaseFirestore.instance.collection('itens').doc(itemId).update({'status': 'devolvido'});
```

Ninguém precisa avisar o feed. Ele está escutando os itens com `status == "aberto"` em tempo real, então, assim que o status muda, o Firestore manda a lista nova sem o item, e ele some da tela de **todos** os usuários, não só da de quem marcou.

## Onde está cada coisa

| Arquivo | O que faz |
| --- | --- |
| `lib/widgets/devolver.dart` | `marcarComoDevolvido` (grava no Firestore) e `confirmarEDevolver` (pergunta, grava e mostra o aviso) |
| `lib/telas/detalhe.dart` | Escolhe o botão do rodapé e mostra a faixa de devolvido |

`confirmarEDevolver` fica fora da tela de propósito: **"Meus itens" usa a mesma função**, para os dois lugares perguntarem e avisarem do mesmo jeito. Ela devolve `true` quando o item foi marcado, para cada tela decidir o que fazer depois (o detalhe volta ao feed).

## Testes

```bash
flutter test test/devolver_test.dart
```

| Teste | Confere |
| --- | --- |
| o dono vê Marcar como devolvido | E não vê o Conversar |
| outra pessoa não vê Marcar como devolvido | E vê o Conversar |
| pede confirmação, e Cancelar não muda nada | Nada é gravado |
| se der erro, avisa e continua no detalhe | A mensagem de erro e a tela que não fecha |
| item já devolvido | A faixa aparece e nenhum botão |
| **critério de pronto** | Do feed: abre o item, marca, confirma, volta ao feed com o aviso, e o item não está mais na lista |

O último teste usa um "Firestore de mentira": uma lista que, quando um item é devolvido, manda a versão nova ao feed, do mesmo jeito que o Firestore de verdade faz. Por isso o feed e o detalhe aceitam o parâmetro `devolver`, que só os testes usam.
