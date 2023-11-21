# Reusable Workflows

Repositório utilizado para criação de Workflows Actions reutilizáveis

## Check Commit (check-commit.yml)
Utilizada para verificar a quantidade de commits que houveram na branch main, desde a última tag/release criada

### Secrets:

- `VRPACKAGETOKEN` token de usuário do GitHub **[obrigatório]**

### Inputs:

- `byPass` força um retorno `true` no output `exist`. Não afeta o output `count`

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
Utilizada para notificar no Google Chat, no Space: **Célula Web + Jira + GitHub** mensagens personalizadas

### Inputs:

- `appName` nome da aplicação que irá enviar a notificação **[obrigatório]**
- `mensagem` informa o conteúdo da mensagem **[obrigatório]**
- `problem` informa se é uma mensagem comum (`false`), ou um aviso sobre problema (`true`) **[obrigatório]**

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
      mensagem: Concluída Build e Deploy Realizado
      hasError: false
...
```

## Chat Notify Deploy (chat-notify-deploy.yml)
Utilizada para notificar no Google Chat, no Space: **Célula Web + Jira + GitHub** sobre novos deploys

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
    uses: vrsoftbr/reusable-workflows/.github/workflows/chat-notify-deploy.yml@main
    if: ${{ always() }}
    needs: [check-commit, build-api]
    with:
      appName: VRFinanceiroWeb
      hasCommit: ${{needs.check-commit.outputs.exist == 'true'}}
      hasError: ${{needs.build-api.outputs.status != 'success'}}
...
```

## Create Release (create-release.yml)
Utilizada para criação de uma Release/Tag de uma nova versão, e também para criação do arquivo CHANGELOG.md

A release sempre é criada com o nome da versão informada, e a tag contem um `v` no inicio. Exemplo: Release 4.0.0, Tag v4.0.0.

As regras de criação do conteúdo do arquivo CHANGELOG.md são:
  - os commits deverão ter como título três caractéres, um traço, e um numero inteiro. Exemplo: WEB-123;
  - será adicionado no arquivo somente o conteúdo que estiver entre as tags `<RNB>` e `<RNF>`;
    - o conteúdo entre as tags `<RNB>` serão adicionados na seção "Correções";
    - o conteúdo entre as tags `<RNF>` serão adicionados na seção "Novos Recursos";
  - quando não houverem commits as tags nos commits, o texto "Melhorias de performance e correções diversas" será adicionado ao arquivo;

### Inputs:

- `versao` nome da release que será criada **[obrigatório]**

### Outputs:

- `status` retorna o status da execução do workflow

### Exemplo
```
...
jobs:
  create-release:
    name: Create Release/Tag and CHANGELOG.md
    needs: upgrade-version-and-build
    uses: vrsoftbr/reusable-workflows/.github/workflows/create-release.yml@main
    with:
      versao: ${{needs.upgrade-version-and-build.outputs.versao}}
    secrets:
      VRPACKAGETOKEN: ${{ secrets.VRPACKAGETOKEN }}
...
```


