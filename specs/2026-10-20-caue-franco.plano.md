# Plano — issues do Cauê no Achei no Campus (#3, #4, #8, #6)

Responsável: Cauê (`cauedev30`). Base: `origin/main` em `56886de` (14/10/2026).
Repo: `dv-dev1/achei-no-campus`. Clone: `C:\Users\Administrator\Desktop\achei-no-campus`.

## Contexto

Na redistribuição de 20/10/2026, quatro issues abertas ficaram com o Cauê:

| Ordem | Issue | O que é | Severidade |
|---|---|---|---|
| 1 | #3 | A conversa fica carregando para sempre depois da primeira mensagem | alta |
| 2 | #4 | A busca com duas palavras não encontra o item | média |
| 3 | #8 | `docs/requisitos.md` e `docs/diagramas/` | bloqueia a #9 (Lúcio) |
| 4 | #6 | Cloudinary de verdade e item com foto | bloqueia a #7 e a #11 |

As issues valem como spec: cada uma traz o "pronto quando". A ordem vai da mais grave à que
depende de ação externa (criar a conta no Cloudinary). A #8 vem depois da #3 e da #4 para os
documentos descreverem o app já corrigido.

### Causa provável da #3 (confirmar na tarefa 1.1)

`lib/telas/conversa.dart` decide que a conversa "existe" quando ela aparece em
`Conversas.minhas()`. Só que, na primeira mensagem, ela aparece ali **pela gravação local
pendente** do `set`, antes de o servidor confirmar. Nesse instante a tela já assina
`Conversas.mensagens(id)`. Do lado do servidor, a regra de leitura de `mensagens`
(`firestore.rules:91`) faz `get()` numa conversa que ainda não existe, e a leitura é negada.
O stream termina com erro. O `StreamBuilder` das mensagens não tem ramo `hasError`, então mostra
o carregando para sempre. E como o `_mensagens ??=` guarda o stream que falhou, a tela nunca
tenta de novo. Ao recarregar, a conversa já existe e tudo funciona.

O `docs/chat.md` (item 3 dos "três cuidados") já pedia isso: "as mensagens só são escutadas
depois que a conversa existe". O código conferia a existência pelo cache local, não pelo servidor.

## Restrições globais

- `StreamBuilder` e `setState`, sem biblioteca de estado. Modelo `Conversa`, schemas e
  `firestore.rules` **não mudam**.
- Código no estilo do repo: português, comentários explicando o porquê, guia em `docs/` por parte.
- Antes de editar: `git pull --ff-only origin main`. Antes de todo push: `git fetch` e conferir
  que a `main` não andou.
- Commits pequenos, um assunto cada, mensagem em pt-BR, autor `cauedev30 <cauefranco01@gmail.com>`,
  sem Co-Authored-By. No comando com `git commit`, usar `cd "C:/Users/Administrator/Desktop/achei-no-campus"`,
  nunca `/c/...`.
- **Push só com o aval do Cauê**, no ponto de parada de cada etapa. **Sem comentário nas
  issues** (decisão do Cauê em 20/10): o que iria no comentário fica na seção "Registro da
  execução", no fim deste plano, e sobe no mesmo push.
  Quem corrige não fecha a issue: o Lúcio retesta e fecha (`docs/testes.md`, seção 4).
- Teste novo falha antes da correção (TDD). Os casos `todo` de `web-ct.test.js` são o reteste.
- `docs/testes.md` é do Lúcio: os resultados vão no "Registro da execução", não nesse arquivo.

Comandos de verificação (a partir da raiz do clone; em `firestore-tests/` para os `npm`):

```text
V1  flutter analyze                       → No issues found!
V2  flutter test                          → All tests passed!
V3  flutter build web                     → Built build/web
V4  emulators:exec ... "npm test"         → fail 0 (regras)
V5  emulators:exec ... "npm run test:ct"  → fail 0 (casos W no Chrome)
```

`emulators:exec` = `npx --no-install firebase emulators:exec --config ../firebase.json --project demo-achei-no-campus --only auth,firestore "<script>"`.
O V5 exige o V3 antes, porque o `driver.mjs` serve o `build/web`. O Chrome está instalado em
`C:\Program Files\Google\Chrome`, então não precisa de `CHROME_BIN`. O Java 21 já está no PATH.

---

## Etapa 0 — Preparar o clone

### Tarefa 0.1 — Atualizar e medir a base
- **Arquivos:** nenhum.
- **Passos:** `git pull --ff-only origin main` (o clone está 4 commits atrás: `2acfd55`..`56886de`,
  os commits do Lúcio). Conferir que `git config user.name`/`user.email` locais são
  `cauedev30`/`cauefranco01@gmail.com`; se não forem, gravar num comando separado. `npm ci` em
  `firestore-tests/`.
- **Testes:** V1 a V5 na base, sem mudança nenhuma.
- **Pronto quando:** V1–V4 verdes e V5 com `tests 28 · pass 24 · fail 0 · todo 4`, como o Lúcio
  registrou. Se divergir, parar e reportar antes de mexer em código.

### Tarefa 0.2 — Plano no repo
- **Arquivos:** `specs/2026-10-20-caue-franco.plano.md` (padrão do `specs/2026-10-06-daniel-vieira.plano.md`).
- **Passos:** copiar este plano sem a seção "Fora do repositório".
- **Commit:** `docs: plano das issues do Cauê (#3, #4, #6 e #8)`.
- **Pronto quando:** o commit existe localmente; o push sai junto com a etapa 1.

---

## Etapa 1 — #3: a conversa nova trava no carregando

### Tarefa 1.1 — Reproduzir e confirmar a causa (sem commit)
- **Passos:**
  1. Tirar o `todo` do CT-27 em `firestore-tests/web-ct.test.js`, rodar V3 + V5 e ver o CT-27 falhar.
  2. Diagnóstico temporário: no `StreamBuilder` das mensagens, um ramo `hasError` que mostra
     `snapshot.error` na tela; no CT-27, imprimir `visitante.rotulos()` depois de tocar em Enviar.
  3. Esperado: o erro é `permission-denied` na escuta de `conversas/{id}/mensagens`.
- **Decisão em aberto:** se o erro **não** for esse (por exemplo, `criadoEm` nulo, a suspeita
  do Lúcio), parar, desfazer o diagnóstico e reescrever as tarefas 1.2–1.4 antes de seguir.
- **Pronto quando:** a causa está confirmada com o texto do erro em mãos, e o diagnóstico
  temporário foi desfeito.

### Tarefa 1.2 — A regra que explica o defeito, em teste
- **Arquivos:** `firestore-tests/chat.test.js`.
- **Teste novo:** "as mensagens de uma conversa que ainda não existe não podem ser lidas (por
  isso a tela espera o servidor)". O participante tenta listar `conversas/{id}/mensagens` antes
  do `set` da conversa: `assertFails`. Depois do `set`: `assertSucceeds`. Fica ao lado do teste
  existente "a conversa nova não pode ser lida antes de existir".
- **Observação:** este teste passa desde já, porque documenta o comportamento da regra, que não
  muda. Ele não é o vermelho do TDD; o vermelho é o CT-27 da tarefa 1.1.
- **Commit:** `test: regra nega ler mensagens antes de a conversa existir`.
- **Pronto quando:** V4 com `fail 0` e um teste a mais que antes.

### Tarefa 1.3 — Erro no stream das mensagens aparece na tela
- **Arquivos:** `lib/telas/conversa.dart` (`_listaDeMensagens`).
- **Interface:** no `StreamBuilder<List<Mensagem>>`, um ramo `snapshot.hasError` antes do
  `!hasData`, que devolve
  `Aviso(icone: Icons.cloud_off, texto: 'Não foi possível carregar as mensagens.', acao: <botão "Tentar de novo">)`.
  O botão faz `setState(() => _mensagens = null)`, e o `??=` assina de novo no próximo build.
  Reusa o `Aviso` de `lib/widgets/aviso.dart`, igual ao ramo de erro que já existe para `_minhas`.
  Sem retentativa automática, para não entrar em laço contra uma regra que nega.
- **Testes:** V1 e V2. O `fake_cloud_firestore` não emite erro de regra, então este ramo só é
  exercitado de verdade pelo V5. Registrar isso no guia (tarefa 1.5).
- **Commit:** `fix: erro ao carregar as mensagens aparece na tela, com tentar de novo`.
- **Pronto quando:** nenhuma falha de stream das mensagens fica mais num carregando infinito.

### Tarefa 1.4 — A conversa nova só escuta as mensagens depois de gravada no servidor
- **Arquivos:** `lib/telas/conversa.dart` e `firestore-tests/web-ct.test.js`.
- **Interface:**
  - campo novo `bool _criandoConversa = false` em `_TelaConversaState`, com um comentário
    explicando o porquê (a gravação local aparece em `minhas()` antes de o servidor confirmar);
  - `_enviar({required bool jaExiste})`: quando `!jaExiste`, liga `_criandoConversa` no mesmo
    `setState` que liga `_enviando`, e desliga no `finally`;
  - `_listaDeMensagens(Conversa? atual)`: enquanto `atual == null || _criandoConversa`, continua
    o aviso "Mande a primeira mensagem…" e não assina `mensagens()`. Depois que `Conversas.enviar`
    volta, o `set` e o `add` já foram confirmados pelo servidor, então a assinatura é permitida.
  - Casos de borda: se o `set` falha, a gravação local é desfeita e `atual` volta a ser nulo. Se o
    `add` falha, a conversa existe no servidor e a lista abre vazia, com o SnackBar de erro.
  - `lib/conversas.dart` e `lib/modelos/conversa.dart` **não mudam**.
- **Testes:**
  - tirar o `todo` do CT-27, CT-28 e CT-29/30 em `web-ct.test.js` (os três `test` que citam a #3);
  - `test/chat_telas_test.dart` continua verde sem mudança: os fluxos de Bruno e Ana, Conversar
    duas vezes e mensagem em branco;
  - V1, V2, V3, V4 e V5.
- **Commit:** `fix: conversa nova espera o servidor antes de escutar as mensagens (#3)`.
- **Pronto quando:** V5 com `fail 0` e `todo 1` (só sobra o CT-21 da #4), e os CT-27 a CT-30 passando.

### Tarefa 1.5 — Guia do chat
- **Arquivos:** `docs/chat.md`.
- **Conteúdo:** no item 3 dos "três cuidados", explicar que "existe" quer dizer **confirmada pelo
  servidor**, não só visível no cache local, e por que a tela espera o `enviar` voltar. Na tabela
  de testes, citar o CT-27 a CT-30 do `web-ct.test.js` e o teste novo do `chat.test.js`. Dizer que
  o `fake_cloud_firestore` não simula as regras, então a regressão é pega pelo `test:ct`.
- **Commit:** `docs: chat explica por que a conversa nova espera o servidor`.
- **Pronto quando:** o guia descreve o código como ele ficou.

**⏸ Ponto de parada da etapa 1** (ver a rotina no fim).

---

## Etapa 2 — #4: busca com várias palavras

### Tarefa 2.1 — Busca por palavras, em qualquer ordem
- **Arquivos:** `lib/util/filtro.dart`, `test/filtro_test.dart` e `firestore-tests/web-ct.test.js`.
- **Interface:** a assinatura `Filtro.aceita(Item item) → bool` não muda. A busca normalizada é
  quebrada em palavras por espaço, descartando as vazias. Todas as palavras precisam aparecer
  (`contains`, que continua achando pedaço de palavra) no texto `"<título> <descrição>"`
  normalizado. Uma palavra pode estar no título e outra na descrição. Sem palavra nenhuma, aceita.
  `normalizar`, `ativo`, `limpar` e `opcoesDe` não mudam.
- **Testes (escritos antes, vermelhos antes da correção):** um `test` novo em `filtro_test.dart`
  usando a lista `itens` que já existe:
  - `'carregador fone'` → `['4']` (uma palavra no título, outra na descrição com acento);
  - `'fone azul'` e `'azul fone'` → `['3']` (a ordem não importa);
  - `'fone   azul'`, com espaços repetidos → `['3']`;
  - `'fone verde'` → `[]` (uma palavra que falta derruba o item).
  
  Os testes que já existem continuam verdes, inclusive o `'  FONE '`. Tirar o `todo` do CT-21
  em `web-ct.test.js`.
- **Commit:** `fix: busca aceita várias palavras em qualquer ordem (#4)`.
- **Pronto quando:** V1, V2 e V3 verdes, e V5 com `fail 0` e `todo 0`.

### Tarefa 2.2 — Guia dos filtros
- **Arquivos:** `docs/filtros.md`.
- **Conteúdo:** na linha **Busca** da tabela, explicar as várias palavras com um exemplo
  (`garrafa prata` acha "Garrafa térmica prata"). Na tabela de testes, citar o caso novo e o CT-21.
- **Commit:** `docs: filtros explica a busca por várias palavras`.

**⏸ Ponto de parada da etapa 2.**

---

## Etapa 3 — #8: requisitos e diagramas

### Tarefa 3.1 — Instalar o PlantUML (fora do repo)
- **Passos:** baixar o `plantuml-<versão>.jar` da última versão estável em
  `github.com/plantuml/plantuml/releases` para `C:\Users\Administrator\development\plantuml\`.
  Anotar a versão exata. Rodar com `java -jar <jar>`.
- **Decisão (recomendada):** usar `!pragma layout smetana` em todo `.puml`. É o layout embutido
  no próprio jar, então não precisa do Graphviz, e o SVG sai igual em qualquer máquina com o
  mesmo jar. Se algum diagrama ficar ilegível com ele, instalar o Graphviz e registrar a troca.
- **Pronto quando:** `java -jar <jar> -version` responde, e um `.puml` de teste vira SVG duas
  vezes seguidas sem diferença.

### Tarefa 3.2 — `docs/requisitos.md`
- **Arquivos:** `docs/requisitos.md`.
- **Conteúdo** (sai da leitura do código da `main` na hora de escrever, não do plano da spec):
  - **RF-01…** cada um com: o que faz, a tela ou o arquivo e o `CT-xx` que prova. Rascunho, a
    conferir no código:

    | RF | O que faz | Arquivos | CT |
    |---|---|---|---|
    | 01 | Cadastro só com `@cs.unipe.edu.br` | `telas/entrar.dart`, `sessao.dart`, `config.dart` | 01, 02, 03, 06 |
    | 02 | Verificação de e-mail obrigatória | `telas/entrar.dart`, `sessao.dart` | 04, 05 |
    | 03 | Entrar e sair | `telas/entrar.dart`, `telas/perfil.dart` | 05, 07, 10 |
    | 04 | Perfil com nome e curso | `telas/perfil.dart` | 08, 09 |
    | 05 | Publicar item perdido ou achado, com aviso de LGPD | `telas/publicar.dart`, `itens.dart` | 11, 12, 13 |
    | 06 | Foto do item | `cloudinary.dart` | 14, 15, 16 |
    | 07 | Feed em tempo real | `telas/feed.dart` | 17, 18 |
    | 08 | Filtros | `util/filtro.dart`, `widgets/barra_de_filtros.dart` | 19, 22, 23 |
    | 09 | Busca | `util/filtro.dart` | 20, 21 |
    | 10 | Detalhe do item | `telas/detalhe.dart` | 24, 25, 26 |
    | 11 | Chat por item | `telas/conversa.dart`, `conversas.dart` | 27, 28, 32 |
    | 12 | Aba Mensagens e não lidas | `telas/mensagens.dart`, `telas/inicio.dart` | 29, 30 |
    | 13 | Marcar como devolvido | `widgets/devolver.dart` | 33, 34 |
    | 14 | Meus itens | `telas/meus_itens.dart` | 35 |
    | 15 | Editar e apagar o próprio item | `telas/publicar.dart`, `itens.dart` | 36, 37, 38 |

  - **RNF:**
    - domínio verificado também nas regras (CT-39, CT-40);
    - conversa só dos participantes e autoria imutável (CT-31, CT-41);
    - planos grátis (Spark e Cloudinary);
    - plataformas (web, Android e iOS) e o estado de cada uma hoje;
    - busca no cliente sobre os 200 itens mais recentes (conferir o `limit` em `itens.dart`/`feed.dart`);
    - tempo real com o app aberto, sem push;
    - interface em pt-BR e identidade visual (CT-43).
  - **Histórias de usuário** ("Como aluno que perdeu…, quero…, para…"): uma por papel, a saber
    aluno, autor do item e interessado.
  - **Fora de escopo:** a lista da spec (seção "Fora de escopo") e o que a `main` ainda não
    entrega, apontando a issue: Firebase real (#5), Hosting (#7), APK (#11) e iOS (#12).
- **Pronto quando:** todo RF cita pelo menos um `CT-xx` que existe em `docs/testes.md` (conferir
  com `grep` cada código citado).

### Tarefa 3.3 — Diagramas
- **Arquivos:** `docs/diagramas/{casos-de-uso,dados,arquitetura,sequencia-chat}.puml` e o `.svg`
  gerado de cada um.
- **Conteúdo:**
  - `casos-de-uso`: os atores Aluno, Autor do item e Interessado (os dois últimos herdam de
    Aluno), com os casos dos RF;
  - `dados`: `usuarios`, `itens`, `conversas` e `mensagens`, com os campos da spec ("Modelo de
    dados"), o ID fixo `{itemId}_{interessadoUid}` e as relações;
  - `arquitetura`: o app Flutter (web, Android e iOS) falando com o Firebase Auth, o Firestore
    (com as regras), o Cloudinary e o Hosting; o Hosting marcado como previsto (#7);
  - `sequencia-chat`: primeira mensagem (`set` da conversa → confirmação do servidor → `add` da
    mensagem → só então a tela escuta as mensagens, a correção da #3), o `naoLidas` do dono sobe,
    o dono abre a conversa e o `marcarComoLida` zera.
- **Testes:** gerar todos com `java -jar <jar> -tsvg docs/diagramas/*.puml`, commitar, gerar de
  novo e rodar `git status --short docs/diagramas`: não pode listar nada. Conferir se o
  `core.autocrlf` não marca os `.svg` como alterados.
- **Commits:** `docs: requisitos do app entregue (#8)` (3.2) e
  `docs: diagramas de casos de uso, dados, arquitetura e chat (#8)` (3.3).
- **Pronto quando:** o critério da issue passa, com `plantuml` trocado por `java -jar <jar>`.

### Tarefa 3.4 — README
- **Arquivos:** `README.md`.
- **Conteúdo:** uma linha linkando `docs/requisitos.md` e `docs/diagramas/`, com o comando para
  gerar os SVG e a versão do PlantUML usada.
- **Commit:** `docs: README aponta requisitos e diagramas`.

**⏸ Ponto de parada da etapa 3.** No registro da execução, avisar o Lúcio que a #9 está liberada.

---

## Etapa 4 — #6: Cloudinary de verdade

### Tarefa 4.1 — Conta e preset (ação do Cauê)
- **Decisão em aberto, no início da etapa:** quem cria o preset no console. Ou o Cauê, seguindo
  os passos, ou a IA, pela sessão dele no Chrome. A conta é sempre ele quem cria.
- **Preset:**
  - **unsigned**, com nome sugerido `achei_unsigned`;
  - pasta `achei`;
  - formatos `jpg,png,webp`;
  - transformação de entrada `c_limit,w_1280,h_1280`.
- **Risco a conferir:** a documentação pública do Cloudinary não mostra um limite de tamanho por
  preset. Se o console não tiver essa opção, os 2 MB continuam garantidos só pelo app
  (`limiteFotoBytes` em `config.dart`). Isso fica registrado no README e no comentário da issue,
  porque um dos itens do "pronto quando" da #6 não teria como passar.
- **Pronto quando:** o cloud name e o nome do preset estão anotados.

### Tarefa 4.2 — Conferir o preset direto na API
- **Passos:** pelo `curl` da issue:
  - uma imagem pequena → `200`, com `secure_url` em `res.cloudinary.com/<cloud name>/…/achei/…`;
  - um PDF → recusado;
  - uma imagem acima de 2 MB → anotar o que acontece (ver o risco da 4.1).
  
  Apagar no console as imagens de teste.
- **Pronto quando:** os três resultados estão anotados para o comentário da issue.

### Tarefa 4.3 — Foto de verdade no app, na web
- **Passos:** emuladores no ar e
  `flutter run -d chrome --dart-define=CLOUDINARY_CLOUD_NAME=<…> --dart-define=CLOUDINARY_UPLOAD_PRESET=<…>`.
  - CT-14: publicar com foto da galeria; a foto aparece no card e no detalhe, e a `fotoUrl`
    gravada é do `res.cloudinary.com/<cloud name>/`, na pasta `achei`;
  - CT-16: imagem acima de 2 MB → `A foto deve ter no máximo 2 MB.`, sem publicar;
  - CT-15: câmera, se a máquina tiver webcam; senão fica ⏳ com o motivo.
- **Decisão em aberto:** quem executa. Ou o Cauê à mão, ou a IA pelo Chrome (com `file_upload`).
- **Android:** fica para a #11, porque esta máquina não tem Android SDK. Registrar no comentário.
- **Pronto quando:** CT-14 e CT-16 passam na web, com print.

### Tarefa 4.4 — README
- **Arquivos:** `README.md`, seção "Fotos".
- **Conteúdo:**
  - o cloud name e o nome do preset (não são segredo);
  - as restrições do preset;
  - os dois `--dart-define` para rodar e buildar com foto (sem eles, o app segue publicando sem
    foto, como hoje);
  - o que ficou de fora (Android pela #11, e o limite de 2 MB se a 4.1 confirmar o risco).
  
  Tirar a frase "Esta entrega testa HTTP simulado; não faz upload real".
- **Commit:** `docs: README registra o Cloudinary do projeto (#6)`.

**⏸ Ponto de parada da etapa 4.** No registro da execução, deixar os valores para o Daniel usar na #5, #7 e #11.

---

## Rotina do ponto de parada (fim de cada etapa)

1. Rodar de novo o que a etapa pede (V1–V5) e mostrar a saída ao Cauê.
2. **Pedir o aval** para o push. Com o aval, `git fetch`: se a `main` andou, rebase e repetir o
   passo 1. Depois, `git push origin main`.
3. Registrar a etapa em "Registro da execução": os commits, a saída do `test:ct`, o que fica
   para o reteste do Lúcio e o que fica pendente, com o responsável.
4. Só então começar a etapa seguinte.

## Checklist

- [x] 0.1 Clone atualizado e base medida (V5 = `pass 24 · todo 4`)
- [x] 0.2 Plano em `specs/2026-10-20-caue-franco.plano.md`
- [x] 1.1 Causa da #3 confirmada (`permission-denied`)
- [x] 1.2 Teste da regra de mensagens antes da conversa
- [x] 1.3 Ramo de erro das mensagens com "Tentar de novo"
- [x] 1.4 Conversa nova espera o servidor; CT-27 sem `todo` (CT-28 e CT-29/30: ver o registro)
- [x] 1.5 `docs/chat.md` atualizado
- [x] ⏸ Etapa 1: push e registro (#3)
- [x] 2.1 Busca por várias palavras; CT-21 sem `todo`
- [x] 2.2 `docs/filtros.md` atualizado
- [x] ⏸ Etapa 2: push e registro (#4)
- [x] 3.1 PlantUML instalado e determinístico
- [x] 3.2 `docs/requisitos.md`
- [x] 3.3 Quatro diagramas `.puml` + `.svg`
- [x] 3.4 README com os links
- [x] ⏸ Etapa 3: push e registro (#8)
- [x] 4.1 Conta e preset do Cloudinary
- [x] 4.2 Preset conferido na API
- [x] 4.3 CT-14 e CT-16 na web
- [x] 4.4 README "Fotos"
- [x] ⏸ Etapa 4: push e registro (#6)

## Registro da execução

Máquina: Windows 10, Flutter 3.47.6, Node 24, JDK 21, Chrome 155.

### Etapa 0 — base (20/10/2026)

A base em `56886de` deu `test:ct` com `pass 23 · fail 1 · todo 4`, e não `pass 24` como na
rodada do Lúcio. O CT-26 falhava: em tela larga a foto 4:3 do detalhe passava da altura da
janela e escondia o título. O Daniel corrigiu isso em `b8a3eb9` no mesmo dia (altura máxima
de 400 px); a correção paralela do Cauê foi descartada no rebase.

### Etapa 1 — #3, conversa carregando para sempre

Commits: `77dcc41` (teste da regra), `29ffe11` (erro das mensagens na tela), `99b7646`
(correção) e `6f39942` (guia). CI do push: `success`.

**Causa confirmada:** na primeira mensagem, logo depois do `set`, a conversa já aparecia em
`Conversas.minhas()` pela gravação local, antes de o servidor confirmar. A tela escutava
`conversas/{id}/mensagens` nesse instante e a regra negava a leitura, porque no servidor a
conversa ainda não existia:

```text
[cloud_firestore/permission-denied]
evaluation error at L91:24 for 'list' @ L91, Null value error.
```

O `StreamBuilder` das mensagens não tinha ramo de erro, então ficava no carregando. A
suspeita do `criadoEm` nulo não se confirmou.

**Correção:** `lib/telas/conversa.dart` espera o `enviar` da primeira mensagem voltar antes de
escutar as mensagens. Erro no stream agora mostra "Não foi possível carregar as mensagens."
com **Tentar de novo**. O porquê está em `docs/chat.md`.

**Resultado em `6f39942`:** `flutter test` 82 verdes · `npm test` `pass 30 · fail 0` · CT-27 ✔.

**Para o Lúcio (reteste e fechamento da #3):** o CT-27 saiu do `todo`. O CT-28 e o CT-29/30
continuam `todo`: o app já faz o que eles pedem, mas o roteiro trava em passos que nunca
tinham sido executados, porque antes o teste parava no defeito.

1. Com não lidas, o rótulo da aba é `1\nMensagens` (número e nome juntos), então
   `tocar('Mensagens')` e `esperarRotulo('1')` não acham por igualdade exata.
2. No CT-29/30, `tocar('Feed')` roda com a conversa aberta por cima das abas; falta voltar.

Com este ajuste em `firestore-tests/web-ct.test.js`, os três passaram:

```diff
 // CT-28
-  await dono.tocar('Mensagens');
+  await dono.tocarContendo('Mensagens');

 // CT-29 e CT-30
-  await dono.esperarRotulo('1');
-  await dono.tocar('Mensagens');
+  await dono.esperarRotulo('1\nMensagens');
+  await dono.tocarContendo('Mensagens');
   await dono.tocarContendo('Fone branco');
   await dono.esperarTexto('E meu fone');
+  await dono.tocar('Voltar');
   await dono.tocar('Feed');
-  await esperarSem(dono, '1');
+  await esperarSem(dono, '1\nMensagens');
+  await dono.esperarRotulo('Mensagens');
```

O motivo escrito no `todo` desses dois casos ainda cita o defeito da #3.

### Etapa 2 — #4, busca com várias palavras

Commits: `bb8528f` (correção, CT-21 sem `todo`) e `bbeaedf` (guia).

`Filtro.aceita` (`lib/util/filtro.dart`) quebra a busca em palavras; cada uma precisa aparecer
no título ou na descrição, em qualquer ordem. `garrafa prata` acha "Garrafa térmica prata".

**Resultado:** `flutter test` 83 verdes · `npm run test:ct` `tests 28 · pass 26 · fail 0 · todo 2`
(os dois `todo` são o CT-28 e o CT-29/30 da etapa 1).

**Para o Lúcio:** reteste e fechamento da #4.

### Etapa 3 — #8, requisitos e diagramas

Commits: `1f7fac5` (`docs/requisitos.md`), `b3c74ac` (os quatro diagramas e
`docs/diagramas/README.md`) e `e7a615d` (link no README).

- `docs/requisitos.md`: 15 RF, 9 RNF, histórias por papel e o que ficou de fora. Os 45 `CT-xx`
  citados existem em `docs/testes.md`, e todo RF cita pelo menos um.
- `docs/diagramas/`: `casos-de-uso`, `dados`, `arquitetura` e `sequencia-chat`, cada um com o
  `.puml` e o `.svg`. PlantUML **1.2026.9** com `!pragma layout smetana` (sem Graphviz) e
  `-charset UTF-8`. Gerar de novo e rodar `git status --short docs/diagramas` não lista nada,
  inclusive com os `.puml` em CRLF (como o Windows faz no checkout).
- O critério da issue usa `plantuml -tsvg`; no Windows o comando é
  `java -jar plantuml-1.2026.9.jar -charset UTF-8 -tsvg docs/diagramas/*.puml`.

**Para o Lúcio:** a #9 (revisar requisitos e diagramas contra o app) está liberada. A pendência
"os documentos ainda não existem", em `docs/testes.md`, já pode sair.

### Etapa 4 — #6, Cloudinary de verdade

Commit: `70c52f3` (README, seção "Fotos").

**Conta e preset:** conta grátis do Cauê, cloud name `tbeq7obd`. Preset `achei_unsigned`
criado no console: unsigned, pasta `achei` com a pasta como prefixo do public ID, formatos
`jpg,png,webp`, transformação de entrada `c_limit,w_1280,h_1280`, public ID aleatório e
"Disallow public ID" ligado.

**Preset direto na API** (`curl` da issue):

| Envio | Resultado |
|---|---|
| PNG de 350 KB | `200`, `secure_url` em `res.cloudinary.com/tbeq7obd/image/upload/.../achei/...` |
| PDF | `400`, "Image file format pdf not allowed" |
| PNG de 3 MB | `200`: **aceito**. O Cloudinary não tem limite de tamanho por preset |
| PNG com `public_id=sobrescrever` | ignorado; o Cloudinary gerou um nome aleatório |

O item do "pronto quando" que pede o envio acima de 2 MB **recusado pelo Cloudinary** não tem
como passar: não existe essa opção no preset. Os 2 MB são garantidos pelo app
(`limiteFotoBytes`), e isso está registrado no README.

**No app, na web** (Chrome 155, build com os dois `--dart-define`, contra os emuladores):

- CT-14 ✅: item publicado com foto da galeria; a `fotoUrl` gravada é
  `https://res.cloudinary.com/tbeq7obd/image/upload/v1792519163/achei/lstiubyyakdrrodbmlnp.png`,
  e a foto aparece no card do feed e no detalhe (as duas requisições à foto voltaram `200`).
- CT-16 ✅: foto de 3 MB recusada na tela com "A foto deve ter no máximo 2 MB.".
- CT-15 ⏳: na web do computador, o botão Câmera só abre o seletor de arquivo; o teste real é
  no celular (#11).

A escolha do arquivo foi automatizada no navegador (o seletor nativo do Windows não é
operável pela automação); o resto do caminho é o do app: redimensionar, enviar e gravar.

**Para o Daniel:** cloud name `tbeq7obd` e preset `achei_unsigned` para a #5, a #7 e a #11
(os comandos estão no README).

**Para o Lúcio:** CT-14 a CT-16 na coluna A (Android), pela #11, e o reteste da coluna W.

**Para o Cauê:** apagar no Media Library do Cloudinary as imagens enviadas nos testes de
20/10 (três na raiz e três em `achei/`).

### Pendências de outras pessoas

| Quem | O quê |
|---|---|
| Lúcio | Ajustar o roteiro do CT-28 e do CT-29/30 (acima); retestar e fechar a #3 e a #4 |
| Lúcio | Revisar requisitos e diagramas (#9), agora liberada pela #8 |
| Lúcio | CT-14 a CT-16 no Android (#11) e reteste da coluna W |
| Daniel | Usar `tbeq7obd` e `achei_unsigned` nos builds da #5, #7 e #11 |
| Daniel | Defeito achado ao rodar `flutter run -d chrome` (modo debug): o botão **Já verifiquei** não faz nada. `_verificar` em `lib/main.dart:95` usa `setState(() => _acesso = ...)`, e a seta devolve o `Future`; no debug o Flutter lança "setState() callback argument returned a Future" antes de redesenhar. No build release a checagem não existe, por isso CI e `test:ct` não pegam. Correção: `setState(() { _acesso = widget.sessao.prepararAcesso(); });`. Contorno até lá: `flutter run -d chrome --release` |
| Daniel | O CI do `d7f7a17` (a #14) ficou mais de 2h30 "em andamento"; o do `6f39942`, logo depois, terminou em 9 min. Vale cancelar o travado |
| Daniel | Com a #3 e a #4, o `test:ct` do CI passa de `todo 4` para `todo 2` |
