# SESSION_BRIEF

> This file overrides prior conversation context for the current task. Include confirmed, adopted specifications only. Do not include proposals under consideration, rejected ideas, or superseded history.

## Work Mode

Convergence

## Purpose

Accept concise Japanese continuation instructions for `::sdd_tdd` and a bare `::publish` invocation without adding redundant wording or weakening workflow safety.

## Confirmed Specification

- Treat `進めて`, `進めてください`, `続けて`, `続けてください`, `続行`, and `再開` as equivalent `::sdd_tdd` continuation instructions after trimming whitespace and terminal punctuation.
- Never ask users to add polite Japanese wording.
- Resume an unfinished `sdd_tdd` workflow when exactly one exists; otherwise adopt exactly one applicable draft SDD handoff using its stored request.
- Ask for a concrete target only when those sources are absent or ambiguous; never use the shorthand itself as a new request identity.
- Preserve exact request matching after a canonical request has been selected.
- Treat both `::publish` and `::publish --loop` as complete requests to commit, push, and create or reuse a Draft PR after scope, verification, review, and gate evidence is confirmed.
- Do not demand additional phrasing such as `実行してください`, `実行して`, or `進めて` for either publish form.

## Current Problem

The workflow can treat short Japanese continuation instructions as a new request and can demand redundant execution wording after a bare `::publish`, rather than recognizing the pseudo-command as the user's intent.

## Targets

- `common/prompts/sdd_tdd.md` and `common/prompts/publish.md`
- `common/prompts/workflow-help.md` and `common/workflows/workflow-state.sh`
- `common/rules/AGENTS.base.md` and `common/rules/CLAUDE.base.md`
- `common/README.md`, `common/docs/design.md`, regression tests, and this brief

## Non-Targets

- Other pseudo-command behavior and unrelated functional changes

## Prohibitions

- Do not change test expectations for implementation convenience.
- Do not perform unrelated refactoring.
- Do not modify non-target files without updating this brief and obtaining approval.

## Verification

- Confirm the SDD prompt treats short and polite Japanese continuation phrases as equivalent.
- Confirm ambiguous shorthand remains blocked and canonical request matching remains required.
- Confirm bare `::publish` is accepted without an execution phrase.
- `bash common/tests/run-tests.sh`
- `git diff --check`
- Diff review confirms only the target files changed.
