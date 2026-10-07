# Meus itens

É a lista de tudo o que o usuário publicou, abertos e devolvidos. Serve para acompanhar o que ainda está em aberto e resolver: marcar como devolvido ou editar.

## Como chegar

Pela aba **Meus itens**, a terceira da barra de baixo (Feed, Mensagens, Meus itens). Até a task 8 ela era um ícone no topo do feed.

## O que aparece

Um card por item, igual ao do feed, com duas diferenças:

- **Etiqueta do status**, ao lado da de Perdido/Achado: **Aberto** (só o contorno azul) ou **✓ Devolvido** (cinza).
- **Botões embaixo do card:**
  - **Editar**, em todos os itens;
  - **Marcar devolvido**, só nos abertos. Usa a mesma confirmação do detalhe (ver [`devolvido.md`](devolvido.md)).

A ordem é: **abertos primeiro**, porque é com eles que ainda há o que fazer, e depois os devolvidos. Dentro de cada grupo, os mais recentes vêm primeiro.

Tocar no card abre o detalhe, do mesmo jeito que no feed.

Se a pessoa ainda não publicou nada, a tela diz "Você ainda não publicou nenhum item. O que você publicar aparece aqui."

## Como a lista é montada

```dart
FirebaseFirestore.instance.collection('itens').where('autorId', isEqualTo: uid).snapshots()
```

Três escolhas que valem explicar:

1. **Sem `orderBy` na consulta.** Filtrar por `autorId` e ordenar por `criadoEm` na mesma consulta exigiria mais um índice composto no Firestore. Como cada pessoa publica poucos itens, a ordem é feita no app, por `ordenarMeusItens`, e nenhum índice novo é necessário.
2. **Tempo real.** Como no feed, a lista escuta o Firestore. Marcou como devolvido, o card troca a etiqueta para **✓ Devolvido** na hora, sem recarregar.
3. **Segunda garantia.** A consulta já traz só os itens do usuário, mas a tela ainda confere `autorId == uid` antes de mostrar. Nunca aparece item de outra pessoa, mesmo que a consulta mude um dia.

## O botão Editar, por enquanto

Por enquanto, **Editar** só mostra o aviso "A edição ainda está sendo feita.". A tela de edição já existe: o Daniel entregou em 06/10 (`TelaPublicar` com o item), e ela abre pelo ícone de editar no topo do detalhe. Falta ligar este botão a ela. O ponto a trocar está marcado com `TODO(Daniel)` em `lib/telas/meus_itens.dart`, no método `_editar`.

## Onde está cada coisa

| Arquivo | O que faz |
| --- | --- |
| `lib/telas/meus_itens.dart` | A tela, a consulta `meusItensDoFirestore` e a ordem `ordenarMeusItens` |
| `lib/widgets/card_item.dart` | O card, agora com `mostrarStatus`, `botoes` e a `EtiquetaStatus` |
| `lib/widgets/devolver.dart` | A confirmação de devolvido, a mesma do detalhe |
| `lib/widgets/aviso.dart` | A mensagem de vazio ou de erro, compartilhada com o feed |
| `lib/telas/inicio.dart` | A barra de abas, onde esta tela é a terceira aba |

## Testes

```bash
flutter test test/meus_itens_test.dart
```

| Teste | Confere |
| --- | --- |
| **critério de pronto:** cada usuário vê só os próprios itens | Item de outra pessoa não aparece, mesmo vindo na lista |
| etiqueta do status | Aberto e Devolvido aparecem |
| ordem | Abertos antes dos devolvidos, mais recentes primeiro |
| item devolvido não tem Marcar devolvido | Só o Editar |
| **critério de pronto:** marcado aqui, aparece como devolvido | Com um Firestore de mentira, a etiqueta troca de Aberto para Devolvido |
| sem itens | O aviso aparece |
| Editar | Mostra o aviso provisório |

Com esta tela, a task 5 ("Marcar como devolvido") também fecha a outra metade do seu critério de pronto: o item aparece como devolvido em "Meus itens".
