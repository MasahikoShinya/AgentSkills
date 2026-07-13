#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_COMMON="$(cd "$TEST_DIR/.." && pwd)"
ORIGINAL_PATH="$PATH"
PASS_COUNT=0
FAIL_COUNT=0
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf 'ok %d - %s\n' "$PASS_COUNT" "$1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf 'not ok - %s\n' "$1" >&2
}

assert_contains() {
  local value="$1"
  local expected="$2"
  local label="$3"
  if [[ "$value" == *"$expected"* ]]; then
    pass "$label"
  else
    fail "$label (missing: $expected)"
  fi
}

new_repo() {
  local repo
  repo="$(mktemp -d "$TEST_ROOT/repo.XXXXXX")"
  git -C "$repo" init -q
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name AgentSkillsTest
  cp -R "$SOURCE_COMMON" "$repo/common"
  printf '# Rules\n' >"$repo/AGENTS.md"
  printf '# Brief\nConfirmed scope.\n' >"$repo/SESSION_BRIEF.md"
  cat >"$repo/AGENT_MODELS.md" <<'EOF'
| Runtime | A | B | C | Review | Escalation |
| Codex | - | - | - | test-review | test-escalation |
EOF
  printf 'base\n' >"$repo/app.txt"
  git -C "$repo" add .
  git -C "$repo" commit -qm baseline
  printf '%s\n' "$repo"
}

make_fake_codex() {
  local repo="$1"
  mkdir -p "$repo/fake-bin"
  cat >"$repo/fake-bin/codex" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
output=""
while (($# > 0)); do
  if [[ "$1" == "--output-last-message" ]]; then
    output="$2"
    shift 2
  else
    shift
  fi
done
if [[ -n "${FAKE_CODEX_DELAY_SECONDS:-}" ]]; then
  /bin/sleep "$FAKE_CODEX_DELAY_SECONDS"
fi
printf '%s\n' "$FAKE_CODEX_RESULT" >"$output"
EOF
  chmod +x "$repo/fake-bin/codex"
}

make_tracked_sleep() {
  local repo="$1"
  cat >"$repo/fake-bin/sleep" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$$" >"$FAKE_SLEEP_PID_FILE"
exec /bin/sleep "$@"
EOF
  chmod +x "$repo/fake-bin/sleep"
}

make_stubborn_codex() {
  local repo="$1"
  mkdir -p "$repo/fake-bin"
  cat >"$repo/fake-bin/codex" <<'EOF'
#!/usr/bin/env bash
trap '' TERM
while :; do :; done
EOF
  chmod +x "$repo/fake-bin/codex"
}

run_reviewer_with_result() {
  local repo="$1"
  local result="$2"
  local output_file="$repo/reviewer.out"
  make_fake_codex "$repo"
  set +e
  (cd "$repo" && PATH="$repo/fake-bin:$ORIGINAL_PATH" FAKE_CODEX_RESULT="$result" common/reviewers/review-staged-diff.sh) >"$output_file" 2>&1
  TEST_RC=$?
  set -e
  TEST_OUTPUT="$(cat "$output_file")"
}

test_status_consistency() {
  local repo result
  repo="$(new_repo)"
  printf 'change\n' >>"$repo/app.txt"
  git -C "$repo" add app.txt
  result='{"status":"OK","summary":"wrong","model":"test","escalate":false,"findings":[{"severity":"BLOCKER","category":"regression","file":"app.txt","line":1,"evidence":"changed","finding":"breaks","reason":"regression","recommendation":"fix"}]}'
  run_reviewer_with_result "$repo" "$result"
  [[ "$TEST_RC" == "3" ]] && pass "status/finding contradiction is rejected" || fail "status/finding contradiction is rejected"
  assert_contains "$TEST_OUTPUT" "Invalid or inconsistent reviewer JSON" "contradiction reason is visible"
}

test_evidence_required() {
  local repo result
  repo="$(new_repo)"
  printf 'change\n' >>"$repo/app.txt"
  git -C "$repo" add app.txt
  result='{"status":"WARNING","summary":"missing evidence","model":"test","escalate":false,"findings":[{"severity":"WARNING","category":"other","file":"app.txt","line":1,"finding":"unclear","reason":"missing","recommendation":"inspect"}]}'
  run_reviewer_with_result "$repo" "$result"
  [[ "$TEST_RC" == "3" ]] && pass "finding without evidence is rejected" || fail "finding without evidence is rejected"
}

test_manual_cache_and_invalidation() {
  local repo output rc
  repo="$(new_repo)"
  printf 'change\n' >>"$repo/app.txt"
  git -C "$repo" add app.txt
  (cd "$repo" && common/reviewers/record-manual-review.sh --runtime claude --status OK) >/dev/null
  set +e
  output="$(cd "$repo" && PATH="/usr/bin:/bin" common/reviewers/review-staged-diff.sh 2>&1)"
  rc=$?
  set -e
  [[ "$rc" == "0" ]] && pass "manual cache works without Codex" || fail "manual cache works without Codex"
  assert_contains "$output" "Cached: true" "manual cache use is visible"

  printf 'Changed confirmed scope.\n' >>"$repo/SESSION_BRIEF.md"
  set +e
  output="$(cd "$repo" && PATH="/usr/bin:/bin" common/reviewers/review-staged-diff.sh 2>&1)"
  rc=$?
  set -e
  [[ "$rc" == "3" ]] && pass "brief change invalidates manual cache" || fail "brief change invalidates manual cache"
  assert_contains "$output" "no valid manual review" "invalidated cache explains Codex fallback"
}

test_staged_path_parsing() {
  local repo output unusual_path
  repo="$(new_repo)"
  mkdir -p "$repo/tests"
  printf 'test\n' >"$repo/tests/old.test.js"
  git -C "$repo" add tests/old.test.js
  git -C "$repo" commit -qm test-file
  git -C "$repo" mv tests/old.test.js renamed.txt
  unusual_path=$'line\nbreak.test.js'
  printf 'newline\n' >"$repo/$unusual_path"
  git -C "$repo" add -A
  output="$(cd "$repo" && source common/lib/review-common.sh && agentskills_collect_staged_risk 999999 999999 && printf 'files=%s escalate=%s\n' "$AGENTSKILLS_CHANGED_FILES" "$AGENTSKILLS_REVIEW_ESCALATE" && printf 'path=%q\n' "${AGENTSKILLS_STAGED_PATHS[@]}")"
  assert_contains "$output" "files=2 escalate=1" "rename and unusual path are counted and escalated"
  assert_contains "$output" "old.test.js" "rename source path is inspected"
  assert_contains "$output" "break.test.js" "newline-containing path is preserved"

  git -C "$repo" reset -q --hard HEAD
  git -C "$repo" rm -q tests/old.test.js
  output="$(cd "$repo" && source common/lib/review-common.sh && agentskills_collect_staged_risk 999999 999999 && printf 'files=%s escalate=%s\n' "$AGENTSKILLS_CHANGED_FILES" "$AGENTSKILLS_REVIEW_ESCALATE")"
  assert_contains "$output" "files=1 escalate=1" "deleted test path triggers escalation"
}

test_fallback_path() {
  local repo output rc
  repo="$(new_repo)"
  printf 'change\n' >>"$repo/app.txt"
  git -C "$repo" add app.txt
  git -C "$repo" config agentskills.kitPath common
  set +e
  output="$(cd "$repo" && PATH="/usr/bin:/bin" common/gates/check-llm-review.sh 2>&1)"
  rc=$?
  set -e
  [[ "$rc" == "1" ]] && pass "missing Codex blocks automatic review" || fail "missing Codex blocks automatic review"
  assert_contains "$output" "bash common/reviewers/record-manual-review.sh" "fallback uses configured kit path"
}

test_mechanical_gates() {
  local repo output rc
  repo="$(new_repo)"
  printf 'TOKEN=secret\n' >"$repo/.env.local"
  git -C "$repo" add .env.local
  set +e
  output="$(cd "$repo" && common/gates/check-sensitive-files.sh 2>&1)"
  rc=$?
  set -e
  [[ "$rc" != "0" ]] && pass "sensitive staged file is blocked" || fail "sensitive staged file is blocked"
  assert_contains "$output" "BLOCKER" "sensitive-file blocker is visible"

  git -C "$repo" reset -q --hard HEAD
  dd if=/dev/zero of="$repo/large.bin" bs=1048576 count=5 2>/dev/null
  printf x >>"$repo/large.bin"
  git -C "$repo" add large.bin
  set +e
  output="$(cd "$repo" && common/gates/check-large-files.sh 2>&1)"
  rc=$?
  set -e
  [[ "$rc" != "0" ]] && pass "file over 5 MiB is blocked" || fail "file over 5 MiB is blocked"

  git -C "$repo" reset -q --hard HEAD
  printf 'trailing space \n' >>"$repo/app.txt"
  git -C "$repo" add app.txt
  set +e
  output="$(cd "$repo" && AGENTSKILLS_SKIP_LLM_REVIEW=1 common/gates/pre-commit-gate.sh 2>&1)"
  rc=$?
  set -e
  [[ "$rc" != "0" ]] && pass "whitespace error is blocked by pre-commit gate" || fail "whitespace error is blocked by pre-commit gate"
  assert_contains "$output" "[AgentSkills][CHECK][START] whitespace" "pre-commit check name is visible"
}

test_reviewer_timeout() {
  local repo output rc start end
  repo="$(new_repo)"
  printf 'change\n' >>"$repo/app.txt"
  git -C "$repo" add app.txt
  git -C "$repo" config agentskills.reviewTimeoutSeconds 1
  git -C "$repo" config agentskills.reviewTimeoutKillGraceSeconds 1
  make_stubborn_codex "$repo"

  start="$(date +%s)"
  set +e
  output="$(cd "$repo" && PATH="$repo/fake-bin:$ORIGINAL_PATH" common/reviewers/review-staged-diff.sh 2>&1)"
  rc=$?
  set -e
  end="$(date +%s)"
  [[ "$rc" == "3" ]] && pass "TERM-resistant reviewer is forcibly stopped" || fail "TERM-resistant reviewer is forcibly stopped"
  assert_contains "$output" "exceeded 1 seconds" "timeout reason is visible"
  (((end - start) < 8)) && pass "timeout returns within bounded time" || fail "timeout returns within bounded time"

  git -C "$repo" config agentskills.reviewTimeoutSeconds invalid
  set +e
  output="$(cd "$repo" && PATH="$repo/fake-bin:$ORIGINAL_PATH" common/reviewers/review-staged-diff.sh 2>&1)"
  rc=$?
  set -e
  [[ "$rc" == "3" ]] && pass "invalid timeout configuration is rejected" || fail "invalid timeout configuration is rejected"
  assert_contains "$output" "must be a positive integer" "invalid timeout explains required format"
}

test_successful_reviewer_cleans_watchdog() {
  local repo result output timer_pid
  repo="$(new_repo)"
  printf 'change\n' >>"$repo/app.txt"
  git -C "$repo" add app.txt
  git -C "$repo" config agentskills.reviewTimeoutSeconds 30
  make_fake_codex "$repo"
  make_tracked_sleep "$repo"
  result='{"status":"OK","summary":"clean","model":"test","escalate":false,"findings":[]}'

  output="$(cd "$repo" && PATH="$repo/fake-bin:$ORIGINAL_PATH" FAKE_CODEX_RESULT="$result" FAKE_CODEX_DELAY_SECONDS=1 FAKE_SLEEP_PID_FILE="$repo/sleep.pid" common/reviewers/review-staged-diff.sh 2>&1)"
  assert_contains "$output" "[AgentSkills][LLM-REVIEW][PASS]" "successful reviewer completes"
  if [[ -f "$repo/sleep.pid" ]]; then
    timer_pid="$(cat "$repo/sleep.pid")"
    if kill -0 "$timer_pid" 2>/dev/null; then
      kill "$timer_pid" 2>/dev/null || true
      fail "successful reviewer cleans watchdog timer"
    else
      pass "successful reviewer cleans watchdog timer"
    fi
  else
    fail "successful reviewer started a watchdog timer"
  fi
}

test_pre_push_policy() {
  local repo output rc zero
  repo="$(new_repo)"
  zero=0000000000000000000000000000000000000000
  set +e
  output="$(cd "$repo" && printf 'refs/heads/topic %040d refs/heads/main %s\n' 1 "$zero" | common/hooks/pre-push origin example 2>&1)"
  rc=$?
  set -e
  [[ "$rc" == "1" ]] && pass "default main push is blocked" || fail "default main push is blocked"
  assert_contains "$output" "Protected branch: main" "blocked branch is visible"

  git -C "$repo" config --add agentskills.protectedPushBranch release
  set +e
  output="$(cd "$repo" && printf 'refs/heads/topic %040d refs/heads/main %s\n' 1 "$zero" | common/hooks/pre-push origin example 2>&1)"
  rc=$?
  set -e
  [[ "$rc" == "0" ]] && pass "configured policy replaces default branches" || fail "configured policy replaces default branches"
}

test_setup_conflict_and_force() {
  local repo output rc
  repo="$(new_repo)"
  git -C "$repo" config core.hooksPath existing/hooks
  set +e
  output="$(cd "$repo" && common/setup/setup-hooks.sh 2>&1)"
  rc=$?
  set -e
  [[ "$rc" == "1" ]] && pass "setup preserves an existing hooksPath" || fail "setup preserves an existing hooksPath"
  [[ "$(git -C "$repo" config core.hooksPath)" == "existing/hooks" ]] && pass "blocked setup leaves configuration unchanged" || fail "blocked setup leaves configuration unchanged"

  (cd "$repo" && common/setup/setup-hooks.sh --force) >/dev/null
  [[ "$(git -C "$repo" config core.hooksPath)" == "common/hooks" ]] && pass "forced setup installs common hooks" || fail "forced setup installs common hooks"
  [[ "$(git -C "$repo" config agentskills.kitPath)" == "common" ]] && pass "setup records logical kit path" || fail "setup records logical kit path"
}

printf 'TAP version 13\n'
test_status_consistency
test_evidence_required
test_manual_cache_and_invalidation
test_staged_path_parsing
test_fallback_path
test_mechanical_gates
test_reviewer_timeout
test_successful_reviewer_cleans_watchdog
test_pre_push_policy
test_setup_conflict_and_force

if ((FAIL_COUNT > 0)); then
  printf '# %d test assertions failed\n' "$FAIL_COUNT" >&2
  exit 1
fi
printf '# all %d assertions passed\n' "$PASS_COUNT"
