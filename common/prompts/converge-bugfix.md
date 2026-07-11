# Converge Bugfix

[AgentSkills][PROMPT][START] @converge-bugfix

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

Stop and wait for user permission.

## Phase 2: Test

After permission, reproduce with an existing test or add the smallest failing test. Do not edit production code. Do not change an existing expectation to fit current behavior.

## Phase 3: Implement

After permission, make the smallest production change that passes the confirmed test. Do not change test expectations, touch out-of-scope files, or perform unrelated refactoring.

## Phase 4: Review

Read `diff-review.md`. Review unstaged, staged, and untracked changes against `SESSION_BRIEF.md`. Stage explicit paths only after `OK`, then review `git diff --cached` again.

## Phase 5: Gate

Run the gate script and report every check. On failure, do not immediately patch the code. Read `failure-analysis.md` and perform cause analysis only.

[AgentSkills][PROMPT][END] @converge-bugfix
