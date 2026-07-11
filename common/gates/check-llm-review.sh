#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "[AgentSkills][CHECK][START] llm-review"

if git diff --cached --quiet --exit-code; then
  echo "[AgentSkills][CHECK][SKIP] llm-review"
  echo "Reason: No staged diff."
  exit 0
fi

if [[ ! -f SESSION_BRIEF.md ]]; then
  echo "[AgentSkills][CHECK][BLOCKER] llm-review" >&2
  echo "Reason: SESSION_BRIEF.md is required for scoped review." >&2
  echo "Resolution:" >&2
  echo "  cp \"$KIT_ROOT/briefs/SESSION_BRIEF.template.md\" SESSION_BRIEF.md" >&2
  exit 1
fi

diff_hash="$(git diff --cached --binary --no-ext-diff | sha256sum | awk '{print $1}')"

if [[ "${AGENTSKILLS_SKIP_LLM_REVIEW:-0}" == "1" ]]; then
  echo "[AgentSkills][LLM-REVIEW][SKIP] staged-diff"
  echo "Reason: AGENTSKILLS_SKIP_LLM_REVIEW=1 was explicitly set."
  echo "Diff hash: $diff_hash"
  echo "Warning: This result is not cached. Mechanical checks still ran."
  exit 0
fi

line_limit="$(git config --local --get agentskills.reviewEscalateLines || true)"
file_limit="$(git config --local --get agentskills.reviewEscalateFiles || true)"
line_limit="${line_limit:-300}"
file_limit="${file_limit:-10}"

changed_files="$(git diff --cached --name-only --diff-filter=ACMR | wc -l | tr -d ' ')"
changed_lines="$(git diff --cached --numstat --diff-filter=ACMR | awk '$1 ~ /^[0-9]+$/ {sum += $1 + $2} END {print sum + 0}')"
escalate=0
reasons=()

if ((changed_lines >= line_limit)); then
  escalate=1
  reasons+=("changed lines: $changed_lines >= $line_limit")
fi
if ((changed_files >= file_limit)); then
  escalate=1
  reasons+=("changed files: $changed_files >= $file_limit")
fi

while IFS= read -r path; do
  lower="${path,,}"
  if [[ "$lower" =~ (^|/)(auth|authentication|authorization|permissions|payments|migrations|infrastructure)(/|$) ||
        "$lower" == .github/workflows/* ||
        "$lower" =~ (^|/)(test|tests|spec|specs|__tests__)(/|$) ||
        "$lower" =~ \.(test|spec)\.[^.]+$ ]]; then
    escalate=1
    reasons+=("risk path: $path")
  fi
done < <(git diff --cached --name-only --diff-filter=ACMR)

echo "Changed files: $changed_files"
echo "Changed lines: $changed_lines"
if ((escalate == 1)); then
  echo "[AgentSkills][MODEL][WARNING] Review escalation"
  printf 'Reason: %s\n' "${reasons[@]}"
fi

set +e
AGENTSKILLS_REVIEW_ESCALATED="$escalate" "$KIT_ROOT/reviewers/review-staged-diff.sh"
rc=$?
set -e

case "$rc" in
  0)
    echo "[AgentSkills][CHECK][PASS] llm-review"
    ;;
  2)
    echo "[AgentSkills][CHECK][BLOCKER] llm-review" >&2
    exit 1
    ;;
  *)
    echo "[AgentSkills][CHECK][FAIL] llm-review" >&2
    echo "" >&2
    echo "Option 1 - Review manually in Claude Code:" >&2
    echo "  @subagent-review SESSION_BRIEF.md and git diff --cached; do not modify code." >&2
    echo "  bash .agentskills/reviewers/record-manual-review.sh --runtime claude --status OK" >&2
    echo "  git commit" >&2
    echo "" >&2
    echo "Option 2 - Skip LLM review once:" >&2
    echo "  AGENTSKILLS_SKIP_LLM_REVIEW=1 git commit" >&2
    echo "" >&2
    echo "Mechanical gate checks will still run." >&2
    exit 1
    ;;
esac
