# Filtros e busca

No topo do feed fica uma barra para achar um item rápido, sem rolar a lista inteira. Ela tem o campo de busca e, embaixo, os chips de filtro. Tudo pode ser combinado: dá para pedir, por exemplo, "achados, de Eletrônicos, na Biblioteca, com *fone* no texto".

## O que tem na barra

| Parte | Como funciona |
| --- | --- |
| **Busca** | Procura no título e na descrição. Não diferencia maiúsculas nem acentos: `termica`, `Térmica` e `TÉRMICA` acham a mesma garrafa. O **×** apaga o texto. |
| **Todos / Perdidos / Achados** | Escolha única. Começa em Todos. |
| **Categoria ▾** | Abre uma lista embaixo da tela. Escolhida a categoria, o chip fica marcado e mostra o nome dela. "Todas as categorias" desfaz. |
| **Local ▾** | Igual à categoria, para o local. |
| **Limpar** | Só aparece com algum filtro ligado. Desliga tudo e apaga a busca. |

Quando nenhum item passa nos filtros, a tela diz "Nenhum item com esses filtros." e mostra o botão **Limpar filtros**.

## Por que roda no app, e não no Firestore

O Firestore não faz busca por texto ("contém *fone*"). Por isso o filtro e a busca rodam no próprio app, em cima dos até 200 itens que o feed já carregou. Na prática:

- trocar filtro ou digitar não gasta leitura do Firestore nem espera a rede;
- o filtro continua valendo quando chega um item novo em tempo real;
- o limite é que só entram na busca os 200 itens abertos mais recentes, o que sobra para um campus.

## De onde vêm as opções de categoria e local

Os chips mostram **só as categorias e os locais que aparecem nos itens carregados**, sem repetir e em ordem alfabética. Assim ninguém escolhe um local onde não há nada e dá de cara com uma lista vazia.

A spec prevê listas fixas no `lib/config.dart`, que é tarefa do Daniel e ainda não existe. Se o grupo preferir mostrar sempre a lista completa, a troca fica no `lib/telas/feed.dart`:

```dart
// hoje
categorias: opcoesDe(itens, (item) => item.categoria),
locais: opcoesDe(itens, (item) => item.local),

// com as listas fixas do config.dart
categorias: categorias,
locais: locais,
```

## Onde está cada coisa

| Arquivo | O que faz |
| --- | --- |
| `lib/util/filtro.dart` | A regra: a classe `Filtro` (o que está escolhido e se um item passa), `opcoesDe` (as opções dos chips) e `normalizar` (tira acentos e maiúsculas) |
| `lib/widgets/barra_de_filtros.dart` | A barra que a pessoa vê e toca |
| `lib/telas/feed.dart` | Guarda o filtro atual e aplica na lista antes de desenhar |

A regra fica separada da tela de propósito: dá para testar o filtro sem abrir tela nenhuma, e a tela fica mais fácil de ler.

## Testes

```bash
flutter test test/filtro_test.dart test/filtros_feed_test.dart
```

| Teste | Confere |
| --- | --- |
| `filtro_test.dart` | O critério de pronto da tarefa (achado + Eletrônicos + Biblioteca + "fone" mostra só os itens certos, inclusive um que tem "FÔNE" só na descrição), cada filtro sozinho, a busca sem acento e sem maiúscula, o limpar e a ordem das opções |
| `filtros_feed_test.dart` | A tela de verdade: tocar em Perdidos, escolher um local na lista, digitar uma busca sem acento, e o aviso de "nenhum item" com o Limpar |
