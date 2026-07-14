# Converge Bugfix

After reading this file, report:

```text
[AgentSkills][PROMPT][START] ::converge-bugfix
Source: .agentskills/prompts/converge-bugfix.md
```

Use this prompt only for Convergence work. Follow SDD and TDD in this exact order.

## Phase 1: Spec

Do not change files. Read `AGENTS.md` and `SESSION_BRIEF.md`, inspect the current implementation and tests, then report:

- current behavior
- confirmed expected behavior
- mismatch
- impact and regression risks
- conditions the test must fix in place
- likely target files
- planned file changes
- unanswered questions

Stop and wait for user permission. Before waiting, report:

```text
[AgentSkills][PROMPT][END] ::converge-bugfix
Completed: Phase 1 Spec
Next action: Await user permission for Phase 2 Test.
```

## Phase 2: Test

After permission, reproduce with an existing test or add the smallest failing test. Do not edit production code. Do not change an existing expectation to fit current behavior.

## Phase 3: Implement

After permission, make the smallest production change that passes the confirmed test. Do not change test expectations, touch out-of-scope files, or perform unrelated refactoring.

## Phase 4: Review

Read `diff-review.md`. Review unstaged, staged, and untracked changes against `SESSION_BRIEF.md`. Stage explicit paths only after `OK`, then review `git diff --cached` again.

## Phase 5: Gate

Run the gate script and report every check. On failure, do not immediately patch the code. Read `failure-analysis.md` and perform cause analysis only.

For each later phase completed after permission, report the same `PROMPT END` line with the completed phase and next action. If a required input or instruction is unavailable, report `PROMPT BLOCKER` with the reason instead of `PROMPT END`.
