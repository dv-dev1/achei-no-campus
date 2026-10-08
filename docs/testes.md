# Plano de testes e casos de teste

Responsável: Lúcio (QA). Base: `docs/escopo-detalhado.md` e `specs/2026-10-02-achei-no-campus.md`.

## 1. Plano de testes

### O que é testado

Todas as funcionalidades entregues por Daniel e por Cauê:

| Área | Telas e arquivos |
|---|---|
| Login, cadastro e verificação | `lib/telas/entrar.dart`, `lib/sessao.dart` |
| Perfil e sair | `lib/telas/perfil.dart` |
| Publicar, editar e apagar item | `lib/telas/publicar.dart`, `lib/itens.dart`, `lib/cloudinary.dart` |
| Feed, filtros e busca | `lib/telas/feed.dart`, `lib/util/filtro.dart`, `lib/widgets/barra_de_filtros.dart` |
| Detalhe e marcar como devolvido | `lib/telas/detalhe.dart`, `lib/widgets/devolver.dart` |
| Meus itens | `lib/telas/meus_itens.dart` |
| Chat e não lidas | `lib/telas/conversa.dart`, `lib/telas/mensagens.dart`, `lib/conversas.dart` |
| Regras de segurança | `firestore.rules` |

### Em quais aparelhos

| Plataforma | Como | Observação |
|---|---|---|
| Web | `flutter run -d chrome` | Com os emuladores de Auth e Firestore ligados. |
| Android (emulador) | `flutter run -d emulator-5554` | O app encontra o host sozinho, em `10.0.2.2`. |
| Android (celular real) | `flutter build apk --debug` | **Precisa** de `--dart-define=EMULATOR_HOST=<IP da máquina na rede>`. Sem isso o APK tenta `10.0.2.2`, que não existe fora do emulador, e o app abre direto na tela "Não foi possível iniciar o app". |
| iOS (simulador) | `flutter run -d <simulador>` | Depende de um Mac com Xcode. |

### Como os emuladores sobem

```bash
cd firestore-tests && npm ci
npx firebase emulators:start --config ../firebase.json \
  --project demo-achei-no-campus --only auth,firestore
```

O projeto não tem Firebase real: tudo roda contra o emulador local (`lib/firebase_local.dart`).
Como o e-mail de verificação não é enviado de verdade, a conta é verificada pela
interface do emulador de Auth (`http://127.0.0.1:4000/auth`), marcando o usuário
como verificado, e depois tocando em **Já verifiquei** no app.

### Testes automatizados que já cobrem parte disto

| Comando | O que cobre | Última execução |
|---|---|---|
| `flutter analyze` | Lint e tipos | 08/10/2026 — `No issues found!` |
| `flutter test` | 82 testes de unidade e de widget | 08/10/2026 — `All tests passed!` |
| `npm test` em `firestore-tests/` | Regras do Firestore no emulador | Verde no CI de 07/10/2026 |

O caso de teste manual existe para o que o teste automatizado **não** vê:
câmera, galeria, teclado, rolagem, troca de aparelho e texto na tela.

### Como os bugs são registrados

Cada defeito vira uma issue no GitHub com:

1. Título curto dizendo o sintoma;
2. Passos para reproduzir, numerados;
3. Resultado esperado e resultado obtido;
4. Plataforma, versão do Flutter e commit;
5. Print ou vídeo quando for visual;
6. Severidade: **alta** (impede usar), **média** (atrapalha, mas tem contorno) ou **baixa** (incômodo);
7. Responsável: Daniel (base, login, publicar, regras) ou Cauê (tema, feed, detalhe, chat).

Depois da correção o QA **reteste** antes de fechar a issue. Issue fechada sem reteste não conta.

### Legenda do resultado

`✅ passou` · `❌ falhou` · `⏳ não executado` · `➖ não se aplica`

---

## 2. Casos de teste

Cada caso traz passos, resultado esperado e o resultado obtido por plataforma:
**W** = web/Chrome, **A** = Android, **I** = iOS.

### Login e cadastro

### CT-01 — Cadastro com e-mail do domínio certo

1. Abrir o app deslogado e tocar em **Criar uma conta**.
2. Preencher nome `Lúcio Lima`, e-mail `lucio@cs.unipe.edu.br`, senha `senha123`.
3. Tocar em **Criar conta**.

**Esperado:** a conta é criada e o app mostra a tela "verifique seu e-mail", com o botão **Reenviar**.
**Obtido:** W ⏳ · A ⏳ · I ⏳

### CT-02 — Cadastro com e-mail fora do domínio

1. Em **Criar uma conta**, informar `lucio@gmail.com` e uma senha de 6 caracteres.
2. Tocar em **Criar conta**.

**Esperado:** a própria tela recusa, com a mensagem `Use seu e-mail @cs.unipe.edu.br.`, e nenhuma conta é criada no emulador de Auth.
**Obtido:** W ⏳ · A ⏳ · I ⏳ — a validação em si já é coberta por `test/config_test.dart` (✅).

### CT-03 — Domínio parecido não passa

1. Informar `lucio@cs.unipe.edu.br.evil.com`.

**Esperado:** recusado na tela.
**Obtido:** ✅ (automatizado, `test/config_test.dart`).

### CT-04 — Entrar sem verificar o e-mail

1. Cadastrar uma conta e **não** marcá-la como verificada no emulador.
2. Fechar e abrir o app.

**Esperado:** o app para na tela "verifique seu e-mail"; o feed não aparece.
**Obtido:** W ⏳ · A ⏳ · I ⏳

### CT-05 — Entrar depois de verificar

1. Marcar o usuário como verificado em `http://127.0.0.1:4000/auth`.
2. Tocar em **Já verifiquei** no app.

**Esperado:** o app chama `reload()` e `getIdToken(true)`, cria `usuarios/{uid}` e abre o feed.
**Obtido:** W ⏳ · A ⏳ · I ⏳

### CT-06 — Senha curta

1. Informar uma senha com 5 caracteres.

**Esperado:** `Use pelo menos 6 caracteres.`, sem chamada ao Firebase.
**Obtido:** W ⏳ · A ⏳ · I ⏳

### CT-07 — Senha errada ao entrar

1. Entrar com um e-mail existente e a senha errada.

**Esperado:** `E-mail ou senha incorretos.` — nunca o código cru do Firebase.
**Obtido:** W ⏳ · A ⏳ · I ⏳

### Perfil e sair

### CT-08 — Editar nome e curso

1. Abrir **Perfil** pelo ícone do feed.
2. Trocar o nome para `Lúcio Testador` e o curso para `Ciência da Computação`; tocar em **Salvar perfil**.

**Esperado:** aviso `Perfil atualizado.`; ao reabrir a tela, os valores novos continuam lá.
**Obtido:** W ⏳ · A ⏳ · I ⏳

### CT-09 — Nome novo vale no próximo item publicado

1. Depois do CT-08, publicar um item.

**Esperado:** o item aparece com `Publicado por Lúcio Testador`. Itens antigos **mantêm** o nome antigo, como combinado na spec.
**Obtido:** W ⏳ · A ⏳ · I ⏳

### CT-10 — Sair

1. No perfil, tocar em **Sair**.

**Esperado:** volta para a tela de entrar; o botão voltar do aparelho não devolve ao feed.
**Obtido:** W ⏳ · A ⏳ · I ⏳

### Publicar

### CT-11 — Publicar item sem foto

1. Tocar em **Publicar**; escolher tipo `Achado`, título `Fone de ouvido preto`, categoria `Eletrônicos`, local `Biblioteca`.
2. Tocar em **Publicar item**.

**Esperado:** aviso `Item publicado.`, a tela fecha e o item aparece no topo do feed sem recarregar.
**Obtido:** W ⏳ · A ⏳ · I ⏳

### CT-12 — Campos obrigatórios

1. Tocar em **Publicar item** com tudo vazio.

**Esperado:** três mensagens embaixo dos campos: `Informe o título.`, `Escolha a categoria.` e `Escolha o local.`
**Obtido:** W ⏳ · A ⏳ · I ⏳

### CT-13 — Aviso de LGPD na categoria Documentos

1. Na tela de publicar, escolher a categoria `Documentos`.

**Esperado:** aparece `Cubra CPF/RG na foto antes de publicar.` logo abaixo do campo, e some ao trocar de categoria.
**Obtido:** W ⏳ · A ⏳ · I ⏳

### CT-14 — Foto pela galeria

1. Tocar em **Galeria** e escolher uma imagem de até 2 MB.
2. Publicar.

**Esperado:** o nome do arquivo aparece na tela; depois de publicar, a foto abre no card e no detalhe.
**Obtido:** W ⏳ · A ⏳ · I ⏳
**Pré-requisito:** o Cloudinary ainda não está configurado (`CLOUDINARY_CLOUD_NAME` vazio em `lib/config.dart`). Sem ele o app responde `Fotos indisponíveis: configure o Cloudinary ou publique sem foto.` e o caso fica bloqueado.

### CT-15 — Foto pela câmera

1. Tocar em **Câmera**, tirar uma foto e publicar.

**Esperado:** igual ao CT-14. No Chrome, a câmera pede permissão do navegador.
**Obtido:** W ⏳ · A ⏳ · I ⏳

### CT-16 — Foto acima de 2 MB

1. Escolher na galeria uma imagem com mais de 2 MB.

**Esperado:** `A foto deve ter no máximo 2 MB.` e o item não é publicado.
**Obtido:** W ⏳ · A ⏳ · I ⏳

### Feed, filtros e busca

### CT-17 — Feed em tempo real entre aparelhos

1. Entrar com o usuário A no Android e com o usuário B na web.
2. Publicar um item pelo A.

**Esperado:** o item aparece no feed de B em poucos segundos, **sem recarregar a página**.
**Obtido:** W ⏳ · A ⏳ · I ⏳

### CT-18 — Feed vazio

1. Apagar todos os itens abertos e abrir o feed.

**Esperado:** `Nenhum item ainda. Perdeu ou achou algo? Toque em Publicar.`
**Obtido:** ✅ (automatizado, `test/feed_test.dart`) · W ⏳ · A ⏳ · I ⏳

### CT-19 — Filtros combinados

1. Com itens variados no feed, marcar o chip **Achados**.
2. Escolher a categoria `Eletrônicos` e o local `Biblioteca`.

**Esperado:** só os itens que atendem aos três ao mesmo tempo ficam na lista, e o botão **Limpar** aparece.
**Obtido:** ✅ (automatizado, `test/filtros_feed_test.dart`) · W ⏳ · A ⏳ · I ⏳

### CT-20 — Busca sem diferenciar acento e maiúscula

1. Com um item de título `ÓCULOS de grau`, digitar `oculos` na busca.

**Esperado:** o item continua na lista.
**Obtido:** ✅ (verificado em 08/10/2026).

### CT-21 — Busca com mais de uma palavra

1. Com um item de título `Fone de ouvido preto`, digitar `fone preto` na busca.

**Esperado:** o item continua na lista — é assim que a pessoa digita de verdade.
**Obtido:** ❌ falha em todas as plataformas. A busca procura o texto digitado como um pedaço só, então duas palavras separadas no título não casam. Defeito registrado para Cauê.

### CT-22 — Limpar filtros

1. Com filtro e busca ligados, tocar em **Limpar**.

**Esperado:** os chips voltam para `Todos`, o campo de busca esvazia e a lista inteira volta.
**Obtido:** ✅ (automatizado) · W ⏳ · A ⏳ · I ⏳

### CT-23 — Filtro sem resultado

1. Escolher uma combinação que não existe no feed.

**Esperado:** `Nenhum item com esses filtros.` com o botão **Limpar filtros**.
**Obtido:** ✅ (automatizado) · W ⏳ · A ⏳ · I ⏳

### Detalhe

### CT-24 — Abrir o detalhe

1. Tocar num card do feed.

**Esperado:** foto grande, tipo, título, descrição, categoria, local, data no formato `08/10/2026 às 14:30 (há 2 h)` e o nome de quem publicou.
**Obtido:** ✅ (automatizado, `test/detalhe_test.dart`) · W ⏳ · A ⏳ · I ⏳

### CT-25 — Botão Conversar não aparece para o autor

1. Abrir o detalhe de um item **seu**.

**Esperado:** no rodapé aparece **Marcar como devolvido**, nunca **Conversar**; no topo, os ícones de editar e apagar.
**Obtido:** ✅ (automatizado) · W ⏳ · A ⏳ · I ⏳

### CT-26 — Item sem foto

1. Abrir o detalhe de um item publicado sem foto.

**Esperado:** um ícone grande no lugar da foto, sem erro e sem espaço quebrado.
**Obtido:** W ⏳ · A ⏳ · I ⏳

### Chat e mensagens

### CT-27 — Primeira mensagem cria a conversa

1. Com o usuário B, abrir o item do usuário A e tocar em **Conversar**.
2. Escrever `Achei na Biblioteca, posso entregar amanhã` e enviar.

**Esperado:** a mensagem aparece à direita, em azul, e a conversa passa a existir no Firestore com o ID `{itemId}_{uidDoB}`.
**Obtido:** ✅ (automatizado, `test/chat_telas_test.dart`) · W ⏳ · A ⏳ · I ⏳

### CT-28 — Conversa em tempo real entre dois aparelhos

1. A no Android e B na web, na mesma conversa.
2. B envia uma mensagem.

**Esperado:** a mensagem aparece no aparelho de A em poucos segundos, sem recarregar.
**Obtido:** W ⏳ · A ⏳ · I ⏳

### CT-29 — Contador de não lidas sobe

1. B envia mensagem com A **fora** da conversa.

**Esperado:** a aba **Mensagens** de A mostra o número `1`, e a conversa aparece na lista com a última mensagem e a hora.
**Obtido:** ✅ (automatizado) · W ⏳ · A ⏳ · I ⏳

### CT-30 — Contador zera ao abrir

1. A abre a conversa do CT-29.

**Esperado:** o número some da aba e continua zerado ao reabrir o app.
**Obtido:** ✅ (automatizado) · W ⏳ · A ⏳ · I ⏳

### CT-31 — Terceiro não lê a conversa

1. Com o usuário C, tentar ler `conversas/{itemId}_{uidDoB}` pela API do Firestore.

**Esperado:** `PERMISSION_DENIED`.
**Obtido:** ✅ (automatizado, `firestore-tests/chat.test.js`).

### CT-32 — Mensagem vazia

1. Tocar em enviar com o campo vazio ou só com espaços.

**Esperado:** nada é enviado e nenhuma mensagem em branco aparece.
**Obtido:** ✅ (automatizado) · W ⏳ · A ⏳ · I ⏳

### Devolvido, Meus itens, editar e apagar

### CT-33 — Marcar como devolvido

1. No detalhe de um item seu, tocar em **Marcar como devolvido** e confirmar.

**Esperado:** aviso `Item marcado como devolvido.`, a tela volta ao feed e o item some do feed **de todos**.
**Obtido:** ✅ (automatizado, `test/devolver_test.dart`) · W ⏳ · A ⏳ · I ⏳

### CT-34 — Cancelar a confirmação

1. Tocar em **Marcar como devolvido** e depois em **Cancelar**.

**Esperado:** nada muda e o item continua aberto.
**Obtido:** ✅ (automatizado) · W ⏳ · A ⏳ · I ⏳

### CT-35 — Meus itens mostra só os meus

1. Com itens de A e de B no banco, abrir a aba **Meus itens** com o usuário A.

**Esperado:** só os itens de A, abertos primeiro e devolvidos depois, com a etiqueta de status.
**Obtido:** ✅ (automatizado, `test/meus_itens_test.dart`) · W ⏳ · A ⏳ · I ⏳

### CT-36 — Editar o próprio item

1. Em **Meus itens**, tocar em **Editar**, trocar o título e salvar.

**Esperado:** a tela abre já preenchida; depois de salvar, o título novo aparece no feed e no detalhe.
**Obtido:** ✅ (automatizado, `test/fluxo_daniel_test.dart`) · W ⏳ · A ⏳ · I ⏳

### CT-37 — Apagar o próprio item

1. No detalhe de um item seu, tocar no ícone de lixeira e confirmar.

**Esperado:** aviso `Item apagado.`; o item some do feed e de Meus itens.
**Obtido:** ✅ (automatizado) · W ⏳ · A ⏳ · I ⏳

### CT-38 — Outro usuário não edita nem apaga

1. Com o usuário B, abrir o detalhe de um item de A.

**Esperado:** nenhum ícone de editar ou apagar no topo. Pela API, a regra responde `PERMISSION_DENIED`.
**Obtido:** ✅ (automatizado, `firestore-tests/rules.test.js`).

### Segurança (regras do Firestore)

### CT-39 — Domínio errado não lê nada

**Esperado:** um usuário autenticado com outro domínio recebe `PERMISSION_DENIED` em qualquer leitura.
**Obtido:** ✅ (automatizado, `firestore-tests/rules.test.js`).

### CT-40 — E-mail não verificado não escreve

**Esperado:** `PERMISSION_DENIED` ao tentar criar item.
**Obtido:** ✅ (automatizado).

### CT-41 — Item criado com `autorId` de outro

**Esperado:** `PERMISSION_DENIED`.
**Obtido:** ✅ (automatizado).

### Experiência e versão final

### CT-42 — Pessoa de fora usa o app sem ajuda

1. Pedir a alguém de fora do grupo para publicar um item achado e conversar sobre ele, sem explicação nenhuma.
2. Anotar onde a pessoa parou ou hesitou.

**Esperado:** a pessoa conclui as duas tarefas sem perguntar nada.
**Obtido:** ⏳

### CT-43 — Textos, acentos e tema

1. Percorrer todas as telas procurando acento quebrado, texto cortado e cor fora do tema.

**Esperado:** nada fora do tema de `lib/tema.dart`, e nenhum texto cortado numa tela de 360 dp de largura.
**Obtido:** ⏳ parcial — `test/tema_test.dart` já garante que as telas herdam o tema (✅).

### CT-44 — Lista de locais bate com o campus

1. Conferir no campus cada nome de `lib/config.dart`.

**Esperado:** todos existem, com o nome que as pessoas usam.
**Obtido:** ⏳ — depende de ir ao campus.

### CT-45 — Rodar tudo na versão final

1. Antes da entrega, repetir os casos acima no commit que vai ser entregue.

**Esperado:** nenhum ❌ em aberto, ou os restantes listados como defeitos conhecidos.
**Obtido:** ⏳
