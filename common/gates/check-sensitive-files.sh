#!/usr/bin/env bash
set -euo pipefail

echo "[AgentSkills][CHECK][START] sensitive-files"

blocked=()
while IFS= read -r -d '' path; do
  base="${path##*/}"

  case "$base" in
    .env.example|.env.sample|.env.template)
      continue
      ;;
  esac

  if [[ "$base" == ".env" || "$base" == .env.* ||
        "$base" == *.pem || "$base" == *.key ||
        "$base" == *.p12 || "$base" == *.pfx ||
        "/$path/" == *"/secrets/"* ]]; then
    blocked+=("$path")
  fi
done < <(git diff --cached --name-only --diff-filter=ACMR -z)

if ((${#blocked[@]} > 0)); then
  echo "[AgentSkills][CHECK][BLOCKER] sensitive-files" >&2
  echo "Blocked files:" >&2
  printf '  %s\n' "${blocked[@]}" >&2
  echo "Reason: Sensitive files must not be committed." >&2
  echo "Resolution:" >&2
  printf '  git restore --staged --' >&2
  printf ' %q' "${blocked[@]}" >&2
  printf '\n' >&2
  echo "The files remain in the working tree." >&2
  exit 1
fi

echo "[AgentSkills][CHECK][PASS] sensitive-files"
