# Achei no Campus

## Intenção

Quem perde alguma coisa no campus da UNIPÊ hoje só conta com grupo de WhatsApp e sorte. O Achei no Campus é um app (Android, iOS e web) em que o aluno, com e-mail `@cs.unipe.edu.br`, publica item perdido ou achado com foto, filtra por categoria e local, busca, conversa dentro do app com quem postou e marca o item como devolvido.

É trabalho de disciplina de um grupo de 3 a 4 pessoas, com prazo de cerca de um mês. A IA entrega a **base** (tema, logo, login, regras de segurança, o fluxo publicar → feed → detalhe, rascunho de requisitos e diagramas). O resto vira **issue com dono** no GitHub.

## Critério de aceite

Base, entregue pela IA:

```bash
cd ~/achei-no-campus
flutter analyze
# No issues found!

flutter test
# All tests passed!   (inclui emailPermitido: aceita @cs.unipe.edu.br, recusa @gmail.com e cs.unipe.edu.br.evil.com)

cd firestore-tests && npx firebase emulators:exec --only firestore "npm test"
# todos passam:
#   domínio errado → negado
#   e-mail não verificado → negado
#   item: só o dono edita ou apaga
#   conversa e mensagens: só os dois participantes leem e escrevem

cd .. && flutter build web
# ✓ Built build/web

gh run list -R dv-dev1/achei-no-campus -L 1
# completed  success
```

Manual, no Chrome (`flutter run -d chrome`): cadastrar com `@cs.unipe.edu.br`, verificar o e-mail, publicar um item com foto, ver o item no feed e no detalhe. Cadastro com `@gmail.com` é recusado na tela e, se forçado pela API, pela regra do Firestore.

Quando as ferramentas estiverem instaladas: `flutter build apk --debug` gera o APK (Android SDK) e `flutter run` abre no simulador do iPhone (Xcode).

Cada issue do grupo traz o próprio critério de aceite no corpo.

## Fora de escopo

- Push notification com o app fechado: exige Cloud Functions, que exige o plano Blaze (cartão).
- Publicação na Play Store e na App Store.
- Login de funcionário: o domínio não é conhecido; entra quando alguém confirmar.
- Moderação, denúncia e expiração automática de posts.
- DM livre entre usuários e feed social: o chat nasce sempre de um item.
- App desktop nativo (Windows, macOS, Linux): no computador, roda a versão web.
- Apagar a foto no Cloudinary quando o item é excluído.
- Logo oficial da UNIPÊ.
- Slides da apresentação.

## Decisões

Tomadas no brainstorm de 02/10/2026. Formato: escolhido — descartado, e por quê.

| Tema | Escolhido | Descartado e motivo |
|---|---|---|
| Contexto | Trabalho de disciplina, demo para o professor | Produto real: pediria moderação e expiração |
| Divisão | IA faz a base, grupo pega issues | IA fazer tudo deixaria o grupo sem o que apresentar |
| Login | E-mail/senha, só `@cs.unipe.edu.br`, e-mail verificado, barrado também na regra | Qualquer e-mail: gente de fora postando item "achado" |
| Contato | Chat 1:1 dentro do app, nascido de um item | DM livre: mais escopo e mais abuso; WhatsApp: expõe o número |
| Aviso de mensagem | Contador de não lidas em tempo real, com o app aberto | Push: precisa de servidor (Blaze) ou chave de envio exposta no app |
| Fotos | Cloudinary grátis, upload unsigned | Firebase Storage exige Blaze desde out/2024; Supabase seria um segundo backend |
| Busca | No cliente, sobre os 200 itens abertos mais recentes | Firestore não tem busca textual; Algolia é exagero para um campus |
| Plataformas | APK Android, simulador iOS, web no Firebase Hosting | Desktop nativo: FlutterFire não roda em Linux, e são dois alvos a mais para testar |
| Estado | `StreamBuilder` + `setState`, sem lib de estado | Bloc/Riverpod: o professor não exige e atrasaria colegas iniciantes |
| Repositório | `dv-dev1/achei-no-campus`, público, MIT | Privado perde valor de portfólio |
| Marca | Cores e fonte da UNIPÊ, logo própria "lupa + estrela" gerada na API de imagem da OpenAI | Estrela oficial é marca registrada da instituição |
| Documentação | Requisitos (RF/RNF, histórias) + diagramas PlantUML com SVG versionado; rascunho da IA, grupo revisa | Mermaid: não tem caso de uso UML |
| Instalação | Por etapas: Flutter + JDK + CLIs, depois Android SDK, por último Xcode | Tudo de uma vez: o Xcode (~15 GB) travaria o começo |

## Stack

- **Flutter** (canal stable), alvos `android`, `ios`, `web`. Org do pacote: `br.edu.unipe.acheinocampus`; nome Dart: `achei_no_campus`.
- **Firebase, plano Spark (grátis)**: Authentication (e-mail/senha), Cloud Firestore, Hosting.
- **Cloudinary, plano grátis**: fotos, por upload unsigned direto do app.
- Pacotes: `firebase_core`, `firebase_auth`, `cloud_firestore`, `image_picker`, `http`, `google_fonts`. Dev: `flutter_launcher_icons`.
- Testes das regras: `firebase-tools` + `@firebase/rules-unit-testing` no emulador (precisa de JDK 11+).

## Identidade visual

Tirada do site `unipe.edu.br`:

- Azul primário `#003B71`; amarelo de destaque `#FED400`; fundo `#F7F7F7`; texto `#222222`.
- Fonte **Work Sans** (`google_fonts`).
- Botão em pílula (raio grande); card com raio 12.
- Logo: lupa azul com estrela amarela dentro. Quatro variações geradas na API de imagem da OpenAI; o grupo escolhe uma, que vira o ícone do app (`flutter_launcher_icons`) e o splash.
  - *Atualização 07/10:* a logo usada no fim foi outra, feita pelo Cauê: um pino de localização com uma mochila. Ver `docs/icone-e-splash.md`.

## Modelo de dados (Firestore)

```text
usuarios/{uid}
  nome, curso, criadoEm

itens/{id}
  tipo: "perdido" | "achado"
  titulo, descricao, categoria, local, fotoUrl
  autorId, autorNome
  status: "aberto" | "devolvido"
  criadoEm

conversas/{itemId}_{interessadoUid}      // ID fixo: impede duas conversas sobre o mesmo item
  itemId, participantes: [donoUid, interessadoUid]
  ultimaMensagem, atualizadoEm
  naoLidas: { <uid>: n }                 // quem envia incrementa o do outro; quem abre zera o seu

conversas/{id}/mensagens/{id}
  autorId, texto, criadoEm
```

## Regras de segurança (resumo)

Toda leitura e escrita exige:

```text
request.auth != null
&& request.auth.token.email_verified == true
&& request.auth.token.email.matches('.*@cs[.]unipe[.]edu[.]br')
```

- `itens`: qualquer usuário válido lê; cria só com `autorId == request.auth.uid`; edita e apaga só o dono.
- `usuarios/{uid}`: lê quem é válido; escreve só o próprio `uid`.
- `conversas` e `mensagens`: lê e escreve só quem está em `participantes`; mensagem só com `autorId == request.auth.uid`.

A validação de domínio na tela é conveniência; a barreira de verdade é a regra, porque qualquer um cria conta no Firebase Auth pela API.

## Listas

**Categorias:** Documentos, Eletrônicos, Chaves, Carteira/Dinheiro, Garrafa/Copo, Roupa/Acessório, Material escolar, Outros. Em Documentos, o formulário avisa para cobrir CPF/RG na foto (LGPD).

**Locais** (OpenStreetMap e site da UNIPÊ; o grupo confere no campus): Reitoria, Bloco de Medicina, Bloco de Odontologia, Bloco de Enfermagem, Bloco de Arquitetura, EVA (Espaço de Vida Acadêmica), Biblioteca, Centro de Informação, Pós-Graduação, Auditório, Ginásio, Piscina, Clínica-escola, Praça de alimentação/cantinas, Passarela, Estacionamento, Outro.

As duas listas ficam fixas em `lib/config.dart`.

## Estrutura prevista

```text
lib/
  main.dart            init do Firebase, tema, portão (sem login → entrar; logado → feed)
  config.dart          emailPermitido(), categorias, locais, cloud name e preset do Cloudinary
  tema.dart            cores, fonte, botões
  cloudinary.dart      enviarFoto(XFile) → URL
  telas/
    entrar.dart        login, cadastro, "verifique seu e-mail" com reenviar
    feed.dart          itens abertos, mais recentes primeiro, limit(200)
    publicar.dart      formulário com foto
    detalhe.dart       foto, dados, autor, botão "Conversar"
test/config_test.dart
firestore.rules, firebase.json, .firebaserc
firestore-tests/       package.json + rules.test.js
docs/requisitos.md
docs/diagramas/        casos-de-uso, dados, arquitetura, sequencia-chat (.puml + .svg)
assets/logo.png
.github/workflows/ci.yml   flutter analyze, flutter test, testes das regras
```

## Armadilhas para quem implementa

- Depois que o usuário verifica o e-mail, chamar `user.reload()` e `getIdToken(true)`. Sem isso o token antigo segue com `email_verified == false` e a regra nega tudo.
- Foto sempre por bytes (`XFile.readAsBytes()` + `MultipartFile.fromBytes`). `dart:io File` quebra na web.
- `pickImage(maxWidth: 1280, imageQuality: 70)` já comprime; não precisa de pacote de compressão.
- Chaves do Firebase (`firebase_options.dart`, `google-services.json`) não são segredo e podem ir para o repo público; a proteção são as regras. O preset unsigned do Cloudinary também é público: limitar formato, tamanho e pasta nele.
- O e-mail de verificação pode cair no spam do e-mail acadêmico; a tela de verificação deve dizer isso.

## Divisão do trabalho

As entregas da base e do grupo são feitas com commits e push direto para a `main`, sem exigir PR ou aprovação de merge. Cada integrante precisa aceitar o convite de colaborador para ter acesso de escrita.

**Base (IA)**, entregue diretamente na `main`: esqueleto Flutter, CI, tema, logo, Firebase configurado, login com verificação, regras e testes das regras, publicar → feed → detalhe, rascunho de `docs/requisitos.md` e dos diagramas.

**Issues (grupo)**, uma por pessoa, cada uma com critério de aceite:

1. Filtro por categoria e local (chips no feed).
2. Busca por texto no título e na descrição (no cliente).
3. Marcar como devolvido + tela "Meus itens".
4. Chat: botão "Conversar" e tela da conversa.
5. Chat: aba Mensagens + contador de não lidas.
6. Perfil (nome, curso) e sair.
7. Conferir a lista de locais no campus.
8. Deploy da versão web no Firebase Hosting.
9. Gerar o APK e testar no simulador do iOS.
10. Revisar requisitos e diagramas para a entrega.

## Pendências antes de começar o build

- [ ] `firebase login` e ligar o provedor "E-mail/senha" no console do Firebase.
- [ ] Conta no Cloudinary e preset unsigned: pasta `achei`, formatos jpg/png/webp, até 2 MB, limite de 1280 px. Anotar o cloud name e o nome do preset.
- [ ] Chave da OpenAI no Keychain: `security add-generic-password -s openai-api -a dvdev -w`, rodado no próprio terminal.
- [ ] Usuários do GitHub dos colegas, para o convite de colaborador.
- [ ] Instalar Flutter, JDK e as CLIs (`firebase-tools`, `flutterfire_cli`, `plantuml`); depois o Android SDK; por último o Xcode.

## Próximo passo

`writing-plans` sobre esta spec gera `specs/2026-10-02-achei-no-campus.plano.md` com as tarefas da base; depois do ok, execução por `subagent-driven-development`.
