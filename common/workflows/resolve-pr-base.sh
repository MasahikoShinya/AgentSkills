#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [branch-name]" >&2
}

if [[ $# -gt 1 ]]; then
  usage
  exit 2
fi

branch="${1:-$(git branch --show-current)}"
if [[ -z "$branch" ]]; then
  echo "[AgentSkills][PUBLISH][BLOCKER] A checked-out branch is required to determine the PR base" >&2
  exit 1
fi

configured_base="$(git config --get "branch.${branch}.agentskills-pr-base" || true)"
if [[ -n "$configured_base" ]]; then
  printf '%s\n' "$configured_base"
  exit 0
fi

case "$branch" in
  develop)
    printf '%s\n' 'main'
    ;;
  feature/*|fix/*|hotfix/*|chore/*|docs/*|refactor/*)
    printf '%s\n' 'develop'
    ;;
  main)
    echo "[AgentSkills][PUBLISH][BLOCKER] Publish from main is not allowed; create a release PR from develop instead" >&2
    exit 1
    ;;
  *)
    echo "[AgentSkills][PUBLISH][BLOCKER] No PR base is defined for branch '$branch'. Use a recognized work-branch prefix or set branch.${branch}.agentskills-pr-base" >&2
    exit 1
    ;;
esac
