# Reusable Workflows

Repositório utilizado para criação de Workflows Actions reutilizáveis

## Check Commit (check-commit.yml)
Utilizada para verificar a quantidade de commits que houveram na branch main, desde a última tag/release criada

### Secrets:

- `VRPACKAGETOKEN` token de usuário do GitHub

### Outputs:

- `count` retorna um Integer com a quantidade de commits na branch main, desde a ultima tag/release criada
- `exist` retorna um Boolean indicando se houveram commits na branch main, desde a ultima tag/release criada

### Exemplo
```
...
jobs:
  check-commit:
    name: Check Commit
    uses: vrsoftbr/check-commit/.github/workflows/check-commit.yml@main
    secrets:
      VRPACKAGETOKEN: ${{ secrets.VRPACKAGETOKEN }} 
...
```


