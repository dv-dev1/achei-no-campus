# Feed (tela inicial)

O feed é a primeira tela depois do login. Ele mostra os itens perdidos e achados que ainda não foram devolvidos, os mais recentes primeiro, e se atualiza sozinho: quando alguém publica, o item aparece na tela de todo mundo sem precisar recarregar.

## Onde está cada coisa

| Arquivo | O que faz |
| --- | --- |
| `lib/telas/feed.dart` | A tela: busca os itens e decide o que mostrar (carregando, vazio, erro ou a lista) |
| `lib/widgets/card_item.dart` | O card de cada item e a etiqueta "Perdido"/"Achado", que o detalhe e "Meus itens" também vão usar |
| `lib/modelos/item.dart` | O modelo do item, com os mesmos campos do documento `itens/{id}` da spec |
| `lib/util/tempo.dart` | O texto "há 5 min", "ontem", "há 3 dias" |
| `lib/dados/itens_exemplo.dart` | Cinco itens de mentira, para ver o feed sem o Firebase |

## Como funciona

1. A tela pede ao Firestore os itens com `status == "aberto"`, ordenados por `criadoEm` do mais novo para o mais velho, no máximo 200.
2. Ela usa `.snapshots()`, não `.get()`. A diferença é que `snapshots()` fica escutando: toda vez que um item é criado, editado ou devolvido, o Firestore manda a lista nova e a tela se redesenha sozinha.
3. Um `StreamBuilder` escolhe o que aparece:
   - **carregando:** a rodinha, enquanto a primeira resposta não chega;
   - **erro:** "Não foi possível carregar os itens";
   - **vazio:** "Nenhum item ainda. Perdeu ou achou algo? Toque em Publicar.";
   - **lista:** um card por item.

Cada card mostra a foto (ou um ícone, se não houver foto ou o link falhar), a etiqueta (amarela para **Perdido**, azul para **Achado**), o título, a categoria e o local, e há quanto tempo foi publicado.

## Como o feed se liga ao resto do app

A base do Daniel (06/10) já ligou tudo o que o feed precisava:

- **Pacotes:** `cloud_firestore` e companhia estão no `pubspec.yaml`.
- **Rota de publicar:** o botão **Publicar** abre a rota `/publicar`, registrada no `onGenerateRoute` do `main.dart`.
- **Onde o feed aparece:** é a primeira aba da tela de início (`lib/telas/inicio.dart`), que o portão do login abre depois que o e-mail é verificado. Ver [`chat.md`](chat.md#a-barra-de-abas).
- **Índice composto:** filtrar por `status` e ordenar por `criadoEm` exige um índice, que já está versionado em `firestore.indexes.json`. Os emuladores não precisam dele, mas o Firebase de verdade sim. Quando o app for para lá, suba com `firebase deploy --only firestore:indexes`. Sem o índice, o feed cai no estado de erro e o console mostra `FAILED_PRECONDITION: The query requires an index`.

**Sobre o modelo do item:** `lib/modelos/item.dart` foi criado junto com o feed, seguindo os campos da spec, e a base do Daniel usa o mesmo modelo.

## Como ver o feed sem o Firebase

Enquanto o Firebase não está ligado, troque por um momento a `home` do `MaterialApp`:

```dart
home: TelaFeed(itens: Stream.value(itensDeExemplo())),
```

e rode `flutter run -d chrome`. Lembre de voltar para `const TelaFeed()` antes de commitar.

## Testes

```bash
flutter test test/feed_test.dart test/item_test.dart test/tempo_test.dart
```

| Teste | Confere |
| --- | --- |
| `feed_test.dart` | Carregando, vazio, erro, conteúdo do card, botão Publicar e o critério de pronto da tarefa: **um item novo aparece sem recarregar** |
| `item_test.dart` | Leitura de um documento completo, de um incompleto (não pode quebrar o feed) e ida e volta `paraMapa`/`deMapa` |
| `tempo_test.dart` | "agora mesmo", minutos, horas, "ontem", dias e a data depois de 30 dias |

O teste de tempo real usa um `StreamController` no lugar do Firestore: ele manda uma lista, depois uma lista com um item novo no topo, e confere se o card novo apareceu.

## Próximos passos que mexem aqui

- **Filtros e busca:** já estão no topo desta tela. Ver [`filtros.md`](filtros.md).
- **Detalhe:** tocar num card abre a tela de detalhe. Ver [`detalhe.md`](detalhe.md).
- **Meus itens:** fica na aba ao lado. Ver [`meus-itens.md`](meus-itens.md).
- **Perfil:** o ícone de pessoa no topo abre o perfil (tela do Daniel).
