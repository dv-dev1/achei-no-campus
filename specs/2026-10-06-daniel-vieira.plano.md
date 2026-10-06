# Daniel Vieira — primeira entrega local

Execução inline com `executing-plans`, baseada no plano aprovado em 06/10/2026.
Base: `origin/main` em `27a9388`. Worktree: `.worktrees/daniel-vieira`, branch `feat/daniel-vieira-local`.
Spec: `specs/2026-10-06-daniel-vieira.md`.

## Restrições globais

- Preservar o modelo `Item`, os schemas e as telas de Cauê.
- `StreamBuilder` e `setState`; nenhum gerenciador de estado adicional.
- Emuladores por padrão: projeto `demo-achei-no-campus`, Auth 9099 e Firestore 8080.
- Domínio `@cs.unipe.edu.br` com verificação obrigatória na interface e nas regras.
- Nome obrigatório e curso opcional. Tipo, título, categoria e local obrigatórios; descrição e foto opcionais.
- Upload por bytes, até 2 MB, HTTP simulado em testes. Sem configuração, impedir o envio da foto e permitir publicação sem foto.
- Testes novos devem falhar antes da implementação. Commits locais somente após autorização do gate; sem push ou merge.

### Task 1: Ambiente e scaffold

Instalar Flutter stable e JDK 21. Criar scaffold Android/iOS/web em diretório temporário e copiar apenas arquivos ausentes, preservando `lib/` e `test/`. Adicionar dependências usadas nas telas existentes e nas entregas. Rodar a suíte de Cauê para estabelecer a base. Criar Firebase CLI local e lockfile em `firestore-tests/`.

Verificação: `flutter test`, esperado `All tests passed!`.

### Task 2: Firebase local e regras

Escrever testes reais com `@firebase/rules-unit-testing` antes das regras. Exercitar domínio, verificação, criação, leitura, edição e exclusão; autoria imutável; perfis próprios; conversas e mensagens acessíveis apenas aos participantes. Observar falhas com regra permissiva temporária no emulador, depois implementar e observar aprovação. Versionar portas, projeto demo e índice composto do feed.

Verificação: `npx --no-install firebase emulators:exec --config ../firebase.json --project demo-achei-no-campus --only auth,firestore "npm test"`, esperado `fail 0`.

### Task 3: Login, verificação e perfil

Escrever testes de domínio e sessão, observar falhas e implementar cadastro/login, envio e reenvio da verificação. Antes do feed executar `reload()` e `getIdToken(true)`; somente após verificação criar `usuarios/{uid}` sem sobrescrever perfil existente. Implementar edição de nome/curso e saída; impedir navegação em rotas protegidas sem sessão verificada.

Verificação: `flutter test`, esperado `All tests passed!`.

### Task 4: Publicar, editar, apagar e upload

Escrever testes do formulário e upload antes da implementação. Reutilizar formulário para edição, preservar autoria/data/status, buscar nome atual do perfil ao publicar. Foto de câmera/galeria com `maxWidth: 1280, imageQuality: 70`; aviso de documentos; upload sem `dart:io`. Confirmar exclusão; somente o dono vê ações. Integrar perfil no feed e `/publicar` no app.

Verificação: `flutter test`, esperado `All tests passed!`.

### Task 5: CI, documentação e aceite

Criar GitHub Actions com Flutter, Node e JDK 21, análise, testes, build web e emuladores sem credenciais reais. Atualizar README e divisão de tarefas com o escopo efetivamente entregue. Executar todos os comandos da spec e o fluxo no Chrome. Registrar resultados e limitações reais, convergir intenção com diff e preservar worktree para entrega local.

Verificação: comandos e aceite manual da spec.
