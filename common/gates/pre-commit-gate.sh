#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "[AgentSkills][GATE][START] pre-commit-gate"

echo "[AgentSkills][CHECK][START] whitespace"
if git diff --cached --check; then
  echo "[AgentSkills][CHECK][PASS] whitespace"
else
  echo "[AgentSkills][CHECK][BLOCKER] whitespace" >&2
  echo "Reason: git diff --cached --check found whitespace errors." >&2
  exit 1
fi

"$SCRIPT_DIR/check-sensitive-files.sh"
"$SCRIPT_DIR/check-large-files.sh"
"$SCRIPT_DIR/check-diff-basic.sh"
"$SCRIPT_DIR/check-llm-review.sh"

echo "[AgentSkills][GATE][PASS] pre-commit-gate"
