# Reusable Workflows

Repositório utilizado para criação de Workflows Actions reutilizáveis e composite actions compartilhadas pela organização.

## Composite Actions

Diferente das reusable workflows abaixo (consumidas a nível de **job** via `uses:` no `jobs:`), composite actions são consumidas a nível de **step** dentro de um job existente.

### Bucket Publish JAR ([bucket-publish-jar](./bucket-publish-jar))
Publica um JAR em um ou mais buckets de Object Storage, gravando a versão como metadado. Implementação atual: OCI Object Storage. Interface provider-agnostic, preparada para futuras migrações de provedor.

Ver [bucket-publish-jar/README.md](./bucket-publish-jar/README.md) para detalhes de uso, inputs e formato do secret `BUCKET_PUBLISH_CREDENTIALS`.

---

## Reusable Workflows

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

## Claude PR Review (claude-review.yml)
Executa code review automático em PRs usando o Claude (via plano OAuth, sem API key). Carrega contexto do ticket no Jira via MCP e aplica uma política em camadas mantida em outro repositório ([VRCodeReviewPolicy](https://github.com/vrsoftbr/VRCodeReviewPolicy)).

Política aplicada (concatenada e passada ao Claude como prompt do review), na ordem:
  1. **default** — `instructions/default.md` no repo de policy, sempre aplicada;
  2. **stack** — `instructions/stacks/<stack>.md`, opcional, escolhida via input `stack`;
  3. **projeto** — `instructions/projects/<project>.md`, opcional, escolhida via input `project`.

Camadas mais específicas têm precedência. Como toda policy vive no repo central, alterar regras de qualquer projeto não exige tocar no repo do projeto.

### Inputs:

- `jira_url` URL base do Jira (ex.: `https://vrsoft.atlassian.net`) **[obrigatório]**
- `stack` nome da camada de stack (resolve para `instructions/stacks/<stack>.md`). Vazio = só default
- `project` ID do projeto (resolve para `instructions/projects/<project>.md`). Vazio = sem camada de projeto
- `policy_ref` ref do repo de policy (tag/branch/sha). Default: `main`. Recomenda-se fixar em tag (`v1`)
- `policy_repo` `owner/repo` do repositório de policy. Default: `vrsoftbr/VRCodeReviewPolicy`

### Secrets:

- `CLAUDE_CODE_OAUTH_TOKEN` token OAuth gerado por `claude setup-token` localmente **[obrigatório]**
- `JIRA_USERNAME` e-mail da conta Atlassian **[obrigatório]**
- `JIRA_API_TOKEN` API token criado em `id.atlassian.com/manage-profile/security/api-tokens` **[obrigatório]**
- `POLICY_REPO_TOKEN` PAT/App token com acesso read ao repo de policy. **Opcional** — necessário apenas se o repo de policy for privado e o `GITHUB_TOKEN` padrão não tiver acesso

### Exemplo
```
name: Code review (Claude)

on:
  pull_request:
    types: [opened, synchronize, reopened]

concurrency:
  group: claude-review-${{ github.event.pull_request.number }}
  cancel-in-progress: true

jobs:
  review:
    uses: vrsoftbr/reusable-workflows/.github/workflows/claude-review.yml@main
    with:
      jira_url: https://vrsoft.atlassian.net
      stack: java
      project: vrpdv
      policy_ref: v1
    secrets: inherit
```


