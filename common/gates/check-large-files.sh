#!/usr/bin/env bash
set -euo pipefail

MAX_FILE_SIZE_BYTES="${AGENTSKILLS_MAX_FILE_SIZE_BYTES:-5242880}"
echo "[AgentSkills][CHECK][START] large-files"
echo "Limit: ${MAX_FILE_SIZE_BYTES} bytes"

blocked_paths=()
blocked_sizes=()

while IFS= read -r -d '' path; do
  if ! size="$(git cat-file -s ":$path" 2>/dev/null)"; then
    continue
  fi
  if ((size > MAX_FILE_SIZE_BYTES)); then
    blocked_paths+=("$path")
    blocked_sizes+=("$size")
  fi
done < <(git diff --cached --name-only --diff-filter=ACMR -z)

if ((${#blocked_paths[@]} > 0)); then
  echo "[AgentSkills][CHECK][BLOCKER] large-files" >&2
  for i in "${!blocked_paths[@]}"; do
    echo "File: ${blocked_paths[$i]}" >&2
    echo "Size: ${blocked_sizes[$i]} bytes" >&2
    echo "Limit: ${MAX_FILE_SIZE_BYTES} bytes" >&2
  done
  echo "Reason: One or more staged files exceed the configured size limit." >&2
  echo "Resolution:" >&2
  printf '  git restore --staged --' >&2
  printf ' %q' "${blocked_paths[@]}" >&2
  printf '\n' >&2
  exit 1
fi

echo "[AgentSkills][CHECK][PASS] large-files"
