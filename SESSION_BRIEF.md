# SESSION_BRIEF

> This file overrides prior conversation context for the current task. Include confirmed, adopted specifications only. Do not include proposals under consideration, rejected ideas, or superseded history.

## Work Mode

Convergence

## Purpose

Add the `::resolve`, `::ui-mock`, and `::test-plan` pseudo-commands, make `::sdd_tdd` a strict SDD + TDD workflow, and make LLM review failures diagnosable.

## Confirmed Specification

- `::resolve` handles a bounded review finding, regression, or confirmed defect without creating a task or new specification artifact.
- `::sdd_tdd` writes an adopted specification to `SESSION_BRIEF.md`, obtains failing-test or reproduction evidence, then proceeds through implementation, review, and gate.
- `::ui-mock` is an Expansion command that writes only a static UI draft to `docs/ui-mocks/<slug>.html`.
- `::test-plan` is an Expansion command that uses the installed `test-orchestrator` skill in planning-only mode and writes a draft to `docs/test-plans/<slug>.md`.
- `::test-plan` reports `BLOCKER` when the required skill is unavailable; it does not silently replace the skill.
- `::converge-bugfix` is not retained as a compatibility alias.
- Each non-cached Codex staged-diff review records a persistent run-state file and stdout/stderr log under its local `.git/agentskills/reviews/` context directory.
- Review start and failure output show the run-state and log paths. Invalid JSON also preserves the returned result file.
- `agentskills.reviewPolicy=auto` accepts an `OK` `codex-self-review` cache produced by `::resolve` or `::sdd_tdd`; `independent` requires an external reviewer and ignores self-review caches.
- When running inside a Codex session without a usable cache, the gate blocks immediately rather than starting a nested `codex exec`.

## Current Problem

The workflow needs distinct entry points for rapid bounded resolution, strict SDD + TDD, UI specification exploration, and test-planning exploration. LLM reviewer failures currently discard their child-process log, making a missing terminal status difficult to diagnose.

## Targets

- Common rules, prompts, and workflow-help prompt
- Common README and synchronized design documents
- Reviewer and gate diagnostics, regression tests, and this brief

## Non-Targets

- Untracked `.claude/` local files
- Existing skill implementations, the `EXECUTED` marker contract, and unrelated functional behavior

## Prohibitions

- Do not change test expectations for implementation convenience.
- Do not perform unrelated refactoring.
- Do not modify non-target files without updating this brief and obtaining approval.

## Verification

- Confirm all four commands map to their intended prompts in the common rules.
- Confirm `::sdd_tdd` requires the brief specification and failing-test evidence.
- Confirm `::test-plan` requires the installed `test-orchestrator` skill.
- Confirm reviewer failure output exposes persistent diagnostics.
- Confirm auto and independent review policies handle self-review caches as specified.
- `bash common/tests/run-tests.sh`
- `git diff --check`
- Diff review confirms only the target files changed.
