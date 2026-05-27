#!/usr/bin/env bash
# Extrai chave Jira (padrão [A-Z][A-Z0-9]+-[0-9]+, ex.: PPV-123, ARQ-198)
# do título e da branch do PR. Pega o primeiro match.
#
# Env vars obrigatórias:
#   PR_TITLE        - título do PR (geralmente github.event.pull_request.title)
#   PR_BRANCH       - branch head do PR (geralmente github.event.pull_request.head.ref)
#   GITHUB_OUTPUT   - injetado pelo runner do GitHub Actions
#
# Recebe título/branch via env var (não interpolados direto no script) para evitar
# injection caso título contenha caracteres especiais ($, `, ;, etc.).
#
# Outputs anexados ao $GITHUB_OUTPUT:
#   key         - chave detectada (vazio se nenhuma)
#   has_ticket  - "true" se detectada, "false" caso contrário

set -euo pipefail

: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"
PR_TITLE="${PR_TITLE:-}"
PR_BRANCH="${PR_BRANCH:-}"

KEY=$(printf '%s %s' "$PR_TITLE" "$PR_BRANCH" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -n1 || true)

if [ -n "$KEY" ]; then
  echo "Chave Jira detectada: $KEY"
  echo "key=$KEY" >> "$GITHUB_OUTPUT"
  echo "has_ticket=true" >> "$GITHUB_OUTPUT"
else
  echo "Nenhuma chave Jira encontrada no título/branch."
  echo "key=" >> "$GITHUB_OUTPUT"
  echo "has_ticket=false" >> "$GITHUB_OUTPUT"
fi
