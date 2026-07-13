#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/review-common.sh
source "$KIT_ROOT/lib/review-common.sh"

echo "[AgentSkills][CHECK][START] diff-basic"
agentskills_collect_staged_risk 2147483647 2147483647
if ((${#AGENTSKILLS_STAGED_PATHS[@]} == 0)); then
  echo "[AgentSkills][CHECK][SKIP] diff-basic"
  echo "Reason: No staged files."
  exit 0
fi

echo "Staged files:"
printf '  %s\n' "${AGENTSKILLS_STAGED_PATHS[@]}"

warning_files=()
for path in "${AGENTSKILLS_STAGED_PATHS[@]}"; do
  if agentskills_is_risk_path "$path"; then
    lower="$(printf '%s' "$path" | tr '[:upper:]' '[:lower:]')"
    if [[ "$lower" =~ (^|/)(test|tests|spec|specs|__tests__)(/|$) ||
          "$lower" =~ \.(test|spec)\.[^.]+$ ]]; then
      warning_files+=("$path")
    fi
  fi
done

if ((${#warning_files[@]} > 0)); then
  echo "[AgentSkills][CHECK][WARNING] diff-basic"
  echo "Test or spec files changed:"
  printf '  %s\n' "${warning_files[@]}"
  echo "Reason: Test changes may be valid under TDD, but expectations require review."
else
  echo "[AgentSkills][CHECK][PASS] diff-basic"
fi
