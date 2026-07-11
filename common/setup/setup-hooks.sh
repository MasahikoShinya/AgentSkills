#!/usr/bin/env bash
set -euo pipefail

force=0
if (($# > 1)); then
  echo "Usage: $0 [--force]" >&2
  exit 2
fi
if (($# == 1)); then
  if [[ "$1" != "--force" ]]; then
    echo "Usage: $0 [--force]" >&2
    exit 2
  fi
  force=1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
SCRIPT_DIR_PHYSICAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
KIT_ROOT_PHYSICAL="$(cd "$SCRIPT_DIR_PHYSICAL/.." && pwd -P)"

case "${BASH_SOURCE[0]}" in
  *"/.agentskills/setup/setup-hooks.sh"|.agentskills/setup/setup-hooks.sh)
    hooks_path=".agentskills/hooks"
    ;;
  *"/common/setup/setup-hooks.sh"|common/setup/setup-hooks.sh)
    hooks_path="common/hooks"
    ;;
  *)
    echo "[AgentSkills][SETUP][FAIL] Cannot determine logical kit path" >&2
    echo "Run the script through common/setup/setup-hooks.sh or .agentskills/setup/setup-hooks.sh." >&2
    exit 2
    ;;
esac

echo "[AgentSkills][SETUP][START] Git hooks"
echo "Repository: $REPO_ROOT"
echo "Kit root: $KIT_ROOT_PHYSICAL"
echo "Requested core.hooksPath: $hooks_path"

current="$(git config --local --get core.hooksPath || true)"
echo "Current core.hooksPath: ${current:-<unset>}"

if [[ -n "$current" && "$current" != "$hooks_path" ]]; then
  if ((force == 0)); then
    echo "[AgentSkills][SETUP][BLOCKER] Existing core.hooksPath detected" >&2
    echo "Current: $current" >&2
    echo "Requested: $hooks_path" >&2
    echo "No changes were made." >&2
    echo "To replace it intentionally:" >&2
    echo "  bash ${BASH_SOURCE[0]} --force" >&2
    echo "To integrate manually, call the gate from the existing pre-commit hook:" >&2
    echo "  $hooks_path/../gates/pre-commit-gate.sh" >&2
    exit 1
  fi

  git config --local agentskills.previousHooksPath "$current"
  echo "[AgentSkills][SETUP][WARNING] Replacing existing core.hooksPath"
  echo "Previous: $current"
  echo "Restore with: git config --local core.hooksPath $(printf '%q' "$current")"
fi

chmod +x "$KIT_ROOT_PHYSICAL"/hooks/*
chmod +x "$KIT_ROOT_PHYSICAL"/gates/*.sh
chmod +x "$KIT_ROOT_PHYSICAL"/reviewers/*.sh
chmod +x "$KIT_ROOT_PHYSICAL"/setup/*.sh

git config --local core.hooksPath "$hooks_path"

echo "[AgentSkills][SETUP][PASS] Git hooks installed"
echo "core.hooksPath=$(git config --local --get core.hooksPath)"
echo "Protected push branches:"
mapfile -t protected < <(git config --local --get-all agentskills.protectedPushBranch || true)
if ((${#protected[@]} == 0)); then
  echo "  main (default)"
  echo "  master (default)"
else
  printf '  %s\n' "${protected[@]}"
fi
