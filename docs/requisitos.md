# Requisitos

O que o Achei no Campus faz e com que regras, descrito a partir do app como ele está na `main`, e não do que foi planejado. Cada requisito aponta onde está no código e qual caso de teste de [`testes.md`](testes.md) prova que ele funciona. Os diagramas ficam em [`diagramas/`](diagramas/).

## Quem usa

| Papel | Quem é |
| --- | --- |
| **Aluno** | Qualquer pessoa com e-mail `@cs.unipe.edu.br` verificado. Vê o feed, busca, filtra e publica. |
| **Autor do item** | O aluno que publicou um item. Só ele edita, apaga e marca o item como devolvido. |
| **Interessado** | O aluno que toca em **Conversar** no item de outra pessoa, porque acha que o item é dele ou porque o achou. |

Autor e interessado são o mesmo aluno em momentos diferentes: quem publica um item hoje pode ser o interessado no item de outra pessoa amanhã.

## Histórias de usuário

- Como **aluno que perdeu** alguma coisa, quero ver os itens achados no campus, buscar e filtrar por categoria e local, para descobrir se alguém achou o meu.
- Como **aluno que achou** alguma coisa, quero publicar o item com foto, categoria e local, para o dono encontrar sem eu precisar expor meu telefone.
- Como **interessado**, quero conversar com quem publicou dentro do app, para combinar onde e quando devolver.
- Como **autor do item**, quero ver quantas mensagens não li e marcar o item como devolvido, para saber quem me procurou e tirar o item do feed quando o caso se resolver.
- Como **autor do item**, quero editar ou apagar o que publiquei, para corrigir um erro ou retirar o item.

## Requisitos funcionais

| RF | O que o app faz | Onde está | Prova |
| --- | --- | --- | --- |
| RF-01 | Cadastro com nome, e-mail e senha. Só aceita e-mail que termina exatamente em `@cs.unipe.edu.br` e senha com pelo menos 6 caracteres. | `lib/telas/entrar.dart`, `lib/sessao.dart`, `lib/config.dart` (`emailPermitido`) | CT-01, CT-02, CT-03, CT-06 |
| RF-02 | Verificação do e-mail obrigatória antes do feed, com **Reenviar verificação** e o aviso de que o e-mail pode cair no spam. Depois de **Já verifiquei**, o app recarrega o usuário e renova o token, e só então cria o perfil. | `lib/telas/entrar.dart`, `lib/sessao.dart` (`prepararAcesso`) | CT-04, CT-05 |
| RF-03 | Entrar com e-mail e senha, com mensagem clara para senha errada, e sair. | `lib/telas/entrar.dart`, `lib/telas/perfil.dart`, `lib/sessao.dart` | CT-05, CT-07, CT-10 |
| RF-04 | Perfil com nome (obrigatório) e curso (opcional). O nome do perfil é o que aparece nos itens publicados depois. | `lib/telas/perfil.dart`, `lib/sessao.dart` (`salvarPerfil`) | CT-08, CT-09 |
| RF-05 | Publicar item perdido ou achado: tipo, título, categoria e local obrigatórios, descrição opcional. Na categoria Documentos, avisa para cobrir CPF/RG na foto. | `lib/telas/publicar.dart`, `lib/itens.dart` | CT-11, CT-12, CT-13 |
| RF-06 | Foto opcional, pela galeria ou pela câmera, de até 2 MB, enviada ao Cloudinary. Sem o Cloudinary configurado, o app avisa e deixa publicar sem foto. | `lib/telas/publicar.dart`, `lib/cloudinary.dart` | CT-14, CT-15, CT-16 |
| RF-07 | Feed com os itens abertos, mais recentes primeiro, atualizando em tempo real. Feed vazio explica o que fazer. | `lib/telas/feed.dart` | CT-17, CT-18 |
| RF-08 | Filtros por tipo (Todos, Perdidos, Achados), categoria e local, combináveis, com **Limpar**. Sem resultado, oferece **Limpar filtros**. | `lib/util/filtro.dart`, `lib/widgets/barra_de_filtros.dart` | CT-19, CT-22, CT-23 |
| RF-09 | Busca no título e na descrição, sem diferenciar acento e maiúscula. Com várias palavras, todas precisam aparecer, em qualquer ordem. | `lib/util/filtro.dart` (`Filtro.aceita`) | CT-20, CT-21 |
| RF-10 | Detalhe do item: foto (ou um ícone, sem foto), tipo, título, descrição, categoria, local, data e autor. Quem não é o autor vê **Conversar**; o autor vê **Marcar como devolvido**, **Editar** e **Apagar**. | `lib/telas/detalhe.dart` | CT-24, CT-25, CT-26 |
| RF-11 | Chat 1:1 sobre um item, entre o autor e o interessado, em tempo real. A conversa nasce na primeira mensagem e é uma só por item e interessado. Mensagem vazia não é enviada. | `lib/telas/conversa.dart`, `lib/conversas.dart`, `lib/modelos/conversa.dart` | CT-27, CT-28, CT-32 |
| RF-12 | Aba **Mensagens** com as conversas do usuário (item, com quem, última mensagem e hora) e o total de não lidas em cima da aba. Abrir a conversa zera as não lidas dela. | `lib/telas/mensagens.dart`, `lib/telas/inicio.dart`, `lib/conversas.dart` | CT-29, CT-30 |
| RF-13 | Marcar como devolvido, com confirmação. O item sai do feed de todos; cancelar não muda nada. | `lib/widgets/devolver.dart`, `lib/itens.dart` (`devolver`) | CT-33, CT-34 |
| RF-14 | **Meus itens**: tudo o que o usuário publicou, abertos e devolvidos, só dele. | `lib/telas/meus_itens.dart` | CT-35 |
| RF-15 | Editar e apagar o próprio item, com confirmação ao apagar. Quem não é o autor não vê essas ações. | `lib/telas/publicar.dart`, `lib/telas/detalhe.dart`, `lib/itens.dart` | CT-36, CT-37, CT-38 |

## Requisitos não funcionais

| RNF | Requisito | Onde está | Prova |
| --- | --- | --- | --- |
| RNF-01 | **Só alunos verificados.** Toda leitura e escrita no Firestore exige login, e-mail verificado e o domínio exato `@cs.unipe.edu.br`. A conferência da tela é conveniência; a barreira de verdade é a regra, porque qualquer um cria conta no Firebase Auth pela API. | `firestore.rules` (`aluno()`) | CT-39, CT-40 |
| RNF-02 | **Cada um mexe só no que é seu.** Item com `autorId` de outra pessoa é recusado; só o autor edita e apaga; autoria e data de criação não mudam. Conversa e mensagens só são lidas e escritas pelos dois participantes, e a mensagem sai sempre com a autoria de quem envia. | `firestore.rules` | CT-31, CT-41, CT-38 |
| RNF-03 | **Planos grátis.** Firebase no plano Spark (Authentication e Firestore) e Cloudinary grátis para as fotos, porque o Firebase Storage exige o plano pago. Por isso também não há push com o app fechado. | `lib/cloudinary.dart`, `firebase.json` | — (decisão de projeto) |
| RNF-04 | **Busca no próprio app.** O Firestore não busca texto, então filtros e busca rodam no app, sobre os 200 itens abertos mais recentes que o feed já carregou. | `lib/telas/feed.dart` (`limiteDoFeed`), `lib/util/filtro.dart` | CT-20, CT-21 |
| RNF-05 | **Tempo real com o app aberto.** Feed, conversas e contador de não lidas chegam sozinhos, sem recarregar, enquanto o app está aberto. | `lib/telas/feed.dart`, `lib/conversas.dart` | CT-17, CT-28, CT-29 |
| RNF-06 | **Plataformas.** Um código Flutter só para web, Android e iOS. Hoje a web roda e é testada no Chrome; Android e iOS têm o projeto pronto, mas ainda não foram verificados. | `pubspec.yaml`, `android/`, `ios/`, `web/` | CT-45 |
| RNF-07 | **Interface em português e identidade da UNIPÊ.** Azul `#003B71`, amarelo `#FED400`, fonte Work Sans, botões em pílula e cards com raio 12. Logo própria (pino com mochila), não a oficial. | `lib/tema.dart`, `assets/` | CT-43 |
| RNF-08 | **Fácil de usar sem explicação.** Alguém de fora do grupo consegue usar o app sozinho. | todas as telas | CT-42 |
| RNF-09 | **Locais do campus.** A lista de locais é fixa e precisa bater com os nomes que os alunos usam. | `lib/config.dart` (`locais`) | CT-44 |

## O que ficou de fora

Da spec ([`specs/2026-10-02-achei-no-campus.md`](../specs/2026-10-02-achei-no-campus.md), seção "Fora de escopo"):

- push notification com o app fechado (exige Cloud Functions, que exige o plano pago);
- publicação na Play Store e na App Store;
- login de funcionário (o domínio deles não é conhecido);
- moderação, denúncia e expiração automática de posts;
- conversa livre entre usuários e feed social: o chat sempre nasce de um item;
- app desktop nativo: no computador, roda a versão web;
- apagar a foto no Cloudinary quando o item é apagado;
- logo oficial da UNIPÊ;
- slides da apresentação.

O que a spec prevê, mas a `main` ainda não entrega, cada um com a sua issue:

| O quê | Issue |
| --- | --- |
| Projeto Firebase de verdade (hoje o app só fala com os emuladores) | #5 |
| Fotos de verdade no Cloudinary | #6 |
| Versão web no ar, no Firebase Hosting | #7 |
| APK e testes no Android | #11 |
| Rodar no simulador do iPhone | #12 |
