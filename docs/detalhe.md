# Tela de detalhe

É a tela que abre quando alguém toca num card do feed. Ela mostra tudo o que se sabe sobre o item e é daqui que a pessoa entra em contato com quem publicou.

## O que aparece

De cima para baixo:

1. **Barra do topo:** "Item perdido" ou "Item achado", com a seta para voltar ao feed.
2. **Foto grande**, na largura da tela (proporção 4:3). Sem foto, ou se o link falhar, aparece um ícone no lugar. Se o item já foi devolvido, logo abaixo vem a faixa amarela "Este item já foi devolvido.".
3. **Etiqueta** Perdido (amarela) ou Achado (azul), a mesma do card.
4. **Título** e **descrição**. Se o item não tiver descrição, esse trecho some.
5. **Informações**, cada uma com um ícone:
   - Categoria;
   - **Perdido em** ou **Achado em**, conforme o tipo, com o local;
   - Publicado: data, hora e há quanto tempo, por exemplo "06/10/2026 às 14:30 (há 2 h)";
   - Publicado por: o nome de quem postou. Se for você, aparece "(você)" do lado.
6. **Um botão preso no rodapé**, que muda conforme quem está vendo.

## O botão do rodapé

| Quem está vendo | Botão |
| --- | --- |
| Outra pessoa | **Conversar** |
| Quem publicou | **Marcar como devolvido** (ver [`devolvido.md`](devolvido.md)) |
| Qualquer um, com o item já devolvido | Nenhum |

Quem publicou não precisa conversar consigo mesmo, então para ele o Conversar dá lugar ao devolvido.

Para saber quem está usando o app, a tela pergunta ao Firebase Auth (`FirebaseAuth.instance.currentUser?.uid`) e compara com o `autorId` do item.

Nos testes não há Firebase, então a tela aceita esse dado pronto pelo parâmetro `uidDoUsuario`. O feed repassa o mesmo parâmetro quando abre o detalhe. No app de verdade ninguém precisa passar nada.

## O botão Conversar

Abre a conversa com quem publicou, sobre este item. Se for a primeira vez, a conversa nasce na primeira mensagem. Ver [`chat.md`](chat.md).

## Editar e apagar

Para quem publicou, a barra do topo também tem os ícones **Editar** e **Apagar**. Essa parte é do Daniel (`lib/itens.dart` e `lib/telas/publicar.dart`).

## Onde está cada coisa

| Arquivo | O que faz |
| --- | --- |
| `lib/telas/detalhe.dart` | A tela e a função `dataEHora`, que monta o "06/10/2026 às 14:30 (há 2 h)" |
| `lib/telas/feed.dart` | Abre o detalhe quando um card é tocado |
| `lib/widgets/card_item.dart` | A `EtiquetaTipo`, usada no card e aqui |

## Testes

```bash
flutter test test/detalhe_test.dart
```

| Teste | Confere |
| --- | --- |
| mostra todos os dados do item | Título, tipo, descrição, categoria, local, data e autor |
| outra pessoa vê o botão Conversar | O botão aparece e, por enquanto, mostra o aviso |
| o autor não vê o botão Conversar | O botão some e o nome ganha o "(você)" |
| tocar num card do feed abre o detalhe certo | O critério de pronto da tarefa: do feed para o detalhe, com os dados do item tocado |
| data e hora por extenso | O formato de `dataEHora` |
