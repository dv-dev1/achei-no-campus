# Ícone e tela de abertura (splash)

A logo do app é um pino de localização com uma mochila dentro, sobre uma base amarela. Ela aparece em dois lugares:

- **Ícone:** o desenho que fica na tela inicial do celular, na aba do navegador e na lista de apps.
- **Splash (tela de abertura):** a tela que aparece por um instante quando o app abre, enquanto ele ainda está carregando. É a logo no centro, sobre o fundo cinza-claro do app (`#F7F7F7`). Sem ela, o Android mostraria uma tela branca vazia nesse tempo, e a web, uma página em branco.

## As imagens

Ficam em `assets/` e foram feitas a partir de uma única logo:

| Arquivo | Para quê | Como é |
| --- | --- | --- |
| `assets/logo.png` | Splash | Só a logo, fundo transparente, 1024 × 1024 |
| `assets/icone.png` | Ícone no iPhone e na web | Logo sobre o fundo `#F7F7F7`, sem transparência (a App Store não aceita ícone transparente) |
| `assets/icone_adaptativo.png` | Ícone no Android e splash do Android 12+ | Logo menor, com folga em volta, fundo transparente |

**Por que o Android tem uma versão com folga?** No Android, quem decide o formato do ícone é o celular: círculo, gota, quadrado arredondado... Ele recorta o ícone, e só o miolo nunca é cortado (mais ou menos 60% do meio). Por isso a logo fica menor nessa versão, para caber inteira em qualquer recorte. O fundo atrás dela é a cor `#F7F7F7`. No Android 12 ou mais novo, o splash também usa o ícone dentro de um círculo, então usa a mesma imagem.

## Como gerar de novo (trocou a logo?)

1. Substitua as imagens em `assets/`, mantendo os nomes. As três podem sair da mesma logo: o ideal é uma imagem quadrada de 1024 px ou mais, com fundo transparente.
2. Rode:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

3. Confira com `git status` e `git diff` o que mudou antes de commitar (veja os cuidados abaixo).

As configurações ficam em dois arquivos na raiz, comentados: `flutter_launcher_icons.yaml` (ícone) e `flutter_native_splash.yaml` (splash). As duas ferramentas estão em `dev_dependencies`: elas só geram arquivos e não vão dentro do app.

## Cuidados ao gerar de novo

As ferramentas mexem em arquivos que não são delas. Na primeira geração (06/10), três coisas precisaram de ajuste à mão:

- **`web/index.html`:** o gerador do splash reescreve o arquivo. Ele manteve o `firebase_local.js` do Daniel, mas acrescentou uma linha que **bloqueava o zoom com os dedos** (`user-scalable=no`), o que atrapalha quem precisa ampliar a tela. A linha ficou só com `width=device-width, initial-scale=1.0`. Se gerar de novo, confira se o bloqueio não voltou.
- **`ios/Runner.xcodeproj/project.pbxproj`:** o gerador do ícone trocou uma configuração do Xcode que só aceita sim/não (`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`) de `YES` para `AppIcon`, o que pode quebrar o build no Mac. A alteração foi desfeita (`git checkout` no arquivo). O nome do ícone já é `AppIcon` por padrão.
- **`ios/Runner/Info.plist`:** o gerador do splash reindentou o arquivo inteiro só para acrescentar uma linha que já é o padrão. Também foi desfeito.

## O splash some sozinho?

Sim. O app não chama nada para tirar o splash: quando o Flutter desenha a primeira tela, ela cobre o splash por completo. Isso foi conferido com um app de teste que pinta a tela toda de vermelho: o print saiu todo vermelho, sem a logo aparecendo.

## Como foi conferido

- **Web:** print da página só com o splash (logo no centro, fundo `#F7F7F7`), a prova do vermelho acima e o teste de recarga no Chrome do Daniel (`npm run test:web`) passando com o `index.html` novo.
- **Android:** sem emulador nesta máquina. Foi montada uma prévia a partir dos arquivos gerados (`res/mipmap-*` e `res/drawable-*`), com o ícone recortado em círculo: a logo cabe inteira. Vale abrir no celular quando gerarem o APK.
- **iOS:** os 25 tamanhos de ícone foram gerados e conferidos, mas ainda não foram vistos num iPhone, porque precisa do Mac com Xcode.

## Observações sobre a logo

- A imagem original tem 500 px, e o desenho ocupa só uns 180 × 250 px dela. Para os ícones grandes (o de 1024 px da App Store), ela foi ampliada e pode ficar levemente suave. Se existir uma versão maior ou em SVG, vale gerar de novo com ela.
- As cores da logo (azul-escuro acinzentado e um amarelo um pouco diferente) não são exatamente as do tema (`#003B71` e `#FED400`). A logo foi usada como veio.
