# Achei no Campus

Achados e perdidos da UNIPÊ: cadastro acadêmico verificado, perfil, publicação, edição e exclusão dos próprios itens, feed com filtros e busca, detalhe, marcar como devolvido, "Meus itens" e chat por item com contador de não lidas.
App Flutter com Firebase local. Projeto acadêmico, não oficial da UNIPÊ. Cada parte tem um guia em [`docs/`](docs/).

**Status (07/10):** as entregas de código de Daniel e Cauê estão todas na `main` e conferidas juntas; o projeto entra na **fase de testes** com Lúcio. Web executável; Android/iOS têm scaffold e ainda precisam do aceite de Lúcio. Foto é opcional; upload real depende de configurar o Cloudinary. Escopo desta entrega em [`specs/2026-10-06-daniel-vieira.md`](specs/2026-10-06-daniel-vieira.md), decisões gerais em [`specs/2026-10-02-achei-no-campus.md`](specs/2026-10-02-achei-no-campus.md).

## Executar localmente

Requisitos: Flutter stable 3.47.6, Node.js 22, JDK 21 disponível em `java -version` e Chrome. O Firebase CLI é dependência local; não exige `firebase login`, conta ou projeto real. Instalação do Flutter: [documentação oficial](https://docs.flutter.dev/install/manual).

No macOS, o JDK do Homebrew pode precisar destas variáveis no terminal dos emuladores:

```bash
export JAVA_HOME="$(brew --prefix openjdk@21)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
```

No Windows, aponte `JAVA_HOME` para o JDK 21 instalado e inclua sua pasta `bin` no `PATH`.

Em um terminal, a partir da raiz:

```bash
cd firestore-tests
npm ci
npx --no-install firebase emulators:start --config ../firebase.json --project demo-achei-no-campus --only auth,firestore
```

Em outro terminal, na raiz do projeto:

```bash
flutter pub get
flutter run -d chrome
```

Auth usa `127.0.0.1:9099`, Firestore `127.0.0.1:8080` e a interface dos emuladores fica em `http://127.0.0.1:4000`. Dados são temporários e ficam no emulador. O app conecta sempre ao projeto `demo-achei-no-campus`, nunca a serviços reais.

Cadastre um e-mail de teste com `@cs.unipe.edu.br`. O link de verificação aparece no terminal do emulador, sem enviar e-mail real. Abra o link e volte ao app para tocar em **Já verifiquei**. **Reenviar verificação** gera outro link. O perfil só é criado após confirmação, recarga do usuário e renovação do token.

O emulador Android usa `10.0.2.2`; web e simulador iOS usam `127.0.0.1`. Para outro host, use `--dart-define=EMULATOR_HOST=<host>` e ajuste a escuta dos emuladores. Android precisa de Android SDK; iOS precisa de Xcode. Os builds móveis ainda não foram verificados nesta entrega.

## Fotos

Sem Cloudinary configurado, publique sem foto. Selecionar uma foto e tentar enviar mostra o motivo e permite removê-la. Ao editar, uma foto existente fica preservada até ser removida ou substituída. O formulário aceita até 2 MB e avisa para cobrir CPF/RG na categoria Documentos.

`enviarFoto(XFile)` usa bytes e multipart, compatíveis com web. A configuração futura usa `CLOUDINARY_CLOUD_NAME` e `CLOUDINARY_UPLOAD_PRESET` via `--dart-define`. O preset unsigned deve restringir formatos, tamanho e pasta. Esta entrega testa HTTP simulado; não faz upload real.

## Verificação

```bash
flutter analyze
flutter test
flutter build web
cd firestore-tests
npm ci
npx --no-install firebase emulators:exec --config ../firebase.json --project demo-achei-no-campus --only auth,firestore "npm test"
npx --no-install firebase emulators:exec --config ../firebase.json --project demo-achei-no-campus --only auth,firestore "npm run test:web"
```

Pare a execução interativa dos emuladores antes de usar `emulators:exec`, para liberar as portas. Saída obtida nesta entrega:

```text
No issues found!
All tests passed!
✓ Built build/web
ℹ tests 26
ℹ pass 26
ℹ fail 0
```

O aceite visual no Chrome confirmou cadastro, reenvio, verificação pelo emulador, edição do perfil, publicação sem foto, edição, cancelamento da exclusão, exclusão e saída. Segundo usuário sem ações de dono; tentativas de editar e apagar o item alheio pela API retornaram HTTP 403. Foram inspecionados desktop e viewport 390×844.

`test:web` abre um Chrome headless com perfil temporário, cadastra um usuário fictício, recarrega a página e exige a mesma sessão no emulador. Falha se Auth, Firestore ou renovação de token tentarem acessar Firebase real. Procura Chrome no caminho padrão; para outra instalação, defina `CHROME_BIN`.

O workflow em `.github/workflows/ci.yml` executa análise, testes Flutter, build web, regras e recarga no Chrome no projeto demo sem credenciais reais. A execução remota fica pendente de publicar a branch.

`web/firebase_local.js` conecta Auth antes de o FlutterFire restaurar a sessão. Isso contorna a ordem de inicialização de [FlutterFire #11534](https://github.com/firebase/flutterfire/issues/11534), que impede conectar o emulador após a primeira requisição. O script usa as mesmas opções fornecidas por Dart e Firebase JS SDK 12.19.0, versão usada pelo FlutterFire do `pubspec.lock`. Ao atualizar FlutterFire, mantenha as versões alinhadas e execute `test:web`.

As regras exigem domínio exato e e-mail verificado em todas as coleções; só o dono altera/apaga seus itens e edita seu perfil. Autoria e data de criação são imutáveis. Conversas preservam item e participantes; somente participantes leem/enviam mensagens, com autoria própria. O índice composto do feed está versionado em `firestore.indexes.json`.

## Como contribuir

As entregas são feitas com commits e push direto para a `main`, sem exigir PR ou aprovação de merge.

Para enviar alterações, é necessário ser colaborador do repositório: informe seu usuário do GitHub ao responsável e aceite o convite. O repositório público permite leitura por qualquer pessoa, mas não concede acesso de escrita a visitantes.

Trabalhe na `main` e atualize sua cópia com `git pull --ff-only origin main` antes de editar. Depois de revisar e commitar suas alterações, envie com `git push origin main`.

## Licença

[MIT](LICENSE)
