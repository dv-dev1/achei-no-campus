# QA: plano de testes, casos e registro de bugs

## Intenção

O projeto tem 82 testes automatizados verdes e CI passando, mas nenhum plano de
testes manual, nenhum caso de teste escrito e nenhum bug registrado. Quem for
avaliar a entrega não consegue dizer o que foi testado nem em quais aparelhos.

Este trabalho entrega o papel de QA descrito em `docs/escopo-detalhado.md`:
o plano e os casos de teste em `docs/testes.md`, a execução deles nas três
plataformas, e os defeitos encontrados registrados como issue no GitHub.

## Critério de aceite

```bash
# 1. A suíte automatizada continua verde e a análise limpa.
flutter analyze          # esperado: "No issues found!"
flutter test             # esperado: "All tests passed!"

# 2. Existe um caso de teste para cada funcionalidade da lista do escopo.
grep -c '^### CT-' docs/testes.md     # esperado: >= 20

# 3. Cada funcionalidade da lista aparece no documento.
grep -ciE 'cadastro|publicar|feed|filtro|busca|detalhe|chat|devolvido|meus itens|perfil' docs/testes.md

# 4. Os defeitos confirmados têm issue aberta e rastreável.
gh issue list --state open
```

## Fora de escopo

- Corrigir os defeitos encontrados: a correção é de Daniel e de Cauê. O QA
  registra, acompanha e reteste.
- Escrever `docs/requisitos.md` e os diagramas de `docs/diagramas/`: eles ainda
  não existem, e o escopo pede que o QA os **revise**, não que os crie.
- Teste no iOS com aparelho real: depende de um Mac com Xcode, que não há nesta
  máquina. Fica registrado como não executado.
