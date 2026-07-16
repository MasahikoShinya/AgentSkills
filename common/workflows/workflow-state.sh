#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 start <resolve|sdd_tdd> <initial-phase> <request>" >&2
  echo "       $0 advance <resolve|sdd_tdd> <next-phase>" >&2
  echo "       $0 show <resolve|sdd_tdd> <request>" >&2
}

action="$1"
workflow="${2:-}"
phase="${3:-}"
request="${4:-}"

case "$action" in
  start)
    [[ $# == 4 ]] || { usage; exit 2; }
    ;;
  advance)
    [[ $# == 3 ]] || { usage; exit 2; }
    ;;
  show)
    [[ $# == 3 ]] || { usage; exit 2; }
    request="$phase"
    phase=""
    ;;
  *)
    usage
    exit 2
    ;;
esac

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

expected_next_phase() {
  case "$1:$2" in
    sdd_tdd:spec) printf 'test\n' ;;
    sdd_tdd:test) printf 'implement\n' ;;
    sdd_tdd:implement) printf 'review\n' ;;
    sdd_tdd:review) printf 'gate\n' ;;
    sdd_tdd:gate) printf 'complete\n' ;;
    resolve:inspect) printf 'implement\n' ;;
    resolve:implement) printf 'verify\n' ;;
    resolve:verify) printf 'review\n' ;;
    resolve:review) printf 'gate\n' ;;
    resolve:gate) printf 'complete\n' ;;
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

hash_text() {
  local value="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$value" | sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    printf '%s' "$value" | shasum -a 256 | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    printf '%s' "$value" | openssl dgst -sha256 | awk '{print $NF}'
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

validate_resumable_phase() {
  local recorded_phase
  recorded_phase="$(state_value next_phase)"
  if ! valid_phase "$workflow" "$recorded_phase"; then
    echo "[AgentSkills][WORKFLOW-STATE][BLOCKER] Workflow state has an invalid next phase: ${recorded_phase:-<missing>}" >&2
    exit 1
  fi
  printf '%s\n' "$recorded_phase"
}

validate_request_match() {
  local stored_request_hash current_request_hash
  stored_request_hash="$(state_value request_hash)"
  current_request_hash="$(hash_text "$request")"
  if [[ -z "$stored_request_hash" || "$stored_request_hash" != "$current_request_hash" ]]; then
    echo "[AgentSkills][WORKFLOW-STATE][BLOCKER] Workflow state does not match the requested work" >&2
    echo "Reason: An unfinished workflow can resume only with its original request text." >&2
    echo "Resolution: Continue the active request, or resolve its state before starting different work." >&2
    exit 1
  fi
}

write_state() {
  local next_phase="$1"
  local initial_file="$2"
  local request_hash="$3"
  local temporary
  temporary="$STATE_FILE.tmp.$$"
  {
    printf 'schema=1\n'
    printf 'workflow=%s\n' "$workflow"
    printf 'next_phase=%s\n' "$next_phase"
    printf 'head=%s\n' "$(git rev-parse HEAD)"
    printf 'brief_hash=%s\n' "$(hash_file "$REPO_ROOT/SESSION_BRIEF.md")"
    printf 'request_hash=%s\n' "$request_hash"
    printf 'initial_staged_file=%s\n' "$initial_file"
    printf 'recorded_at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  } >"$temporary"
  mv "$temporary" "$STATE_FILE"
}

case "$action" in
  start)
    mkdir -p "$STATE_DIR"
    if [[ -f "$STATE_FILE" ]]; then
      validate_state_workflow
      recorded_phase="$(validate_resumable_phase)"
      if [[ "$recorded_phase" != "complete" ]]; then
        echo "[AgentSkills][WORKFLOW-STATE][BLOCKER] Unfinished $workflow workflow state already exists" >&2
        echo "Run ::$workflow <request> to continue from its recorded next phase." >&2
        exit 1
      fi
    fi
    git diff --cached --name-only --no-ext-diff >"$INITIAL_STAGED_FILE"
    write_state "$phase" "$INITIAL_STAGED_FILE" "$(hash_text "$request")"
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
    recorded_phase="$(validate_resumable_phase)"
    expected_phase="$(expected_next_phase "$workflow" "$recorded_phase" || true)"
    if [[ -z "$expected_phase" ]]; then
      echo "[AgentSkills][WORKFLOW-STATE][BLOCKER] $workflow is already complete; start a new workflow instead of advancing it" >&2
      exit 1
    fi
    if [[ "$phase" != "$expected_phase" ]]; then
      echo "[AgentSkills][WORKFLOW-STATE][BLOCKER] $workflow must advance from $recorded_phase to $expected_phase, not $phase" >&2
      exit 1
    fi
    write_state "$phase" "$(state_value initial_staged_file)" "$(state_value request_hash)"
    echo "[AgentSkills][WORKFLOW-STATE][PASS] advanced $workflow"
    echo "Next phase: $phase"
    echo "State: $STATE_FILE"
    ;;
  show)
    if [[ ! -f "$STATE_FILE" ]]; then
      echo "[AgentSkills][WORKFLOW-STATE][BLOCKER] No resumable $workflow workflow state" >&2
      echo "Use ::$workflow <request> to start a new workflow." >&2
      exit 1
    fi
    validate_state_workflow
    recorded_phase="$(validate_resumable_phase)"
    if [[ "$recorded_phase" == "complete" ]]; then
      echo "[AgentSkills][WORKFLOW-STATE][BLOCKER] $workflow is already complete" >&2
      echo "Start a new workflow with ::$workflow <request>." >&2
      exit 1
    fi
    validate_request_match
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
