# Plano — entrega final do Achei no Campus

Spec: `specs/2026-11-26-entrega-final.md` (decisões D1 a D9). Responsável: Cauê (`cauedev30`).
Base: `main` em `1156cce` (26/11/2026). Clone: `C:\Users\Administrator\Downloads\Vault_01\workspace-achei-no-campus\repo` (desde 26/11; o do
Desktop ficou obsoleto). A sessão abre na pasta do workspace, que tem o estado e o contexto.

> Para quem executa: uma tarefa por vez, na ordem, marcando o checklist no fim. O plano diz **o
> que** fazer, com arquivos, interfaces, testes e "pronto quando"; o código é escrito na
> implementação. Se algo mudar no caminho, atualize esta tarefa (e as seguintes, se mudar um
> contrato entre etapas) antes de seguir.

## Ordem de execução (mudada em 26/11/2026)

Os números das etapas não mudam, só a ordem. Depois da etapa 2, o Cauê decidiu adiantar o que põe
o app no ar com link público, porque a apresentação ainda não tem data, mas está perto:
**1 → 2 → 4 → 6 → 7 → 3 → 5 → 8 → 9**. As dependências continuam valendo: a 6 depois da 4, e a 5
depois da 3.

Consequência: a 3 e a 5 mudam `lib/` **depois** do primeiro deploy (etapa 7). Por isso, cada uma
termina com um redeploy do Hosting, com os dois comandos da tarefa 7.1 (build com os
`--dart-define` e `firebase deploy --only hosting`) e uma olhada rápida na URL pública. Isso entra
no ponto de parada delas.

## Restrições globais

- Commits em pt-BR, um assunto por commit, autor `cauedev30 <cauefranco01@gmail.com>`, **sem**
  Co-Authored-By. No comando com `git commit`, use `cd "C:/Users/Administrator/Downloads/Vault_01/workspace-achei-no-campus/repo"`
  (a hook de autor lê identidade vazia com caminho `/c/...`).
- **Fechar issue pelo commit (D5):** o GitHub só reconhece palavra-chave em inglês. A última linha do
  corpo da mensagem é `Closes #N` (uma por issue: `Closes #3, closes #4`). Nada de comentário em issue.
- Antes de editar: `git pull --ff-only origin main`. Antes de todo push: `git fetch` e conferir
  `git log HEAD..origin/main`. **Push só com o ok do Cauê**, no ponto de parada de cada etapa.
- Texto com barra invertida (`\n` em JS, regex): escreva com a ferramenta de edição, não com heredoc
  do Bash, e confira com `grep` depois.
- Domínio aceito: `@cs.unipe.edu.br`, só em `lib/config.dart` e `firestore.rules` (D2).
- Fora de escopo: iOS, Android, SSO, lojas, migração de dados, reescrever specs antigas.

### Comandos de verificação (V)

| Id | Comando | Onde |
|---|---|---|
| V1 | `flutter analyze` | raiz |
| V2 | `flutter test` | raiz |
| V3 | `npx --no-install firebase emulators:exec --config ../firebase.json --project demo-achei-no-campus --only auth,firestore "npm test"` | `firestore-tests/` |
| V4 | `flutter build web` e depois o mesmo `emulators:exec` com `"npm run test:web"` | raiz, depois `firestore-tests/` |
| V5 | o mesmo `emulators:exec` com `"npm run test:ct"` (cerca de 10 min; filtro: `node --test --test-concurrency=1 --test-name-pattern=CT-XX web-ct.test.js`) | `firestore-tests/` |
| V6 | `gh run list -R dv-dev1/achei-no-campus -L 1` mostra `success` depois do push | — |

Ambiente: Flutter em `C:\Users\Administrator\development\flutter\bin` (pôr no `PATH` do comando),
`JAVA_HOME="C:/Program Files/Microsoft/jdk-21.0.12.101-hotspot"` para os emuladores, PlantUML em
`C:\Users\Administrator\development\plantuml\`. Nesta máquina o `test:ct` é mais lento que no CI: um
caso que confere a tela sem esperar pode falhar aqui e passar lá (foi o CT-18).

### Ponto de parada (fim de cada etapa)

1. V1 a V5 verdes (o que a etapa tocar; V4 e V5 sempre que mudar `lib/` ou `firestore-tests/`).
2. Atualizar a seção **Registro da execução** deste plano (commits, resultados, pendências) e commitar.
3. Mostrar ao Cauê o resumo e pedir o ok do push. Push, depois V6.
4. Só então a etapa seguinte.

## Mapa de arquivos

| Arquivo | Etapas | Papel |
|---|---|---|
| `firestore-tests/web-ct.test.js` | 1, 4 | casos da coluna W no navegador |
| `firestore-tests/driver.mjs` | 2, 4 | abre o app no Chrome/Edge headless; helpers do emulador |
| `firestore-tests/navegador.test.js` | 2 | testes da escolha do navegador (roda no `npm test`) |
| `lib/telas/publicar.dart` | 3 | publicar/editar item |
| `test/publicar_local_antigo_test.dart` | 3 | reproduz a #15 |
| `firestore.rules` | 4 | `aluno()` |
| `lib/config.dart` | 4, 5, 6 | domínio, locais, modo do Firebase |
| `lib/sessao.dart`, `lib/itens.dart`, `lib/main.dart`, `lib/telas/entrar.dart` | 4 | login sem verificação |
| `test/sessao_test.dart`, `test/fluxo_daniel_test.dart` | 4 | testes do login |
| `firestore-tests/rules.test.js`, `firestore-tests/chat.test.js` | 4 | testes de regras |
| `lib/firebase_producao.dart` (novo), `lib/firebase_options.dart` (gerado) | 6 | inicialização com o projeto real |
| `.firebaserc`, `firebase.json` | 6, 7 | alias do projeto real e hosting |
| `docs/testes.md`, `docs/requisitos.md`, `docs/diagramas/*`, `README.md`, `docs/visita-campus.md`, `docs/divisao-de-tarefas.md` | todas | documentação |

---

## Etapa 1 — Fechar o que já está pronto (#3, #4, #6, #8, #14)

### Tarefa 1.1 — CT-18 espera a frase do feed vazio

- **Arquivos:** `firestore-tests/web-ct.test.js` (CT-18, perto da linha 208).
- **O que muda:** a conferência imediata `assert.ok(await app.tem('Nenhum item ainda.'), …)` vira
  `await app.esperarTexto('Nenhum item ainda.')` (helper já existe no `driver.mjs`).
- **Testes:** V5 filtrado em `CT-18`, três vezes seguidas, todas ✔ nesta máquina.
- **Pronto quando:** CT-18 passa aqui três vezes seguidas.
- **Commit:** `test: CT-18 espera o feed carregar antes de conferir a frase`.

### Tarefa 1.2 — `docs/testes.md` e registro de 25/11 corrigidos; fecham as issues prontas

- **Arquivos:** `docs/testes.md`; `specs/2026-10-20-caue-franco.plano.md` (seção "Retomada da #3").
- **O que muda:**
  - `docs/testes.md`: CT-21 e CT-27 a CT-30 passam de ❌ para "W ✅ (automatizado, 25/11/2026,
    `c0a6285`)"; nova seção "Rodada de 26/11/2026" com o resultado do CI de `739c025`
    (`test:ct` 28 de 28, `todo 0`) e a nota de que a #14 está cumprida (o passo já existe no CI).
  - Plano de 20/10: a frase sobre o CT-18 passa a dizer que ele **passa no CI** e só falhava nesta
    máquina por conferir a tela sem esperar; corrigido na tarefa 1.1. A linha do Lúcio sobre o
    CT-18 na tabela de pendências sai (feito). Não apagar o texto antigo: riscar e anotar a data.
- **Testes:** só docs; conferir os links e a tabela no preview do GitHub depois do push.
- **Pronto quando:** nenhum caso já corrigido aparece ❌ em `docs/testes.md`.
- **Commit:** `docs: registra os retestes de #3 e #4 e o test:ct no CI`, corpo terminando em
  `Closes #3, closes #4, closes #6, closes #8, closes #14`.

**⏸ Ponto de parada da etapa 1.** V5 completo, V6. Conferir no GitHub que as cinco issues fecharam.

---

## Etapa 2 — #2: falha clara quando o navegador não abre

### Tarefa 2.1 — `abrirApp` falha logo, citando `CHROME_BIN`

> Revisada em 26/11/2026, antes de começar, com o que a etapa 1 achou. A #2 é sobre o `test:web`,
> e o `web.test.js` tem o próprio `spawn` (não usa o `abrirApp`). Hoje ele já falha rápido, mas com
> o `ENOENT` cru. Além disso, quando o app não carrega, a suíte trava: o `abrirApp` não fecha o que
> abriu, e o CT-17 e o `comDoisApps` abrem a segunda aba fora do `try`. A versão anterior desta
> tarefa só previa o `abrirApp`.

- **Arquivos:** `firestore-tests/driver.mjs` (`abrirApp`, `conectar`, novo `erroDoNavegador`);
  `firestore-tests/web.test.js` (o `spawn` próprio); `firestore-tests/web-ct.test.js`
  (`comDoisApps` e CT-17); `firestore-tests/navegador.test.js` (testes novos); `README.md` (~93).
- **Decisão (fechada):** os testes novos vão em `navegador.test.js`, que roda no `npm test` e no job
  `firestore` do CI, porque o `servir()` não precisa do `build/web` para subir. O runner Ubuntu do
  CI já traz o `google-chrome`.
- **Interfaces:**
  - `export function erroDoNavegador(caminho, erro) → Error`: mensagem
    `Não foi possível abrir o navegador em "<caminho>" (<erro.code>). Defina CHROME_BIN com o caminho do Chrome ou do Edge.`
    e `cause` = `erro`. Usada pelo `abrirApp` e pelo `web.test.js`.
  - `conectar(perfil, falhaDoNavegador)`: `falhaDoNavegador` é `() => Error | undefined`. A espera
    pelo `DevToolsActivePort` para e lança assim que ela devolver um erro.
  - `abrirApp({ raiz, limite } = {}) → Promise<app>`: `raiz` é a pasta servida (padrão: `build/web`)
    e `limite` é o prazo, em ms, do `pronto()` (padrão: 20000, que não muda). As chamadas atuais,
    sem argumento, seguem iguais.
  - Spawn que falha: o `abrirApp` rejeita com `erroDoNavegador(...)` em menos de 5 s.
  - **Limpeza em qualquer falha:** se qualquer passo do `abrirApp` falhar depois do `servir()`,
    inclusive o `pronto()` (hoje fora do `try`), o navegador e o servidor são fechados (e o perfil
    apagado) antes de relançar o erro original.
  - `web.test.js`: o erro do spawn passa por `erroDoNavegador`. Nada mais muda no caso.
  - `comDoisApps` e CT-17: se a segunda aba não abrir, a primeira é fechada antes de propagar o
    erro.
- **Testes** (escrever primeiro e ver falhar):
  - `navegador.test.js`, caso 1: `CHROME_BIN` aponta para um arquivo que não existe. O
    `abrirApp()` rejeita em menos de 5 s, e a mensagem contém `CHROME_BIN`.
  - `navegador.test.js`, caso 2: `abrirApp({ raiz: <pasta temporária vazia>, limite: 2000 })` roda
    num processo Node filho. O filho imprime o erro e **sai sozinho** em menos de 30 s. Hoje ele
    fica pendurado: isso é o que prova a limpeza. Se nenhum navegador for achado, o caso é pulado.
  - V3 (inclui os 3 testes de `caminhoDoNavegador`).
  - V4 duas vezes, `pass 1` nas duas: sem `CHROME_BIN`, e com
    `CHROME_BIN="C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"`.
  - `test:web` com `CHROME_BIN` num arquivo que não existe: falha em segundos, com a mensagem nova.
  - V5 filtrado em `CT-17` e `CT-28` (os dois de duas abas), para conferir que nada quebrou.
- **Pronto quando:** os testes acima passam, e o `README.md` (linha ~93) diz o que fazer quando
  aparece a mensagem.
- **Commits** (um assunto cada, nesta ordem):
  1. `fix: test:web e test:ct avisam logo quando o navegador não abre`, corpo terminando em
     `Closes #2` (`erroDoNavegador`, `conectar`, `web.test.js`, caso 1, README).
  2. `fix: test:ct fecha o navegador quando o app não carrega a tempo` (limpeza do `abrirApp`,
     opções `raiz` e `limite`, `comDoisApps`, CT-17, caso 2).

**⏸ Ponto de parada da etapa 2.**

---

## Etapa 3 — #15: editar item com local fora da lista

### Tarefa 3.1 — Local inicial só se estiver na lista

- **Arquivos:** `lib/telas/publicar.dart:25`; `test/publicar_local_antigo_test.dart`.
- **O que muda:** o valor inicial do campo de local é o local do item **somente** se
  `locais.contains(...)`; senão `null`. O validador existente (`'Escolha o local.'`) cuida do resto.
  Sem migração (D8).
- **Testes:** primeiro rodar o teste com o `todo` removido e ver falhar (exceção do
  `DropdownButtonFormField`); depois da mudança, ele passa e confere também que salvar sem escolher
  mostra `Escolha o local.`. V1, V2. V5 filtrado em `CT-36` (editar continua funcionando).
- **Pronto quando:** o teste passa sem `todo`, e `docs/testes.md` (CT-44) não cita mais a #15
  como bloqueio.
- **Commit:** `fix: editar item com local que saiu da lista abre a tela`, corpo com `Closes #15`.

**⏸ Ponto de parada da etapa 3.** Com a ordem nova, inclui o redeploy do Hosting (ver "Ordem de
execução").

---

## Etapa 4 — Login sem verificação por e-mail (D1, D2)

Contrato que a etapa 6 consome: `aluno()` nas regras = logado **e** e-mail do domínio, sem
`email_verified`; `Sessao.prepararAcesso()` devolve `true` para qualquer usuário logado com
e-mail do domínio.

### Tarefa 4.1 — Regras sem `email_verified`

- **Arquivos:** `firestore.rules:4-9`; `firestore-tests/rules.test.js`; `firestore-tests/chat.test.js`.
- **O que muda:**
  - `aluno()` perde a linha do `email_verified`.
  - Helpers `db()` dos dois testes deixam de injetar `email_verified: true`.
  - O caso "e-mail não verificado" de `rules.test.js` (linha ~42, prova do CT-40) inverte: com o
    domínio certo e `email_verified: false`, ler e escrever **passa**. Os casos de domínio errado
    e parecido continuam negando (CT-39).
- **Testes:** escrever o caso invertido primeiro e ver falhar com a regra atual; mudar a regra; V3.
- **Pronto quando:** V3 verde; nenhum `email_verified` em `firestore.rules` nem nos dois testes.
- **Commit:** `feat: regras aceitam o domínio acadêmico sem exigir e-mail verificado`.

### Tarefa 4.2 — App sem verificação

- **Arquivos:** `lib/config.dart`; `lib/sessao.dart`; `lib/itens.dart`; `lib/main.dart`;
  `lib/telas/entrar.dart`; `test/sessao_test.dart`; `test/fluxo_daniel_test.dart`; mocks com
  `isEmailVerified` nos demais testes (só se o analisador reclamar).
- **Interfaces:**
  - `lib/config.dart`: nova `const dominioAcademico = '@cs.unipe.edu.br';` e
    `const avisoDominio = 'Use seu e-mail @cs.unipe.edu.br.';` (montada a partir de
    `dominioAcademico`); `emailPermitido(String email) → bool` continua igual. As mensagens de
    `main.dart:110`, `sessao.dart:88`, `entrar.dart:71` e `:102` passam a usar `avisoDominio`.
  - `Sessao.prepararAcesso() → Future<bool>`: `false` se não há usuário ou o domínio é inválido;
    senão cria `usuarios/{uid}` se faltar e devolve `true`. Sai o `reload()` e o
    `getIdToken(true)` (existiam só para o claim de verificação).
  - `Sessao.cadastrar(nome, email, senha) → Future<void>`: sem `sendEmailVerification`.
  - `Sessao.salvarPerfil(nome, curso)`: erro só se não logado ou domínio inválido; mensagem
    `Entre com seu e-mail acadêmico.`
  - `Sessao.reenviarVerificacao`: **removido**.
  - `Itens._uidVerificado` → renomear para `_uidDoAluno() → String`, sem `emailVerified`;
    mesma mensagem nova.
  - `main.dart` (`_PortaoState`): `snapshot.data != true` volta para `TelaEntrar` (caso raro:
    usuário sumiu); `TelaVerificar` não existe mais. Comentário da linha 155 atualizado.
  - `lib/telas/entrar.dart`: `TelaVerificar` (linhas 167-235) removida.
- **Testes:**
  - `test/sessao_test.dart`: sai o mock `UsuarioVerificavel` e os casos de verificação
    (linhas ~38-58 e ~104-111); novo caso "cadastro não envia e-mail e `prepararAcesso` cria o
    perfil na primeira entrada".
  - `test/fluxo_daniel_test.dart`: o caso das linhas ~43-66 vira "cadastro leva ao feed".
  - V1, V2.
- **Pronto quando:** V1 e V2 verdes; `grep -rn "emailVerified\|sendEmailVerification\|TelaVerificar\|Já verifiquei" lib test` vazio.
- **Commit:** `feat: cadastro entra direto no app, sem verificação por e-mail`.

### Tarefa 4.3 — Casos do navegador sem verificação

- **Arquivos:** `firestore-tests/web-ct.test.js`; `firestore-tests/driver.mjs:326-341`.
- **Interfaces:**
  - `cadastrar(app, endereco, nome = 'Lúcia Tester') → Promise<string>` (uid): cadastra pela tela
    e espera o rótulo `Publicar`.
  - `entrarVerificado` e `verificarEmail` **removidos**; todos os casos que usavam
    `entrarVerificado` passam a usar `cadastrar`.
- **Casos que mudam de sentido (mantêm o número):**
  - CT-01 "cadastro com e-mail do domínio certo": confere o feed (`Publicar`) e o e-mail logado.
  - CT-04: caso removido do arquivo (em `docs/testes.md` vira ➖ "removido por D1, 26/11/2026").
  - CT-05 "entrar com conta existente": cadastrar, sair, entrar com a mesma senha, feed.
  - CT-07 "senha errada": cadastrar, sair, entrar com senha errada, mensagem de erro.
- **Testes:** V4, V5 completo.
- **Pronto quando:** V5 com `fail 0`, `todo 0` e `tests 27` (CT-04 saiu); `grep -n "verificar" firestore-tests/*.js firestore-tests/*.mjs` vazio.
- **Commit:** `test: casos do navegador cadastram e caem direto no feed`.

### Tarefa 4.4 — Docs do login novo

- **Arquivos:** `docs/requisitos.md` (linhas 9, 28, 47); `docs/testes.md` (linhas 13, 40-42,
  CT-01, CT-04, CT-05, CT-40); `docs/diagramas/arquitetura.puml` (20, 30) e `casos-de-uso.puml`
  (13, 20), com os `.svg` regerados; `README.md` (3, 40, 91, 99).
- **O que muda:**
  - RF-02 vira "Entrada só com e-mail `@cs.unipe.edu.br`, sem verificação por e-mail (D1)".
  - RNF-01 vira "Só o domínio acadêmico", com a **limitação conhecida** (conta com endereço
    inventado do domínio) e o **próximo passo** (SSO institucional: Google Workspace ou Microsoft
    no plano grátis; SAML/OIDC no Identity Platform, pago).
  - CT-40 renomeado "Domínio certo basta, sem verificação" ✅ (`rules.test.js`).
  - README: a mesma limitação numa seção curta "Limitações conhecidas".
- **Testes:** `java -jar C:\Users\Administrator\development\plantuml\plantuml.jar -tsvg docs/diagramas/*.puml`
  e conferir que o diff dos `.svg` só troca os textos; `grep -rn "verific" docs README.md` só
  sobra onde fala da decisão D1.
- **Pronto quando:** nenhum doc vivo descreve a verificação como parte do app.
- **Commit:** `docs: login sem verificação, limitação conhecida e SSO como próximo passo`.

**⏸ Ponto de parada da etapa 4.** V1 a V5 completos, V6.

---

## Etapa 5 — #10: lista de locais

**Depende de:** etapa 3 e da lista que o Cauê vai passar. **Pare e peça a lista antes de começar.**

### Tarefa 5.1 — Aplicar a lista do Cauê

- **Arquivos:** `lib/config.dart` (`locais`); `docs/testes.md` (CT-44); `docs/visita-campus.md`;
  testes ou casos que usam nomes de local que mudarem (`grep -rn "'Biblioteca'\|Reitoria\|Ginásio\|Passarela\|Auditório\|Piscina\|Estacionamento\|Centro de Informação" test firestore-tests`).
- **O que muda:** `locais` = a lista dele, na ordem que ele passar, com `Outro` no fim. CT-44 ✅
  "lista passada pelo Cauê em DD/MM/2026" (D6). `docs/visita-campus.md` ganha no topo uma nota de
  que a conferência veio dessa lista, não de uma visita.
- **Decisão em aberto:** se algum nome usado nos testes sumir, trocar no teste pelo nome novo mais
  próximo (não recriar o antigo).
- **Testes:** V1, V2, V4, V5.
- **Pronto quando:** testes verdes com a lista nova.
- **Commit:** `feat: lista de locais conferida pelo Cauê`, corpo com `Closes #10`.

**⏸ Ponto de parada da etapa 5.** Com a ordem nova, inclui o redeploy do Hosting (ver "Ordem de
execução").

---

## Etapa 6 — #5: Firebase real (Spark), só web

**Depende de:** etapa 4. **Ações do Cauê antes da tarefa 6.2** (pare e peça):
1. Criar o projeto no console do Firebase com a conta Google pessoal dele (D4), plano Spark.
2. Ligar Authentication → E-mail/senha.
3. Criar o Cloud Firestore em modo produção.
4. No terminal desta sessão: `! cd firestore-tests && npx --no-install firebase login`.

**Decisões em aberto, a perguntar no início da etapa:** o ID do projeto (sugestão:
`achei-no-campus-unipe`) e a região do Firestore (sugestão: `southamerica-east1`, São Paulo; não
dá para trocar depois).

### Tarefa 6.1 — Modo produção no código

- **Arquivos:** `lib/config.dart`; `lib/firebase_producao.dart` (novo); `lib/main.dart:14-35`.
- **Interfaces:**
  - `lib/config.dart`: `const modoProducao = String.fromEnvironment('FIREBASE') == 'producao';`
  - `lib/firebase_producao.dart`: `Future<void> inicializarFirebaseProducao()`: chama
    `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` e aplica
    `Settings(persistenceEnabled: false)` no Firestore, igual ao modo local, para os dois
    modos se comportarem igual. **Não** chama `configurarAuthLocal` (o `web/firebase_local.js`
    não muda: só define uma função que ninguém chama em produção).
  - `main()`: `modoProducao ? inicializarFirebaseProducao() : inicializarFirebaseLocal()`. A
    mensagem de erro de inicialização muda por modo: local continua pedindo os emuladores;
    produção diz `Não foi possível conectar. Confira sua internet e tente de novo.`
- **Observação:** a 6.1 compila só depois de existir `lib/firebase_options.dart` (6.2). Faça as
  duas em sequência e commite separado, a 6.2 primeiro se preferir ordem compilável a cada commit.
- **Testes:** V1, V2; `flutter build web` **sem** o define e V4/V5 (nada muda nos testes).
- **Pronto quando:** testes verdes e o build padrão continua batendo só nos emuladores (o próprio
  V4 falha se houver acesso ao Firebase real).
- **Commit:** `feat: modo produção escolhido no build com --dart-define=FIREBASE=producao`.

### Tarefa 6.2 — Projeto real ligado (web)

- **Arquivos:** `lib/firebase_options.dart` (gerado); `.firebaserc`; `README.md` (Executar).
- **O que muda:**
  - `dart pub global activate flutterfire_cli` (se faltar) e
    `flutterfire configure --project=<id> --platforms=web --out=lib/firebase_options.dart`.
    O arquivo vai para o repo (a proteção são as regras).
  - `.firebaserc`: `"default": "demo-achei-no-campus"` continua; novo alias `"producao": "<id>"`.
  - Publicar regras e índices: de `firestore-tests/`,
    `npx --no-install firebase deploy --config ../firebase.json --only firestore:rules,firestore:indexes --project producao`.
  - README: seção com os dois modos e esses comandos.
- **Testes:**
  - `flutter run -d chrome --dart-define=FIREBASE=producao` (ou build + servidor local):
    cadastrar `teste1.<data>@cs.unipe.edu.br`, cair no feed, publicar um item sem foto, ver o
    item no console do Firestore.
  - Cadastro com `@gmail.com` recusado na tela.
  - No DevTools (aba Rede), nenhuma requisição para `127.0.0.1:9099` ou `:8080`.
  - Sem o define, `flutter run -d chrome` continua nos emuladores.
- **Pronto quando:** os quatro itens acima conferidos e anotados no registro.
- **Commit:** `feat: projeto Firebase real (Spark) configurado para a web`, corpo com `Closes #5`.

**⏸ Ponto de parada da etapa 6.** V1 a V5, V6.

---

## Etapa 7 — #7: versão web no Firebase Hosting

### Tarefa 7.1 — Hosting e deploy

- **Arquivos:** `firebase.json`; `README.md`.
- **O que muda:**
  - `firebase.json` ganha `"hosting": {"public": "build/web", "ignore": ["firebase.json", "**/.*"], "rewrites": [{"source": "**", "destination": "/index.html"}]}`.
    Conferir que o caminho `build/web` resolve a partir da raiz (o `--config ../firebase.json` é
    lido de `firestore-tests/`).
  - Build: `flutter build web --dart-define=FIREBASE=producao --dart-define=CLOUDINARY_CLOUD_NAME=tbeq7obd --dart-define=CLOUDINARY_UPLOAD_PRESET=achei_unsigned`.
  - Deploy: de `firestore-tests/`, `npx --no-install firebase deploy --config ../firebase.json --only hosting --project producao`.
  - README: link da versão no ar no topo, "Status", e "como refazer o deploy" (os dois comandos).
- **Testes (na URL pública `https://<id>.web.app`, aba anônima, duas contas de teste):**
  1. cadastrar e cair no feed;
  2. publicar com foto (Cloudinary) e ver a foto no detalhe;
  3. recarregar a página e continuar logado;
  4. a segunda conta abre o item, conversa; a primeira vê o número de não lidas e a mensagem chegar
     sem recarregar;
  5. marcar como devolvido e o item sumir do feed da outra conta.
- **Decisão em aberto, a perguntar ao Cauê ao fim da conferência:** apagar os dados de teste ou
  deixar alguns itens de exemplo para o professor. Se apagar: itens e conversas pelo console do
  Firestore, contas pelo console do Authentication, fotos pelo Media Library do Cloudinary.
- **Pronto quando:** os cinco itens conferidos, anotados no registro, e o README com o link.
- **Commit:** `feat: versão web publicada no Firebase Hosting`, corpo com `Closes #7`.

**⏸ Ponto de parada da etapa 7.** V6.

---

## Etapa 8 — #9: requisitos e diagramas contra o app entregue

### Tarefa 8.1 — Revisão e correções

- **Arquivos:** `docs/requisitos.md`; `docs/diagramas/*.puml` e `.svg`.
- **O que fazer:** para cada RF e RNF, abrir o caso de teste citado e confirmar que ele prova o
  requisito; conferir `dados.puml` com os campos de `lib/modelos/item.dart` e
  `lib/modelos/conversa.dart`; as permissões dos diagramas com `firestore.rules`;
  `sequencia-chat.puml` com `lib/conversas.dart` (`enviar`, `marcarComoLida`, a espera pelo
  servidor da #3). Corrigir texto direto; regerar os `.svg`. As diferenças achadas e corrigidas
  vão numa lista no registro (D5: nada de comentário na issue).
- **Testes:** PlantUML regera sem erro; links de `docs/requisitos.md` para os casos abrem.
- **Pronto quando:** cada RF aponta um caso que o prova e os diagramas batem com o código.
- **Commit:** `docs: requisitos e diagramas conferidos com o app entregue`, corpo com `Closes #9`.

**⏸ Ponto de parada da etapa 8.**

---

## Etapa 9 — #13: conferência final

### Tarefa 9.1 — Roteiro da pessoa de fora (CT-42)

- **Arquivos:** `docs/testes.md` (CT-42).
- **O que muda:** o CT-42 ganha um roteiro curto, para ler à pessoa sem ajudar:
  1. abrir o link;
  2. criar uma conta;
  3. publicar algo que perdeu, com foto;
  4. achar o item de outra pessoa pelo filtro ou pela busca;
  5. mandar uma mensagem;
  6. marcar o próprio item como devolvido.

  Ao lado, uma tabela para anotar, por passo, se a pessoa conseguiu, onde travou e quanto tempo
  levou.
- **Ação do Cauê:** aplicar o roteiro com a pessoa (D7) e passar as anotações.
- **Pronto quando:** a tabela está preenchida com data. Cada trava vira correção pequena, se for
  texto ou rótulo, ou fica como "problema conhecido", se for maior. A decisão fica com o Cauê.
- **Commit:** `docs: roteiro e resultado do CT-42 (pessoa de fora usa o app)`.

### Tarefa 9.2 — Rodada final e fechamento

- **Arquivos:** `docs/testes.md`; `README.md`; `docs/divisao-de-tarefas.md`.
- **O que fazer:**
  - **Coluna W:** rodar os casos manuais na URL pública. A suíte automática já cobre os
    emuladores.
  - **CT-43:** conferir textos, acentos, cores e tema em todas as telas.
  - **CT-45:** rodar tudo na versão final.
  - **Colunas A e I:** viram ➖ "fora de escopo (D3, 26/11/2026)".
  - Nova seção "Rodada final (DD/MM/2026)", sem nenhum ⏳ que não tenha motivo.
  - **README:** "Status" com o estado entregue e as limitações conhecidas.
  - **`docs/divisao-de-tarefas.md`:**
    - marcar os checkboxes feitos;
    - anotar o que saiu de escopo;
    - anotar que o Cauê assumiu o resto na fase de 26/11 (D9).
- **Testes:** V1 a V5 completos; V6.
- **Pronto quando:** o "pronto quando" da #13 está cumprido, com CI `success`.
- **Commit:** `docs: rodada final de testes e status da entrega`, com o corpo terminando em `Closes #13, closes #11, closes #12`.

**⏸ Ponto de parada final.** Push com o ok do Cauê; V6; atualizar a nota da vault.

---

## Checklist

- [x] 1.1 CT-18 espera o feed
- [x] 1.2 `docs/testes.md` e registro de 25/11; fecham #3, #4, #6, #8, #14
- [x] ⏸ Etapa 1: push e registro
- [x] 2.1 Falha clara do navegador; fecha #2
- [x] ⏸ Etapa 2: push e registro
- [ ] 3.1 Local inicial só se estiver na lista; fecha #15
- [ ] ⏸ Etapa 3: push e registro
- [ ] 4.1 Regras sem `email_verified`
- [ ] 4.2 App sem verificação
- [ ] 4.3 Casos do navegador sem verificação
- [ ] 4.4 Docs do login novo
- [ ] ⏸ Etapa 4: push e registro
- [ ] 5.1 Lista de locais do Cauê; fecha #10
- [ ] ⏸ Etapa 5: push e registro
- [ ] 6.1 Modo produção no código
- [ ] 6.2 Projeto real ligado; fecha #5
- [ ] ⏸ Etapa 6: push e registro
- [ ] 7.1 Hosting e deploy; fecha #7
- [ ] ⏸ Etapa 7: push e registro
- [ ] 8.1 Requisitos e diagramas conferidos; fecha #9
- [ ] ⏸ Etapa 8: push e registro
- [ ] 9.1 Roteiro e resultado do CT-42
- [ ] 9.2 Rodada final; fecham #13, #11, #12
- [ ] ⏸ Etapa 9: push, registro e vault

## Registro da execução

(Preenchido a cada ponto de parada: commits, resultados de V1 a V6, decisões tomadas no caminho e
pendências.)

### Etapa 1 — 26/11/2026

**Commits:** `93878db` (1.1, CT-18 espera a frase do feed vazio) e `8d2f48d` (1.2, `docs/testes.md`
com a rodada de 26/11 e a correção do registro do CT-18 no plano de 20/10, fechando #3, #4, #6, #8
e #14). Sobe junto o `693e7b7`, em que a spec e o plano passam a apontar para o clone no workspace.

**Verificação nesta máquina** (clone novo, `flutter build web` refeito):

| Id | Resultado |
|---|---|
| V3 | `tests 30 · pass 30 · fail 0` |
| V4 | `test:web`: `tests 1 · pass 1 · fail 0` |
| V5 filtrado em CT-18 | ✔ três vezes seguidas (19,7 s, 19,1 s e 22,3 s) |
| V5 completo | 23 de 28 ✔. Os 5 ✖ (CT-01, CT-03, CT-04, CT-17 e CT-23) têm o mesmo erro: `Tempo esgotado esperando o Firebase do app carregar.` (`driver.mjs:156`), ou seja, o app não carregou em 20 s. O CT-18 passou na suíte. |
| V5 nos 5 casos, de novo | CT-01, CT-03, CT-04 e CT-23 ✔. CT-17 ✖ com o mesmo erro; é o único dos cinco que abre duas abas ao mesmo tempo. |

Nenhum dos cinco casos foi tocado nesta etapa, e os 28 passaram no CI do `739c025`. A falha é a
lentidão desta máquina para carregar o app, não um defeito. O Cauê decidiu: push, e o CI decide (V6).

**Achado: a suíte trava quando o app não carrega a tempo.** O `abrirApp` lança o erro do `pronto()`
sem fechar o Chrome nem o servidor, porque essa chamada fica fora do `try`. O processo de teste
então nunca termina e o resumo não sai. Nas duas rodadas foi preciso encerrar à mão os Chromes de
teste e o processo filho. Por decisão do Cauê, a correção entra na tarefa 2.1, já atualizada acima.

**V6:** run `45879909965` (`e64c7a4`) `success` em 8 min 40 s. `npm test` deu 30 de 30, o
`test:web` 1 de 1 e o `test:ct` 28 de 28, com `todo 0`. No CI, os 5 casos que falharam aqui
passaram. As issues #3, #4, #6, #8 e #14 fecharam pelo `8d2f48d`.

### Etapa 2 — 26/11/2026

**Antes de começar:** a tarefa 2.1 foi revista (`44c6654`) para cobrir o `test:web`, que tem spawn
próprio, e as duas abas do `test:ct`. A decisão em aberto foi fechada: os testes ficam em
`navegador.test.js`.

**Commits:** `18fbb02` (mensagem com `CHROME_BIN` no `abrirApp` e no `test:web`; `Closes #2`),
`dac9dc7` (o `abrirApp` fecha o navegador e o servidor em qualquer falha; opções `raiz` e
`limite`; `comDoisApps` e CT-17 fecham a primeira aba) e `7055176`, este um achado da revisão: no
`test:web`, o `caminhoDoNavegador()` rodava fora do `try`, e numa máquina sem navegador o servidor
ficava aberto e o teste travava. Por decisão do Cauê, entrou nesta etapa.

**Testes novos, vistos falhando antes da correção:**
- `CHROME_BIN` inexistente: antes, o `abrirApp` estourava o prazo de 20 s do teste. Agora rejeita em
  menos de 5 s, citando `CHROME_BIN`.
- App que não carrega (pasta vazia, `limite` de 2 s, num processo filho): antes, o filho não saía em
  30 s. Agora sai em cerca de 3 s.
- `test:web` numa máquina sem Chrome nem Edge, simulada por um preload que troca `PROGRAMFILES`,
  `PROGRAMFILES(X86)` e `LOCALAPPDATA` (pelo ambiente não dá, porque o Windows reinjeta
  `PROGRAMFILES`): o arquivo antigo travou até o `timeout` matar, aos 30 s; o novo falha e sai em
  1 s com `Nenhum Chrome ou Edge encontrado em: … Defina CHROME_BIN…`.

**Verificação nesta máquina:**

| Id | Resultado |
|---|---|
| V3 | `tests 32 · pass 32 · fail 0` (os 30 de antes e os 2 novos) |
| V4 sem `CHROME_BIN` e com `CHROME_BIN` no Edge | `pass 1` nos dois (depois do `7055176`) |
| `test:web` com `CHROME_BIN` inexistente | falha em 144 ms: `Não foi possível abrir o navegador em "C:/nao-existe/chrome.exe" (ENOENT). Defina CHROME_BIN…` |
| V5 completo | `tests 28 · pass 28 · fail 0 · todo 0`, sem travar |

**Execução:** o subagente em Sonnet fez os commits `18fbb02` e `dac9dc7`. A revisão em Opus aprovou os
dois e achou o caso do `7055176`.

**V6:** run `45884375548` (`15ff650`) `success` em 8 min 51 s. `npm test` deu 32 de 32, com
`skipped 0`: os dois casos novos rodaram no job `firestore`. O `test:web` deu 1 de 1 e o `test:ct`
28 de 28. A #2 fechou pelo `18fbb02`.
