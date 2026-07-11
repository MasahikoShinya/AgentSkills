#!/usr/bin/env bash
set -euo pipefail

echo "[AgentSkills][CHECK][START] diff-basic"

mapfile -d '' staged_files < <(git diff --cached --name-only --diff-filter=ACMR -z)
if ((${#staged_files[@]} == 0)); then
  echo "[AgentSkills][CHECK][SKIP] diff-basic"
  echo "Reason: No staged files."
  exit 0
fi

echo "Staged files:"
printf '  %s\n' "${staged_files[@]}"

warning_files=()
for path in "${staged_files[@]}"; do
  lower="${path,,}"
  if [[ "$lower" =~ (^|/)(test|tests|spec|specs|__tests__)(/|$) ||
        "$lower" =~ \.(test|spec)\.[^.]+$ ]]; then
    warning_files+=("$path")
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
