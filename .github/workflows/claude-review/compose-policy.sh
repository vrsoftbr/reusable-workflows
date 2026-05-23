#!/usr/bin/env bash
# Compõe o arquivo de política de review em camadas (default + stack opcional + projeto opcional)
# a partir do checkout do repo de policy.
#
# Env vars obrigatórias:
#   POLICY_DIR   - caminho do checkout do repo de policy (ex.: .claude-review-policy)
#   OUT_FILE     - arquivo de saída (ex.: .claude/review-policy.md)
#   POLICY_REPO  - "owner/repo" do repo de policy, usado em mensagens de erro
#   POLICY_REF   - ref (tag/branch/sha) do repo de policy, usado em mensagens de erro
#   GITHUB_OUTPUT - injetado pelo runner do GitHub Actions
#
# Env vars opcionais:
#   STACK        - id da stack; carrega instructions/stacks/$STACK.md
#   PROJECT      - id do projeto; carrega instructions/projects/$PROJECT.md
#
# Outputs:
#   Escreve o conteúdo composto em $OUT_FILE.
#   Anexa `applied=<camadas separadas por vírgula>` ao $GITHUB_OUTPUT.

set -euo pipefail

: "${POLICY_DIR:?POLICY_DIR is required}"
: "${OUT_FILE:?OUT_FILE is required}"
: "${POLICY_REPO:?POLICY_REPO is required}"
: "${POLICY_REF:?POLICY_REF is required}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"
STACK="${STACK:-}"
PROJECT="${PROJECT:-}"

mkdir -p "$(dirname "$OUT_FILE")"

DEFAULT_FILE="$POLICY_DIR/instructions/default.md"
if [ ! -f "$DEFAULT_FILE" ]; then
  echo "::error::Política padrão não encontrada em $DEFAULT_FILE — repo de policy correto? (${POLICY_REPO}@${POLICY_REF})"
  exit 1
fi

{
  echo "# Política composta de code review"
  echo ""
  echo "Esta política foi composta em camadas. Camadas mais específicas (declaradas mais abaixo)"
  echo "têm precedência sobre as mais gerais quando houver conflito explícito."
  echo ""
  echo "---"
  echo ""
  echo "## Camada 1 — Política padrão"
  echo ""
  cat "$DEFAULT_FILE"
} > "$OUT_FILE"

APPLIED="default"

if [ -n "$STACK" ]; then
  STACK_FILE="$POLICY_DIR/instructions/stacks/${STACK}.md"
  if [ -f "$STACK_FILE" ]; then
    {
      echo ""
      echo "---"
      echo ""
      echo "## Camada 2 — Stack: ${STACK}"
      echo ""
      cat "$STACK_FILE"
    } >> "$OUT_FILE"
    APPLIED="${APPLIED}, stack:${STACK}"
  else
    echo "::warning::Stack '${STACK}' declarada mas $STACK_FILE não existe — ignorada."
  fi
fi

if [ -n "$PROJECT" ]; then
  PROJECT_FILE="$POLICY_DIR/instructions/projects/${PROJECT}.md"
  if [ -f "$PROJECT_FILE" ]; then
    {
      echo ""
      echo "---"
      echo ""
      echo "## Camada 3 — Projeto: ${PROJECT} (precedência máxima)"
      echo ""
      cat "$PROJECT_FILE"
    } >> "$OUT_FILE"
    APPLIED="${APPLIED}, projeto:${PROJECT}"
  else
    echo "::warning::Projeto '${PROJECT}' declarado mas $PROJECT_FILE não existe — ignorado."
  fi
fi

echo "applied=${APPLIED}" >> "$GITHUB_OUTPUT"
echo "## Camadas aplicadas: ${APPLIED}"
echo "----- início da política composta -----"
cat "$OUT_FILE"
echo "----- fim da política composta -----"
