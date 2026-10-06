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
```

No Chrome: cadastrar, reenviar a verificação, verificar pelo emulador, confirmar a verificação, criar/editar perfil, publicar sem foto, editar, cancelar exclusão, apagar e sair. Um segundo usuário não vê ações de gestão do item alheio e não consegue alterá-lo pela API.
Os testes de upload exercitam bytes, limite de 2 MB, erros HTTP e configuração ausente; a ausência de Cloudinary bloqueia somente o envio de uma foto.

## Fora de escopo

Convites a colaboradores, Firebase real, credenciais reais, upload real, deploy, chat, Meus itens, logo, ícone e splash. As tarefas de Cauê e Lúcio permanecem com seus responsáveis. Android e iOS recebem scaffold; build e aceite desta entrega são web.
