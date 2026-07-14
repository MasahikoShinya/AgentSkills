# SESSION_BRIEF

> This file overrides prior conversation context for the current task. Include confirmed, adopted specifications only. Do not include proposals under consideration, rejected ideas, or superseded history.

## Work Mode

Convergence

## Purpose

Add a clear final-line execution marker for every AgentSkills pseudo-command.

## Confirmed Specification

- When an agent actually recognizes and dispatches a pseudo-command, the final user-facing line is `[AgentSkills][EXECUTED] ::<command>`.
- The displayed `::help` block ends with `[AgentSkills][EXECUTED] ::help` as its final non-empty line.
- The marker confirms pseudo-command execution only. It does not imply that a review, test, gate, or hook passed; those outcomes remain in the component status output.
- If the marker is absent, execution is unconfirmed. It does not imply a detected failure.

## Current Problem

Pseudo-commands are interpreted by the agent and cannot be made to trigger with a 100 percent platform-level guarantee. Users need one compact, unambiguous confirmation when an instruction was actually handled.

## Targets

- Common rules and workflow-help prompt
- Common README and synchronized design documents
- Regression tests and this brief

## Non-Targets

- Untracked `.claude/` local files
- Pseudo-command spelling and unrelated functional behavior

## Prohibitions

- Do not change test expectations for implementation convenience.
- Do not perform unrelated refactoring.
- Do not modify non-target files without updating this brief and obtaining approval.

## Verification

- Confirm the execution marker contract is documented in the rules, help, README, and design documents.
- `bash common/tests/run-tests.sh`
- `git diff --check`
- Diff review confirms only the target files changed.
