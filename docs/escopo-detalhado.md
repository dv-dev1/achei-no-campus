# Achei no Campus: escopo detalhado

Repositório: https://github.com/dv-dev1/achei-no-campus · Spec: `specs/2026-10-02-achei-no-campus.md`

Cada tarefa traz o que fazer e quando ela está pronta. As marcadas com **faltava** não estavam na função original e foram distribuídas.

**Combinados do grupo**

- Flutter (Android, iOS e web) + Firebase plano grátis (Authentication e Firestore). Fotos no Cloudinary, porque o Storage exige o plano pago.
- Estado com `StreamBuilder` + `setState`, sem biblioteca de estado.
- Cada tarefa vira uma issue no GitHub e é entregue com commits e push direto para a `main`, sem exigir PR ou aprovação de merge. É necessário aceitar o convite de colaborador para ter acesso de escrita.
- Login só com e-mail `@cs.unipe.edu.br` verificado.

---

## Daniel (Full Stack)

### 1. Projeto Flutter + Firebase

- Criar o projeto com `flutter create --org br.edu.unipe.acheinocampus --platforms android,ios,web achei_no_campus`.
- Ligar ao Firebase com `flutterfire configure` (Authentication com e-mail/senha ligado no console, e Firestore).
- Criar `lib/config.dart` com:
  - `emailPermitido(email)`: aceita só `@cs.unipe.edu.br`.
  - Lista de categorias: Documentos, Eletrônicos, Chaves, Carteira/Dinheiro, Garrafa/Copo, Roupa/Acessório, Material escolar, Outros.
  - Lista de locais da spec (Reitoria, blocos, EVA, Biblioteca etc.).
  - Cloud name e preset do Cloudinary.
- Criar o modelo do item (campos abaixo) e subir **logo no começo**, porque as telas do Cauê dependem dele.

```text
itens/{id}
  tipo: "perdido" | "achado"
  titulo, descricao, categoria, local, fotoUrl
  autorId, autorNome
  status: "aberto" | "devolvido"
  criadoEm
```

- `main.dart` com o "portão": sem login abre a tela de entrar; logado e verificado abre o feed.
- Teste `test/config_test.dart`: `emailPermitido` aceita `@cs.unipe.edu.br` e recusa `@gmail.com` e `cs.unipe.edu.br.evil.com`.

**Pronto quando:** `flutter analyze` e `flutter test` passam, e `flutter run -d chrome` abre o app.

### 2. Login e cadastro

- Tela `telas/entrar.dart` com entrar e cadastrar (nome, e-mail e senha).
- Recusar na tela o e-mail que não for `@cs.unipe.edu.br`.
- Depois do cadastro, enviar o e-mail de verificação e mostrar a tela "verifique seu e-mail", com botão **reenviar** e o aviso de que ele pode cair no spam.
- Quando o usuário confirmar, chamar `user.reload()` e `getIdToken(true)`. Sem isso o token continua "não verificado" e as regras negam tudo.
- Criar o documento `usuarios/{uid}` com `nome`, `curso` e `criadoEm`.

**Pronto quando:** cadastro com `@cs.unipe.edu.br` chega ao feed depois de verificar; cadastro com `@gmail.com` é recusado na tela.

### 3. Perfil e sair

- Tela de perfil mostrando e editando nome e curso (`usuarios/{uid}`).
- Botão **sair** que volta para a tela de entrar.

**Pronto quando:** alterar o nome reflete nos próximos itens publicados, e sair leva para a tela de entrar.

### 4. Publicar item com foto

- Tela `telas/publicar.dart`: tipo (perdido/achado), título, descrição, categoria, local e foto.
- Foto pela câmera ou galeria com `pickImage(maxWidth: 1280, imageQuality: 70)`.
- Enviar a foto por bytes (`readAsBytes()` + `MultipartFile.fromBytes`) em `lib/cloudinary.dart`. `dart:io File` quebra na web.
- Salvar o item no Firestore com `status: "aberto"` e o `fotoUrl` devolvido pelo Cloudinary.
- Na categoria Documentos, mostrar o aviso "cubra CPF/RG na foto" (LGPD).
- Validar campos obrigatórios e mostrar carregando durante o envio.

**Pronto quando:** o item publicado aparece no Firestore com a foto abrindo pela URL, no Android e na web.

### 5. Regras de segurança do Firestore e testes (faltava)

- `firestore.rules`: toda leitura e escrita exige login, e-mail verificado e domínio `@cs.unipe.edu.br`.
  - `itens`: todos leem; cria só com `autorId` igual ao próprio; edita e apaga só o dono.
  - `usuarios/{uid}`: todos leem; cada um escreve só o seu.
  - `conversas` e `mensagens`: só os dois participantes leem e escrevem; mensagem só com o próprio `autorId`.
- Testes em `firestore-tests/` com `@firebase/rules-unit-testing` no emulador (precisa de JDK 11+).

**Pronto quando:** `npx firebase emulators:exec --only firestore "npm test"` passa, cobrindo: domínio errado negado, e-mail não verificado negado, só o dono edita o item, só participantes acessam a conversa.

### 6. CI no GitHub Actions (faltava)

- `.github/workflows/ci.yml` rodando `flutter analyze`, `flutter test` e os testes das regras a cada push e PR.

**Pronto quando:** a última execução em `gh run list` aparece como `success`.

### 7. Editar e apagar o próprio item (faltava)

- Reaproveitar a tela de publicar para editar.
- Botão apagar com confirmação.
- Só o dono vê esses botões (as regras já bloqueiam os outros).

**Pronto quando:** o dono edita e apaga; outro usuário não vê os botões e, se tentar pela API, a regra nega.

### 8. Deploy web no Firebase Hosting (faltava)

- `flutter build web` e `firebase deploy --only hosting`.

**Pronto quando:** o app abre pela URL pública do Firebase e dá para entrar e ver o feed.

### 9. Adicionar Cauê e Lúcio no repo (faltava)

- Convidar os dois como colaboradores em Settings → Collaborators.

**Pronto quando:** os dois aceitaram os convites e conseguem enviar commits diretamente para a `main`, sem PR.

---

## Cauê (Full Stack)

### 1. Tema visual

- `lib/tema.dart` com as cores do site da UNIPÊ:
  - Azul primário `#003B71`, amarelo de destaque `#FED400`, fundo `#F7F7F7`, texto `#222222`.
- Fonte **Work Sans** com `google_fonts`.
- Botões em pílula (raio grande) e cards com raio 12.
- Aplicar o tema no `MaterialApp` para todas as telas herdarem.

**Pronto quando:** todas as telas usam o tema sem cor nem fonte fixa no código delas.

### 2. Tela inicial (feed)

- `telas/feed.dart` lendo `itens` com `status == "aberto"`, mais recentes primeiro, limite de 200, atualizando em tempo real.
- Card de cada item: foto, título, etiqueta perdido/achado, categoria, local e há quanto tempo foi publicado.
- Estado vazio ("nenhum item ainda") e carregando.
- Botão para publicar (leva à tela do Daniel).
- Enquanto a base do Daniel não chega, testar com itens de exemplo.

**Pronto quando:** um item publicado aparece no feed de outro usuário sem recarregar.

### 3. Filtros e busca

- Chips no topo: perdido / achado / todos, categoria e local, combináveis.
- Campo de busca que procura no título e na descrição, sem diferenciar maiúsculas e acentos.
- Filtro e busca rodam no próprio app, sobre os 200 itens carregados (o Firestore não tem busca por texto).
- Botão para limpar os filtros.

**Pronto quando:** filtrar "achado + Eletrônicos + Biblioteca" e buscar "fone" mostra só os itens certos.

### 4. Tela de detalhe com botão de contato

- `telas/detalhe.dart`: foto grande, tipo, título, descrição, categoria, local, data e nome de quem postou.
- Botão **Conversar**, que abre o chat (tarefa 8). Não aparece para o próprio autor.

**Pronto quando:** tocar num card abre o detalhe com todos os dados corretos.

### 5. Marcar como devolvido

- Botão **Marcar como devolvido** no detalhe e em "Meus itens", visível só para o dono.
- Confirmação antes de mudar o `status` para `"devolvido"`.
- Item devolvido sai do feed.

**Pronto quando:** depois de marcar, o item some do feed para todos e aparece como devolvido em "Meus itens".

### 6. Logo, ícone e splash (faltava)

- Logo própria: lupa azul com estrela amarela (a estrela oficial da UNIPÊ é marca registrada).
- Salvar em `assets/logo.png` e gerar o ícone com `flutter_launcher_icons`.
- Splash com a logo.

**Pronto quando:** o ícone e o splash aparecem no Android e na web.

### 7. Tela "Meus itens" (faltava)

- Lista dos itens do usuário logado (`autorId` = ele), abertos e devolvidos, com a etiqueta do status.
- Dali se marca como devolvido e se abre a edição do Daniel.

**Pronto quando:** cada usuário vê só os próprios itens.

### 8. Chat e aba de mensagens (faltava)

- O chat sempre nasce de um item. ID da conversa: `{itemId}_{uidDoInteressado}`, para não duplicar.
- Tela da conversa: mensagens em tempo real, campo de texto e enviar.
- Aba **Mensagens**: lista das conversas do usuário, com o item, a última mensagem e a hora.
- Contador de não lidas: quem envia soma 1 no `naoLidas` do outro; quem abre a conversa zera o seu.

```text
conversas/{itemId}_{interessadoUid}
  itemId, participantes: [donoUid, interessadoUid]
  ultimaMensagem, atualizadoEm
  naoLidas: { <uid>: n }

conversas/{id}/mensagens/{id}
  autorId, texto, criadoEm
```

**Pronto quando:** dois usuários conversam sobre um item em tempo real, o contador sobe para quem recebe e zera ao abrir, e um terceiro usuário não consegue ler a conversa.

---

## Lúcio (QA)

### 1. Plano e casos de teste

- Plano de testes: o que será testado, em quais aparelhos e como os bugs serão registrados.
- Casos de teste por funcionalidade, cada um com passos, resultado esperado e resultado obtido:
  - Login e cadastro (inclusive e-mail fora do domínio e e-mail não verificado).
  - Publicar (com e sem foto, câmera e galeria, aviso de Documentos).
  - Feed, filtros e busca.
  - Detalhe, chat e contador de não lidas.
  - Marcar como devolvido, Meus itens, editar e apagar.
  - Perfil e sair.
- Guardar em `docs/testes.md` no repo.

**Pronto quando:** existe pelo menos um caso de teste para cada funcionalidade da lista.

### 2. Testar no Android e no iOS

- Rodar os casos de teste em cada entrega, assim que os commits chegarem à `main`, e não só no fim.
- Android pelo APK; iOS pelo simulador do iPhone (precisa de Mac com Xcode); web pelo Chrome.
- Testar entre plataformas: item publicado no Android aparece no iPhone e na web.

**Pronto quando:** todos os casos passaram nas três plataformas, ou os que falharam viraram bug registrado.

### 3. Registrar e acompanhar bugs

- Cada bug vira issue no GitHub com: passos para reproduzir, o que era esperado, o que aconteceu, plataforma e print.
- Marcar o responsável (Daniel ou Cauê) e acompanhar até fechar.
- Retestar depois da correção antes de fechar a issue.

**Pronto quando:** nenhum bug aberto na entrega, ou os restantes estão listados como conhecidos.

### 4. Validar a experiência e conferir a versão final

- Pedir para alguém de fora do grupo usar o app sem ajuda e anotar onde travou.
- Conferir textos, acentos, cores e se tudo segue o tema.
- Antes da entrega, rodar todos os casos de teste na versão final.

**Pronto quando:** a versão final passou na conferência completa.

### 5. Conferir a lista de locais no campus (faltava)

- Andar pelo campus e conferir se os locais da spec existem e com que nome: Reitoria, Bloco de Medicina, Odontologia, Enfermagem, Arquitetura, EVA, Biblioteca, Centro de Informação, Pós-Graduação, Auditório, Ginásio, Piscina, Clínica-escola, Praça de alimentação, Passarela, Estacionamento.
- Corrigir no `lib/config.dart` e enviar o commit diretamente para a `main`, ou passar a lista para o Daniel.

**Pronto quando:** a lista no app bate com o campus.

### 6. Gerar o APK de teste (faltava)

- `flutter build apk --debug` (precisa do Android SDK).
- Instalar no celular e repassar o APK para o grupo testar.

**Pronto quando:** o APK instala e abre num Android real.

### 7. Revisar requisitos e diagramas (faltava)

- Revisar `docs/requisitos.md`: requisitos funcionais, não funcionais e histórias de usuário.
- Revisar os diagramas em `docs/diagramas/` (casos de uso, dados, arquitetura e sequência do chat).
- Conferir se o que está escrito bate com o app pronto.

**Pronto quando:** requisitos e diagramas descrevem o app como ele foi entregue.

---

## Ordem

1. **Daniel** monta a base (tarefa 1) e convida o grupo. Ao mesmo tempo, **Cauê** faz tema e logo, e **Lúcio** escreve o plano de testes e confere os locais.
2. **Daniel:** login e publicar. **Cauê:** feed, filtros, busca e detalhe.
3. **Daniel:** regras, CI, perfil, editar e apagar. **Cauê:** devolvido, Meus itens e chat.
4. **Lúcio** testa cada entrega à medida que chega. No fim: deploy web (Daniel), APK e iOS, revisão da documentação e conferência final (Lúcio).
