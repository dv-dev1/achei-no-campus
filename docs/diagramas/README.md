# Diagramas

Cada diagrama tem o fonte em PlantUML (`.puml`) e o SVG gerado ao lado, os dois versionados. Eles descrevem o app como ele está na `main`; os requisitos citados (RF-xx) estão em [`../requisitos.md`](../requisitos.md).

| Diagrama | O que mostra |
| --- | --- |
| [`casos-de-uso`](casos-de-uso.svg) | O que o aluno, o autor do item e o interessado fazem no app |
| [`dados`](dados.svg) | As coleções do Firestore (`usuarios`, `itens`, `conversas`, `mensagens`) e como se ligam |
| [`arquitetura`](arquitetura.svg) | O app Flutter falando com o Firebase (Auth, Firestore com as regras, Hosting) e com o Cloudinary |
| [`sequencia-chat`](sequencia-chat.svg) | A primeira mensagem de uma conversa e o contador de não lidas subindo e zerando |

## Gerar os SVG

Precisa de Java (o mesmo JDK 21 dos emuladores) e do PlantUML **1.2026.9**, o `plantuml-1.2026.9.jar` das [releases do PlantUML](https://github.com/plantuml/plantuml/releases). Da raiz do projeto:

```bash
java -jar plantuml-1.2026.9.jar -charset UTF-8 -tsvg docs/diagramas/*.puml
```

O `-charset UTF-8` garante os acentos no Windows. Os diagramas usam o layout embutido do PlantUML (`!pragma layout smetana`), então não precisa instalar o Graphviz, e o SVG sai igual em qualquer máquina com a mesma versão. Depois de mudar um `.puml`, gere de novo e commite o `.svg` junto. Para conferir que os SVG estão em dia, gere e rode `git status --short docs/diagramas`: não pode listar nada.
