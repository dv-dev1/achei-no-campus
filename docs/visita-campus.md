# Visita ao campus — conferir a lista de locais (CT-44)

Issue [#10](https://github.com/dv-dev1/achei-no-campus/issues/10). Folha para
levar no celular. A lista abaixo é a `locais` de `lib/config.dart` na ordem em
que aparece no app, que é a ordem do seletor na tela de publicar.

Data da visita: ____/____/______

## Como preencher

Para cada local, três perguntas:

- **Existe?** sim / não.
- **Como chamam?** o nome que os alunos usam de verdade, mesmo quando é
  diferente do nome oficial. É esse que vai para a lista: quem perdeu a mochila
  procura pelo nome que conhece.
- **Observação:** entrada separada, mais de um prédio com o mesmo nome, nome que
  mudou, qualquer coisa que torne a opção ambígua na hora de publicar.

| # | Nome em `lib/config.dart` | Existe? | Como chamam | Observação |
|---|---|---|---|---|
| 1 | Reitoria | | | |
| 2 | Bloco de Medicina | | | |
| 3 | Bloco de Odontologia | | | |
| 4 | Bloco de Enfermagem | | | |
| 5 | Bloco de Arquitetura | | | |
| 6 | EVA (Espaço de Vida Acadêmica) | | | |
| 7 | Biblioteca | | | |
| 8 | Centro de Informação | | | |
| 9 | Pós-Graduação | | | |
| 10 | Auditório | | | |
| 11 | Ginásio | | | |
| 12 | Piscina | | | |
| 13 | Clínica-escola | | | |
| 14 | Praça de alimentação/cantinas | | | |
| 15 | Passarela | | | |
| 16 | Estacionamento | | | |

`Outro` não entra na conferência: é o escape de quem não acha o local na lista e
fica sempre no fim.

## Locais que faltam

Lugar que existe no campus e não está na lista. Vale perguntar na portaria e no
achados e perdidos onde as pessoas mais perdem coisa — é esse o critério, não o
tamanho do prédio.

| Local | Por que entra |
|---|---|
| | |
| | |
| | |

## Antes de corrigir `lib/config.dart`

Duas armadilhas já conhecidas:

1. **Renomear trava a edição dos itens antigos** — defeito
   [#15](https://github.com/dv-dev1/achei-no-campus/issues/15), do Daniel.
   O seletor de local recebe o valor gravado no item e as opções vêm de
   `locais`; sem par na lista, a tela de editar lança em vez de abrir. Esperar a
   correção, e decidir com ele o que fazer com os itens já publicados com o nome
   antigo.
2. **Três nomes estão fixos em testes** — `Biblioteca`, `Reitoria` e `Ginásio`
   aparecem em 12 arquivos de `test/`, entre eles `test/detalhe_test.dart`,
   `test/feed_test.dart` e `test/filtro_test.dart`. Mexer num dos três obriga a
   atualizar os testes no mesmo commit, senão `flutter test` fica vermelho — e o
   "Pronto quando" da #10 exige ele verde.

## Depois da visita

1. Corrigir `lib/config.dart`, mantendo `Outro` no fim.
2. `flutter analyze` e `flutter test`.
3. Marcar CT-44 ✅ em `docs/testes.md` com a data desta visita.
4. Anotar na #10 o que mudou e o que ficou de fora.
