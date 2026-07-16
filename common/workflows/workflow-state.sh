#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <start|advance|show> <resolve|sdd_tdd> [next-phase]" >&2
}

if (($# < 2 || $# > 3)); then
  usage
  exit 2
fi

action="$1"
workflow="$2"
phase="${3:-}"

case "$workflow" in
  resolve|sdd_tdd) ;;
  *)
    echo "[AgentSkills][WORKFLOW-STATE][FAIL] Unknown workflow: $workflow" >&2
    exit 2
    ;;
esac

valid_phase() {
  case "$1:$2" in
    sdd_tdd:spec|sdd_tdd:test|sdd_tdd:implement|sdd_tdd:review|sdd_tdd:gate|sdd_tdd:complete) return 0 ;;
    resolve:inspect|resolve:implement|resolve:verify|resolve:review|resolve:gate|resolve:complete) return 0 ;;
    *) return 1 ;;
  esac
}

if [[ "$action" == "start" ]]; then
  expected_phase="inspect"
  [[ "$workflow" == "sdd_tdd" ]] && expected_phase="spec"
  if [[ "$phase" != "$expected_phase" ]]; then
    echo "[AgentSkills][WORKFLOW-STATE][FAIL] start phase for $workflow must be $expected_phase" >&2
    exit 2
  fi
elif [[ "$action" == "advance" ]]; then
  if [[ -z "$phase" ]] || ! valid_phase "$workflow" "$phase"; then
    echo "[AgentSkills][WORKFLOW-STATE][FAIL] Invalid next phase for $workflow: ${phase:-<missing>}" >&2
    exit 2
  fi
elif [[ "$action" != "show" ]] || [[ -n "$phase" ]]; then
  usage
  exit 2
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
STATE_DIR="$(git rev-parse --git-path agentskills/workflows)"
STATE_FILE="$STATE_DIR/$workflow.state"
INITIAL_STAGED_FILE="$STATE_DIR/$workflow.initial-staged"

hash_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    printf 'missing\n'
    return 0
  fi
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$file" | awk '{print $NF}'
  else
    echo "[AgentSkills][WORKFLOW-STATE][FAIL] sha256sum, shasum, or openssl is required" >&2
    exit 2
  fi
}

state_value() {
  local key="$1"
  awk -F= -v key="$key" '$1 == key { print substr($0, length(key) + 2); exit }' "$STATE_FILE"
}

validate_state_workflow() {
  if [[ "$(state_value workflow)" != "$workflow" ]]; then
    echo "[AgentSkills][WORKFLOW-STATE][BLOCKER] Workflow state does not match the requested command" >&2
    exit 1
  fi
}

write_state() {
  local next_phase="$1"
  local initial_file="$2"
  local temporary
  temporary="$STATE_FILE.tmp.$$"
  {
    printf 'schema=1\n'
    printf 'workflow=%s\n' "$workflow"
    printf 'next_phase=%s\n' "$next_phase"
    printf 'head=%s\n' "$(git rev-parse HEAD)"
    printf 'brief_hash=%s\n' "$(hash_file "$REPO_ROOT/SESSION_BRIEF.md")"
    printf 'initial_staged_file=%s\n' "$initial_file"
    printf 'recorded_at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  } >"$temporary"
  mv "$temporary" "$STATE_FILE"
}

case "$action" in
  start)
    mkdir -p "$STATE_DIR"
    git diff --cached --name-only --no-ext-diff >"$INITIAL_STAGED_FILE"
    write_state "$phase" "$INITIAL_STAGED_FILE"
    echo "[AgentSkills][WORKFLOW-STATE][PASS] started $workflow"
    echo "Next phase: $phase"
    echo "State: $STATE_FILE"
    echo "Initial staged paths: $INITIAL_STAGED_FILE"
    ;;
  advance)
    if [[ ! -f "$STATE_FILE" ]]; then
      echo "[AgentSkills][WORKFLOW-STATE][BLOCKER] No resumable $workflow workflow state" >&2
      echo "Start a new workflow with the matching pseudo-command, or inspect the requested phase manually." >&2
      exit 1
    fi
    validate_state_workflow
    write_state "$phase" "$(state_value initial_staged_file)"
    echo "[AgentSkills][WORKFLOW-STATE][PASS] advanced $workflow"
    echo "Next phase: $phase"
    echo "State: $STATE_FILE"
    ;;
  show)
    if [[ ! -f "$STATE_FILE" ]]; then
      echo "[AgentSkills][WORKFLOW-STATE][BLOCKER] No resumable $workflow workflow state" >&2
      echo "Use ::$workflow --auto <request> to start a new workflow." >&2
      exit 1
    fi
    validate_state_workflow
    stored_brief_hash="$(state_value brief_hash)"
    current_brief_hash="$(hash_file "$REPO_ROOT/SESSION_BRIEF.md")"
    if [[ "$stored_brief_hash" != "$current_brief_hash" ]]; then
      echo "[AgentSkills][WORKFLOW-STATE][BLOCKER] SESSION_BRIEF.md changed after the recorded phase" >&2
      echo "Recorded hash: $stored_brief_hash" >&2
      echo "Current hash: $current_brief_hash" >&2
      echo "Inspect and reconcile the brief before resuming." >&2
      exit 1
    fi
    echo "[AgentSkills][WORKFLOW-STATE][PASS] resumable $workflow workflow"
    echo "Next phase: $(state_value next_phase)"
    echo "Recorded head: $(state_value head)"
    echo "State: $STATE_FILE"
    echo "Initial staged paths: $(state_value initial_staged_file)"
    if [[ -s "$(state_value initial_staged_file)" ]]; then
      sed 's/^/  /' "$(state_value initial_staged_file)"
    else
      echo "  <none>"
    fi
    ;;
esac
