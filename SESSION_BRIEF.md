# SESSION_BRIEF

> This file overrides prior conversation context for the current task. Include confirmed, adopted specifications only. Do not include proposals under consideration, rejected ideas, or superseded history.

## Work Mode

Convergence

## Purpose

Replace the pseudo-command prefix from `#$` to `::` across the AgentSkills common kit.

## Confirmed Specification

- All supported pseudo-commands use the ASCII `::` prefix: `::converge-bugfix`, `::diff-review`, `::subagent-review`, `::pr-review`, `::failure-analysis`, `::gate`, and `::help`.
- Rules, prompts, user-facing shell output, README, design documents, and regression tests use the same command spelling.
- Bash parameter expansions such as `${file#$TARGET_ROOT}` and PR number output such as `#$number` are not pseudo-commands and must remain unchanged.

## Current Problem

The `#$` prefix is visually shell-like and is less ergonomic than `::` for a chat-only pseudo-command. A single `@` cannot be used because it triggers client-side mention suggestions.

## Targets

- Pseudo-command references under `common/`
- `AgentWorkflowKitDesignV01.md`
- `SESSION_BRIEF.md`

## Non-Targets

- `common/setup/deploy.sh` copy-mode behavior
- Untracked `.claude/` local files
- Functional changes unrelated to pseudo-command spelling

## Prohibitions

- Do not change test expectations for implementation convenience.
- Do not perform unrelated refactoring.
- Do not modify non-target files without updating this brief and obtaining approval.

## Verification

- Confirm no pseudo-command reference retains the `#$` prefix.
- Confirm Bash parameter expansions and PR number output are unchanged.
- `bash common/tests/run-tests.sh`
- `git diff --check`
- Diff review confirms only the target files changed.
