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

case "$branch" in
  feature/*|fix/*|hotfix/*|chore/*|docs/*|refactor/*)
    printf '%s\n' 'develop'
    ;;
  develop|main)
    echo "[AgentSkills][PUBLISH][BLOCKER] Publish from '$branch' is not allowed; create a work branch and target develop" >&2
    exit 1
    ;;
  *)
    echo "[AgentSkills][PUBLISH][BLOCKER] No PR base is defined for branch '$branch'. Use a recognized work-branch prefix that targets develop" >&2
    exit 1
    ;;
esac
