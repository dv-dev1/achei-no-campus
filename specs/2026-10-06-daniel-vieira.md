# Daniel Vieira — primeira entrega local

## Intenção

Permitir cadastro e login com e-mail acadêmico verificado, criação e edição do perfil e saída da conta.
Permitir publicar sem foto, editar e apagar os próprios itens nas telas existentes de Cauê.
Executar Auth e Firestore localmente, sem credenciais reais, com regras que protegem autoria e conversas.

## Critério de aceite

```bash
flutter analyze
# No issues found!
flutter test
# All tests passed!
flutter build web
# Built build/web
cd firestore-tests
npm ci
npx --no-install firebase emulators:exec --config ../firebase.json --project demo-achei-no-campus --only auth,firestore "npm test"
# fail 0
npx --no-install firebase emulators:exec --config ../firebase.json --project demo-achei-no-campus --only auth,firestore "npm run test:web"
# tests 1; pass 1; fail 0
```

No Chrome: cadastrar, reenviar a verificação, verificar pelo emulador, confirmar a verificação, criar/editar perfil, publicar sem foto, editar, cancelar exclusão, apagar e sair. Um segundo usuário não vê ações de gestão do item alheio e não consegue alterá-lo pela API.
Os testes de upload exercitam bytes, limite de 2 MB, erros HTTP e configuração ausente; a ausência de Cloudinary bloqueia somente o envio de uma foto.

Convergência da intenção com a implementação:

- Cadastro/login, verificação e perfil: `lib/sessao.dart`, `lib/main.dart` e telas `entrar.dart`/`perfil.dart`. O teste de sessão confirma `reload()` antes de `getIdToken(true)` e que perfil não existe antes da verificação.
- Publicar, editar e apagar os próprios itens: `lib/itens.dart`, `lib/telas/publicar.dart`, `lib/telas/feed.dart` e `lib/telas/detalhe.dart`. O modelo `lib/modelos/item.dart` permanece idêntico à base `27a9388`.
- Execução local e proteção de dados: `lib/firebase_local.dart`, `web/firebase_local.js`, `firebase.json`, `firestore.rules` e `firestore-tests/`. Configuração demo, domínio/verificação obrigatórios, autoria imutável e conversas restritas aos membros.

Aceite executado em 06/10/2026: `flutter analyze` sem problemas, 61 testes Flutter aprovados, build web concluído, `npm ci` concluído, 21 testes de regras e um teste Chrome de recarga aprovados. O fluxo visual no Chrome confirmou cadastro, reenvio, verificação pelo emulador, edição do perfil, publicação sem foto, edição, cancelamento da exclusão, exclusão e saída. Segundo usuário sem ações de dono; tentativas PATCH e DELETE do item alheio retornaram HTTP 403. Desktop e viewport 390×844 inspecionados.

Os testes novos falharam antes da implementação. A recarga também falhou sem o bootstrap local, detectando requisições indevidas a `identitytoolkit.googleapis.com`; restaurada a correção, o teste passou sem essas requisições.

## Fora de escopo

Convites a colaboradores, Firebase real, credenciais reais, upload real, deploy, chat, Meus itens, logo, ícone e splash. As tarefas de Cauê e Lúcio permanecem com seus responsáveis. Android e iOS recebem scaffold; build e aceite desta entrega são web.
