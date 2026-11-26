# Spec — Achei no Campus: tudo o que resta até a entrega

Repo `dv-dev1/achei-no-campus` · clone `C:\Users\Administrator\Downloads\Vault_01\workspace-achei-no-campus\repo` (desde 26/11) ·
base `main` = `739c025` (CI verde: `test:ct` 28 de 28, `todo 0`).

## Contexto

O Daniel e o Lúcio estão em outras frentes, e o Cauê assume tudo o que falta no projeto (pedido
de 26/11/2026). Ainda não há data de entrega, então a ordem segue as dependências.

Como fica pelo fluxo do CLAUDE.md:
1. Esta spec, aprovada, vai para `specs/2026-11-26-entrega-final.md` no repo. O commit é local e
   o push só sai com o ok do Cauê.
2. Em seguida vem o plano completo, em `specs/2026-11-26-entrega-final.plano.md`. Ele traz etapas
   e tarefas, com arquivos, interfaces, testes, "pronto quando", checklist e ponto de parada por
   etapa, sem código pronto. Ele é revisado pelo Cauê.
3. Só então a implementação, tarefa a tarefa.

## Decisões fechadas com o Cauê (26/11)

| # | Decisão |
|---|---|
| D1 | **Sem verificação por e-mail.** Vale qualquer e-mail `@cs.unipe.edu.br`, checado só pelo formato. Risco aceito e escrito nos docs como limitação conhecida: dá para criar conta com um endereço inventado do domínio. **Próximo passo, se a faculdade contratar:** login institucional (SSO). Google Workspace ou Microsoft funcionam no plano grátis do Firebase; SAML/OIDC exige o Identity Platform, que é pago. O SSO fica só nos docs. |
| D2 | Domínio continua `@cs.unipe.edu.br`, em dois pontos só: `lib/config.dart` (regex `emailPermitido` + constante do texto) e `firestore.rules` (`aluno()`). As mensagens das telas passam a usar a constante. |
| D3 | **iOS (#12) e Android (#11) fora.** A entrega é a versão web. As duas issues fecham como fora de escopo, e as colunas A e I de `docs/testes.md` viram ➖ com o motivo. |
| D4 | **Firebase real na conta Google pessoal do Cauê**, plano Spark. Ele faz o login pelo terminal (`! firebase login`). |
| D5 | **Issues fecham pelo commit** (`fecha #N`). Nada de comentário em issue: o registro vai no plano do repo. |
| D6 | **Locais (#10):** o Cauê passa a lista certa. O CT-44 registra a fonte ("lista passada pelo Cauê em DD/MM"), não uma visita. |
| D7 | **Pessoa de fora usa o app (#13, CT-42):** entra; o Cauê arruma a pessoa, e o plano traz um roteiro curto e onde anotar. |
| D8 | **Itens com local fora da lista (#15):** sem migração. A produção começa vazia; o campo abre vazio, e o validador pede um local válido. |
| D9 | "O Cauê faz tudo" vale para esta fase. Os docs do repo registram a troca de responsável em cada issue. |
| D10 | **(26/11, depois da etapa 2) A versão web vai para o GitHub Pages do próprio repo, e não para o Firebase Hosting.** O link fica `https://dv-dev1.github.io/achei-no-campus/`, e o CI publica a cada push na `main` com os testes verdes. O Firebase real (D4, etapa 6) continua para o login e o banco. O Cauê não é admin do repo: o Daniel liga o Pages (Settings → Pages → Source: GitHub Actions), e o Cauê autoriza o domínio `dv-dev1.github.io` no Firebase Authentication. A seção 7 abaixo fica como histórico; o "como" está na etapa 7 do plano. |

## Escopo, por etapa (ordem de execução)

### 1. Fechar o que já está pronto
- Fecham **#3, #4, #6, #8 e #14**. A #14 está resolvida: o `test:ct` já roda no CI (`.github/workflows/ci.yml`, com limite de 20 min) e passou 28 de 28 em `739c025`.
- `docs/testes.md`: o CT-21 e o CT-27 a CT-30 ainda aparecem ❌; passam a ✅, com a data e o commit.
- O registro de 25/11 no plano de 20/10 está errado sobre o CT-18: ele **passa no CI** e só falha na máquina do Cauê, que é mais lenta. Corrigir o texto e deixar o caso robusto, trocando `tem('Nenhum item ainda.')` por `esperarTexto(...)` em `firestore-tests/web-ct.test.js`.

### 2. #2: navegador do `test:web` no Windows
A correção principal já está no repo: `a999394`. `caminhoDoNavegador` em `firestore-tests/driver.mjs:55-75` procura Chrome e Edge e mostra uma mensagem que cita `CHROME_BIN`. A ponta que falta: com um `CHROME_BIN` inválido, `driver.mjs` espera 20 s pelo `DevToolsActivePort` antes de soltar o `ENOENT` cru, enquanto `web.test.js` falha na hora. Igualar os dois: falhar logo, com uma mensagem que cite `CHROME_BIN`. O reteste fecha a #2:
- `npm test` (inclui `navegador.test.js`);
- `test:web` com `CHROME_BIN` apontando para o Edge;
- `CHROME_BIN` inválido dando a mensagem nova.

### 3. #15: editar item com local fora da lista
`lib/telas/publicar.dart` só aceita o local salvo como valor inicial se ele estiver em `locais`. Senão, o campo abre vazio e o validador existente pede a escolha. `test/publicar_local_antigo_test.dart` sai do `todo`.

### 4. Tirar a verificação por e-mail (D1, D2)
- **Regras:** `aluno()` em `firestore.rules:4-9` fica sem `email_verified`.
- **`lib/sessao.dart`:**
  - `prepararAcesso` mantém o domínio e a criação do perfil, mas sai a exigência de verificação;
  - `cadastrar` não envia e-mail;
  - `salvarPerfil` deixa de exigir verificação;
  - `reenviarVerificacao` sai.
- **`lib/itens.dart`:** `_uidVerificado` vira só "logado com domínio".
- **`lib/main.dart`:** o portão vai direto ao feed. `TelaVerificar`, em `lib/telas/entrar.dart:167-235`, sai.
- **Testes:**
  - `test/sessao_test.dart` e `test/fluxo_daniel_test.dart`;
  - `firestore-tests/rules.test.js` e `chat.test.js`: o claim `email_verified` sai dos helpers;
  - `firestore-tests/web-ct.test.js`: `cadastrar`/`entrarVerificado` viram "cadastrar e cair no feed", e sai o `verificarEmail` de `driver.mjs`.
  - Os casos que mudam de sentido mantêm o número, com a mudança registrada:
    - CT-01: o cadastro leva ao feed;
    - CT-04: vira ➖ "removido por D1";
    - CT-05: entrar com uma conta existente;
    - CT-40: um token sem o domínio não escreve, ou ➖. Quem decide é o plano.
- **Docs:**
  - `docs/requisitos.md`: o RF-02 sai ou é reescrito, e o RNF-01 vira "só o domínio", com a limitação e o SSO;
  - `docs/testes.md`;
  - os diagramas `arquitetura.puml` e `casos-de-uso.puml`, com o `.svg` regerado pelo PlantUML de `C:\Users\Administrator\development\plantuml\`;
  - `README.md`.
- As specs antigas ficam como histórico e não são reescritas.

### 5. #10: lista de locais
Aplicar em `lib/config.dart` a lista que o Cauê passar, com `Outro` no fim. Marcar o CT-44 ✅ com data e fonte, e atualizar `docs/visita-campus.md`. **Depende da etapa 3** e da lista dele.

### 6. #5: Firebase real (Spark), só web
- **Ações do Cauê:** criar o projeto na conta dele, ligar Authentication com e-mail/senha, criar o Firestore e rodar `! firebase login`.
- `flutterfire configure` só para web, gerando `lib/firebase_options.dart`. O arquivo vai para o repo público, porque a proteção são as regras.
- **Escolha do modo no build:**
  - `--dart-define=FIREBASE=producao` faz o `main()` inicializar com `DefaultFirebaseOptions` e não chamar `configurarAuthLocal`;
  - sem o define, nada muda: `inicializarFirebaseLocal` continua igual, e testes e CI seguem sem credenciais.
  - O `web/firebase_local.js` não precisa mudar: ele só define uma função, e em produção ninguém a chama.
- Alias do projeto real no `.firebaserc`, com `demo-achei-no-campus` continuando como padrão.
- Regras e índices publicados com `firebase deploy --only firestore:rules,firestore:indexes`.
- **Depende da etapa 4**, porque as regras publicadas já são as sem verificação.

### 7. #7: deploy no Firebase Hosting

> Trocado pelo GitHub Pages em 26/11 (D10). O texto abaixo é o desenho original.

- Seção `hosting` no `firebase.json`, com `build/web` e rewrite para `/index.html`.
- Build com `--dart-define=FIREBASE=producao` e o Cloudinary (`tbeq7obd` / `achei_unsigned`), depois `firebase deploy --only hosting`.
- README com o link no topo, "Status", os dois modos e como refazer o deploy.
- Conferência na URL pública numa aba anônima, com duas contas de teste (sem verificação, nenhuma precisa de caixa de e-mail):
  - cadastrar;
  - publicar com foto;
  - recarregar e manter a sessão;
  - conversar entre as duas contas e ver as não lidas.
- **Decisão em aberto, a perguntar ao Cauê nesta etapa:** o que fazer com os dados de teste em produção (apagar, ou deixar alguns itens de exemplo para o professor).

### 8. #9: requisitos e diagramas contra o app entregue
Fica depois das etapas 4 a 7, porque todas mudam o que os docs descrevem. Cada RF precisa apontar o caso que o prova, e os diagramas precisam bater com:
- `lib/modelos/item.dart` e `lib/modelos/conversa.dart`;
- `firestore.rules`;
- `lib/conversas.dart`.

### 9. #13: conferência final
- Rodada final em `docs/testes.md`:
  - coluna W na URL pública;
  - CT-43: textos, acentos e tema;
  - CT-42: a pessoa de fora (D7);
  - CT-45: rodar tudo na versão final.
  - Nenhum ⏳ sem motivo.
- README "Status" e os checkboxes de `docs/divisao-de-tarefas.md`.
- CI com `success`.
- Fecham a #13 e, por D3, a #11 e a #12.

## Fora de escopo
iOS e Android (D3), SSO (D1), App Store e Play Store, migração de dados (D8) e reescrever specs antigas.

## Riscos
- **Conta falsa no domínio:** aceito em D1 e documentado.
- **Diferença entre emulador e produção:** é o que a conferência da etapa 7 cobre. A suíte automática roda só nos emuladores, porque o driver recusa Firebase real de propósito.
- **Dependências externas:**
  - a lista de locais (etapa 5) e a criação do projeto Firebase (etapa 6) dependem do Cauê;
  - o CT-42 depende da pessoa de fora.
  - Cada uma é um ponto de parada no plano.

## Verificação geral
- **Em toda etapa:**
  - `flutter analyze`, `flutter test`;
  - `npm test` (regras e chat);
  - `npm run test:web` e `npm run test:ct` nos emuladores, depois de `flutter build web`;
  - o CI do push com `success`.
- **Nas etapas 6 e 7:** também a URL pública.
- **Commits:** em pt-BR, um assunto por commit, autor `cauedev30 <cauefranco01@gmail.com>`, sem Co-Authored-By. `git fetch` antes de todo push, e o push só com o ok do Cauê.

## Depois de aprovar (fora do repo)
- Atualizar a memória `achei-no-campus-so-minhas-issues`: nesta fase, todas as issues são dele.
- Atualizar a nota da vault `Projects/Active/Achei no Campus.md`.
