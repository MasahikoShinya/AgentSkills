# Agent Workflow Rules

This file is the base rule set for Claude Code, Codex, and compatible agents.
Merge it into the project-root `AGENTS.md`; do not replace project-specific rules.

## Execution Visibility

When a workflow component is actually used, report it with this format:

```text
[AgentSkills][COMPONENT][START|END|PASS|WARNING|BLOCKER|FAIL|SKIP] name
```

Never claim that a rule, prompt, skill, brief, reviewer, or script was used unless it was actually read or executed.

For every prompt-backed pseudo-command, emit `PROMPT START` and its source path only after reading the prompt. Emit `PROMPT END` only after completing the requested prompt procedure, with its outcome or next action. If the procedure cannot be completed, emit `PROMPT BLOCKER` or `PROMPT SKIP` with the reason instead. `PROMPT END` proves only that the agent completed the prompt procedure; review, gate, and test outcomes must be reported by their own component status. For a pseudo-command that dispatches directly to a shell script, use that script's `START` and final status as its execution evidence.

After a pseudo-command was actually recognized and dispatched to its required prompt or script, append this exact final line to the user-facing response:

```text
[AgentSkills][EXECUTED] ::<command>
```

This line confirms pseudo-command execution only. It does not mean that a review, test, gate, or hook passed; use those components' own final status for that result. Do not emit this line when the pseudo-command was not recognized or its required prompt or script was not used. Its absence means execution was not confirmed, not that a failure was detected.

For a commit gate or hook, commit only after its final status is `PASS`. `BLOCKER` and `FAIL` stop that commit attempt. A `WARNING` alone does not determine commit eligibility; inspect the final `GATE` or `HOOK` status.

## Work Mode Selector

Before editing files, select and display one mode: `Expansion`, `Convergence`, or `Uncertain`.

Apply this precedence:

1. Explicit user mode or pseudo-command.
2. Purpose of the task.
3. Certainty of the expected behavior.
4. Whether existing behavior or code is being changed.
5. If the result remains ambiguous, select `Uncertain`.

Select `Convergence` for bug fixes, regressions, failing tests, confirmed-spec mismatches, bounded changes to existing code, and fixes requested by test, review, or gate results.

Select `Expansion` for ideation, requirement discovery, alternative comparison, architecture exploration, and new features whose specification is not yet confirmed.

For `Uncertain`, do not change code. State the ambiguity and ask the user to choose or confirm the mode.

For `::ui-mock` and `::test-plan`, select `Expansion`. They produce only draft specification artifacts and must not modify application source, production tests, package configuration, or hooks.

For `::resolve`, select `Convergence`, read `.agentskills/prompts/resolve.md`, and use an existing `SESSION_BRIEF.md` only when it applies. Do not create a task or new specification artifact solely because `::resolve` was used.

For `::resolve` and `::sdd_tdd`, check `agentskills.reviewPolicy` before the gate. Under the default `auto` policy, record an `OK` staged self-review as `codex-self-review` for the current diff and label it `SELF-REVIEW`; it is not an independent review. Under `independent`, do not record a self-review for gate approval; use an external reviewer runtime.

For `::sdd_tdd`, select `Convergence` and follow this strict sequence:

1. Read the project-root `SESSION_BRIEF.md` if it exists.
2. Read `.agentskills/prompts/sdd_tdd.md` (or `common/prompts/sdd_tdd.md` inside the AgentSkills repository).
3. Display the selected mode, trigger, evidence, files read, and current phase.
4. Run Phase 1: Spec only. Do not edit application code or tests until the user adopts the specification.
5. Write the adopted specification to `SESSION_BRIEF.md` before Phase 2.
6. Obtain failing-test or reproduction evidence before Phase 3.
7. Keep the mode fixed in `SESSION_BRIEF.md`; do not switch modes silently.

## Phase Definitions

Expansion broadens options and clarifies requirements. Convergence satisfies a confirmed specification while minimizing change and regression risk.

## Mandatory SDD + TDD Order

This order is mandatory for `::sdd_tdd`.

1. Spec: write the adopted current behavior, expected behavior, mismatch, scope, non-scope, and verification to `SESSION_BRIEF.md`.
2. Test: reproduce with an existing test or add the smallest failing test.
3. Implement: make the smallest production change that satisfies the confirmed test and specification.
4. Diff Review: inspect unstaged, staged, and untracked changes against `SESSION_BRIEF.md`.
5. Stage: stage explicit paths only after an `OK` review.
6. Staged Diff Review: inspect `git diff --cached` and `git status`.
7. Gate: run `.agentskills/gates/pre-commit-gate.sh` or the equivalent `common/` path.
8. Commit: keep one purpose per commit.

Never change test expectations to accommodate an implementation unless the confirmed specification explicitly requires the expectation change. Do not perform unrelated refactoring.

## Staging Rules

- Display each candidate path and why it belongs to the task.
- Use `git add -- <path>...` with explicit paths.
- Do not use `git add .`, `git add -A`, or an unrestricted `git add -u`.
- Do not unstage or alter changes that were already staged when the task began.
- If a file mixes in-scope and out-of-scope changes, report `WARNING` and do not stage it.

## Review Rules

Diff review is mandatory. Compare `SESSION_BRIEF.md` with:

- `git status`
- `git diff`
- `git diff --cached`
- untracked files that may belong to the task

Return `OK`, `WARNING`, or `BLOCKER` with concrete evidence. `OK` may proceed. `WARNING` requires user judgment. `BLOCKER` stops the workflow.

An independent reviewer must not assume the parent conversation, implementation intent, reasoning, or prior attempts. It may use only `AGENTS.md`, `SESSION_BRIEF.md`, Git status and diffs, and necessary current file contents. It must not modify code, staging, tests, or the brief.

For a pull request review, use `::pr-review [PR-number-or-URL]`. Read the matching pull-request prompt, inspect PR metadata, checks, and the base/head diff through `gh`, then return `OK`, `WARNING`, or `BLOCKER`. Do not merge, push, comment on, or edit a PR unless the user separately requests that operation.

On test, review, gate, or hook failure, do not make consecutive fixes. Read `.agentskills/prompts/failure-analysis.md`, analyze the cause without code changes, and obtain user permission before applying the next fix.

## Pseudo-Commands

| Command | Required input |
|---|---|
| `::resolve` | `.agentskills/prompts/resolve.md` |
| `::sdd_tdd` | `.agentskills/prompts/sdd_tdd.md` |
| `::ui-mock` | `.agentskills/prompts/ui-mock.md` |
| `::test-plan` | `.agentskills/prompts/test-plan.md` and the installed `test-orchestrator` skill |
| `::diff-review` | `.agentskills/prompts/diff-review.md` |
| `::subagent-review` | `.agentskills/prompts/subagent-review.md` |
| `::pr-review [PR-number-or-URL]` | `.agentskills/prompts/pr-review.md` |
| `::failure-analysis` | `.agentskills/prompts/failure-analysis.md` |
| `::gate` | `.agentskills/gates/pre-commit-gate.sh` |
| `::help` | `.agentskills/prompts/workflow-help.md` |
