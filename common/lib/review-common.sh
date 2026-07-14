#!/usr/bin/env bash

# Shared, Bash 3.2-compatible helpers for staged-diff review scripts.

agentskills_hash_stream() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 | awk '{print $NF}'
  else
    return 127
  fi
}

agentskills_require_hash_command() {
  command -v sha256sum >/dev/null 2>&1 ||
    command -v shasum >/dev/null 2>&1 ||
    command -v openssl >/dev/null 2>&1
}

agentskills_hash_staged_diff() {
  git diff --cached --binary --no-ext-diff | agentskills_hash_stream
}

agentskills_model_from_markdown() {
  local models_file="$1"
  local column="$2"
  [[ -f "$models_file" ]] || return 0
  awk -F'|' -v column="$column" '
    /^[[:space:]]*\|[[:space:]]*Codex[[:space:]]*\|/ {
      value=$column
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      print value
      exit
    }
  ' "$models_file"
}

agentskills_is_risk_path() {
  local path="$1"
  local lower
  lower="$(printf '%s' "$path" | tr '[:upper:]' '[:lower:]')"
  [[ "$lower" =~ (^|/)(auth|authentication|authorization|permissions|payments|migrations|infrastructure)(/|$) ||
    "$lower" == .github/workflows/* ||
    "$lower" =~ (^|/)(test|tests|spec|specs|__tests__)(/|$) ||
    "$lower" =~ \.(test|spec)\.[^.]+$ ]]
}

agentskills_collect_staged_risk() {
  local line_limit="$1"
  local file_limit="$2"
  local status path second_path additions deletions

  AGENTSKILLS_CHANGED_FILES=0
  AGENTSKILLS_CHANGED_LINES=0
  AGENTSKILLS_REVIEW_ESCALATE=0
  AGENTSKILLS_RISK_REASONS=()
  AGENTSKILLS_STAGED_PATHS=()

  while IFS= read -r -d '' status; do
    IFS= read -r -d '' path || return 1
    AGENTSKILLS_STAGED_PATHS+=("$path")
    AGENTSKILLS_CHANGED_FILES=$((AGENTSKILLS_CHANGED_FILES + 1))
    if agentskills_is_risk_path "$path"; then
      AGENTSKILLS_REVIEW_ESCALATE=1
      AGENTSKILLS_RISK_REASONS+=("risk path: $path")
    fi

    case "$status" in
      R*|C*)
        IFS= read -r -d '' second_path || return 1
        AGENTSKILLS_STAGED_PATHS+=("$second_path")
        if agentskills_is_risk_path "$second_path"; then
          AGENTSKILLS_REVIEW_ESCALATE=1
          AGENTSKILLS_RISK_REASONS+=("risk path: $second_path")
        fi
        ;;
    esac
  done < <(git diff --cached --name-status --diff-filter=ACMRD -z)

  while IFS=$'\t' read -r additions deletions path; do
    [[ "$additions" =~ ^[0-9]+$ ]] &&
      AGENTSKILLS_CHANGED_LINES=$((AGENTSKILLS_CHANGED_LINES + additions))
    [[ "$deletions" =~ ^[0-9]+$ ]] &&
      AGENTSKILLS_CHANGED_LINES=$((AGENTSKILLS_CHANGED_LINES + deletions))
  done < <(git diff --cached --numstat --diff-filter=ACMRD)

  if ((AGENTSKILLS_CHANGED_LINES >= line_limit)); then
    AGENTSKILLS_REVIEW_ESCALATE=1
    AGENTSKILLS_RISK_REASONS+=("changed lines: $AGENTSKILLS_CHANGED_LINES >= $line_limit")
  fi
  if ((AGENTSKILLS_CHANGED_FILES >= file_limit)); then
    AGENTSKILLS_REVIEW_ESCALATE=1
    AGENTSKILLS_RISK_REASONS+=("changed files: $AGENTSKILLS_CHANGED_FILES >= $file_limit")
  fi
}

agentskills_context_fingerprint() {
  local repo_root="$1"
  local kit_root="$2"
  local escalated="$3"
  local line_limit="$4"
  local file_limit="$5"
  local review_policy="${6:-auto}"
  local input

  {
    printf 'format=3\n'
    printf 'escalated=%s\nline_limit=%s\nfile_limit=%s\nreview_policy=%s\n' "$escalated" "$line_limit" "$file_limit" "$review_policy"
    git diff --cached --binary --no-ext-diff
    for input in \
      "$repo_root/SESSION_BRIEF.md" \
      "$repo_root/AGENTS.md" \
      "$repo_root/AGENT_MODELS.md" \
      "$kit_root/prompts/subagent-review.md" \
      "$kit_root/schemas/review-result.schema.json" \
      "$kit_root/reviewers/review-staged-diff.sh" \
      "$kit_root/reviewers/record-manual-review.sh" \
      "$kit_root/gates/check-llm-review.sh" \
      "$kit_root/lib/review-common.sh"; do
      printf '\n-- input:%s --\n' "${input#$repo_root/}"
      if [[ -f "$input" ]]; then
        command cat "$input"
      else
        printf '<missing>\n'
      fi
    done
  } | agentskills_hash_stream
}

agentskills_review_policy() {
  local policy
  policy="$(git config --local --get agentskills.reviewPolicy || true)"
  policy="${policy:-auto}"
  case "$policy" in
    auto|independent)
      printf '%s\n' "$policy"
      ;;
    *)
      return 1
      ;;
  esac
}

agentskills_safe_cache_component() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'
}
