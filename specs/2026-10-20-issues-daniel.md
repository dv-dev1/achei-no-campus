# Issues do Daniel: #2, #11, #12 e #14

## Intenção

- #14: o CI roda os casos de teste do navegador (`npm run test:ct`) a cada push, e a correção de #3 e #4 passa a ser conferida pelo próprio CI.
- CT-26 falhava em tela de escala 1 (macOS, Linux do CI): a foto 4:3 na largura toda passava da altura da janela e escondia o título. A foto do detalhe fica limitada a 400 px de altura.
- #2: `test:web` e `test:ct` acham Chrome ou Edge nos caminhos comuns do macOS e do Windows; sem nenhum, o erro manda definir `CHROME_BIN`.
- #11 e #12: gerar o APK e rodar no simulador do iPhone, assim que o Android SDK e o Xcode estiverem instalados.

## Critério de aceite

```bash
flutter analyze                # No issues found!
flutter test                   # All tests passed!
cd firestore-tests
node --test navegador.test.js  # pass 3, fail 0
npx --no-install firebase emulators:exec --config ../firebase.json --project demo-achei-no-campus --only auth,firestore "npm test"          # fail 0
npx --no-install firebase emulators:exec --config ../firebase.json --project demo-achei-no-campus --only auth,firestore "npm run test:web"  # pass 1
npx --no-install firebase emulators:exec --config ../firebase.json --project demo-achei-no-campus --only auth,firestore "npm run test:ct"   # tests 28, fail 0, todo 4
gh run list -R dv-dev1/achei-no-campus -L 1   # completed success, com o passo test:ct
```

#11: `flutter build apk --release` gera `build/app/outputs/flutter-apk/app-release.apk`.
#12: `flutter run -d <simulador>` abre o app no iPhone.

## Fora de escopo

- Firebase real e deploy (#5, #7): agora são do Lúcio.
- APK contra o Firebase real: depende de #5 e #6; até lá, só o build contra os emuladores.
- Rodar a coluna **A** de `docs/testes.md` num celular: precisa do aparelho.
