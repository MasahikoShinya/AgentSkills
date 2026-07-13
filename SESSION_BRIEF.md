# SESSION_BRIEF

> This file overrides prior conversation context for the current task. Include confirmed, adopted specifications only. Do not include proposals under consideration, rejected ideas, or superseded history.

## Work Mode

Convergence

## Purpose

Repair the PR #3 BLOCKER caused by literal `#$` pseudo-command text being expanded as an unset Bash variable.

## Confirmed Specification

- The manual-review fallback must print `#$subagent-review` literally when Codex is unavailable.
- The PR-review prerequisite failure must print `#$pr-review` literally when `gh` is unavailable.
- Both failure paths must retain their documented exit status and actionable message under `set -u`.

## Current Problem

Double-quoted `#$subagent-review` and `#$pr-review` expand `$subagent` and `$pr` as unset variables, interrupting the intended failure message.

## Targets

- `common/gates/check-llm-review.sh`
- `common/reviewers/inspect-pull-request.sh`
- `common/tests/run-tests.sh`
- `SESSION_BRIEF.md`

## Non-Targets

- `common/setup/deploy.sh` copy-mode behavior
- Untracked `.claude/` local files
- Unrelated PR #3 files and documentation

## Prohibitions

- Do not change test expectations for implementation convenience.
- Do not perform unrelated refactoring.
- Do not modify non-target files without updating this brief and obtaining approval.

## Verification

- `bash -n common/gates/check-llm-review.sh common/reviewers/inspect-pull-request.sh common/tests/run-tests.sh`
- Run `common/reviewers/inspect-pull-request.sh` without `gh` and confirm exit status `3` with literal `#$pr-review` output.
- `bash common/tests/run-tests.sh`
- `git diff --check`
- Diff review confirms only the target files changed.
