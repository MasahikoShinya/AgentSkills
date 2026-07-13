#!/usr/bin/env bash
set -euo pipefail

if (($# > 1)); then
  echo "Usage: $0 [<PR-number-or-URL>]" >&2
  exit 2
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "[AgentSkills][PR-REVIEW][FAIL] GitHub CLI not found" >&2
  echo "Reason: @pr-review requires authenticated gh access to inspect PR metadata and diff." >&2
  exit 3
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "[AgentSkills][PR-REVIEW][FAIL] jq not found" >&2
  exit 3
fi

pr_ref="${1:-}"
view_args=(pr view)
[[ -n "$pr_ref" ]] && view_args+=("$pr_ref")
view_args+=(--json number,url,title,state,isDraft,baseRefName,headRefName,mergeable,mergeStateStatus,reviewDecision)

metadata="$(gh "${view_args[@]}")"
number="$(jq -r '.number' <<<"$metadata")"
url="$(jq -r '.url' <<<"$metadata")"

echo "[AgentSkills][PR-REVIEW][START] #$number"
echo "URL: $url"
echo "Title: $(jq -r '.title' <<<"$metadata")"
echo "State: $(jq -r '.state' <<<"$metadata")"
echo "Draft: $(jq -r '.isDraft' <<<"$metadata")"
echo "Base: $(jq -r '.baseRefName' <<<"$metadata")"
echo "Head: $(jq -r '.headRefName' <<<"$metadata")"
echo "Mergeable: $(jq -r '.mergeable' <<<"$metadata")"
echo "Merge state: $(jq -r '.mergeStateStatus' <<<"$metadata")"
echo "Review decision: $(jq -r 'if .reviewDecision == null or .reviewDecision == "" then "none" else .reviewDecision end' <<<"$metadata")"

set +e
checks="$(gh pr checks "$number" 2>&1)"
checks_rc=$?
set -e
if ((checks_rc == 0)); then
  echo "[AgentSkills][PR-REVIEW][PASS] checks"
elif [[ "$checks" == *"no checks reported"* ]]; then
  echo "[AgentSkills][PR-REVIEW][SKIP] checks"
  echo "Reason: No checks are configured for this PR branch."
else
  echo "[AgentSkills][PR-REVIEW][WARNING] checks"
fi
printf '%s\n' "$checks"

echo "Changed files:"
gh pr diff "$number" --name-only
echo "Review diff with: gh pr diff $number"
echo "[AgentSkills][PR-REVIEW][PASS] inspection"
