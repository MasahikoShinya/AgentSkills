#!/usr/bin/env bash
set -euo pipefail

runtime=""
status=""
while (($# > 0)); do
  case "$1" in
    --runtime)
      runtime="${2:-}"
      shift 2
      ;;
    --status)
      status="${2:-}"
      shift 2
      ;;
    *)
      echo "Usage: $0 --runtime <name> --status OK" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$runtime" || "$status" != "OK" ]]; then
  echo "[AgentSkills][MANUAL-REVIEW][BLOCKER] Invalid attestation" >&2
  echo "Usage: $0 --runtime <name> --status OK" >&2
  exit 2
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if [[ ! -f SESSION_BRIEF.md ]]; then
  echo "[AgentSkills][MANUAL-REVIEW][BLOCKER] SESSION_BRIEF.md not found" >&2
  exit 2
fi
if git diff --cached --quiet --exit-code; then
  echo "[AgentSkills][MANUAL-REVIEW][BLOCKER] No staged diff" >&2
  exit 2
fi

diff_hash="$(git diff --cached --binary --no-ext-diff | sha256sum | awk '{print $1}')"
cache_dir="$(git rev-parse --git-path agentskills/reviews)"
cache_file="$cache_dir/$diff_hash.json"
mkdir -p "$cache_dir"

jq -n \
  --arg model "manual:$runtime" \
  --arg hash "$diff_hash" \
  '{
    status: "OK",
    summary: ("Manual independent review attested for staged diff " + $hash),
    model: $model,
    escalate: false,
    findings: []
  }' >"$cache_file"

echo "[AgentSkills][MANUAL-REVIEW][PASS] staged-diff"
echo "Runtime: $runtime"
echo "Diff hash: $diff_hash"
echo "Recorded: $cache_file"
