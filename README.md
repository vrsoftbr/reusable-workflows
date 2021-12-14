# Reusable Workflows

Repositório utilizado para criação de Workflows Actions reutilizáveis

## Check Commit (check-commit.yml)
Utilizada para verificar a quantidade de commits que houveram na branch main, desde a última tag/release criada

### Secrets:

- `VRPACKAGETOKEN` token de usuário do GitHub **[obrigatório]**

### Outputs:

- `count` retorna um Integer com a quantidade de commits na branch main, desde a ultima tag/release criada
- `exist` retorna um Boolean indicando se houveram commits na branch main, desde a ultima tag/release criada

### Exemplo
```
...
jobs:
  check-commit:
    name: Check Commit
    uses: vrsoftbr/reusable-workflows/.github/workflows/check-commit.yml@main
    secrets:
      VRPACKAGETOKEN: ${{ secrets.VRPACKAGETOKEN }} 
...
```

## Chat Notify (chat-notify.yml)
Utilizada para verificar a quantidade de commits que houveram na branch main, desde a última tag/release criada

### Inputs:

- `appName` nome da aplicação que irá enviar a notificação **[obrigatório]**
- `hasCommit` informa se houveram commits desde a última tag/release criada **[obrigatório]**
- `hasError` informa se algum erro ocorreu durante o processo **[obrigatório]**

### Exemplo
```
...
jobs:
  notify:
    name: Notify
    uses: vrsoftbr/reusable-workflows/.github/workflows/chat-notify.yml@main
    if: ${{ always() }}
    needs: [check-commit, build-api]
    with:
      appName: VRFinanceiroWeb
      hasCommit: ${{needs.check-commit.outputs.exist == 'true'}}
      hasError: ${{needs.build-api.outputs.status != 'success'}}
...
```


