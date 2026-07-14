# Strict SDD + TDD Workflow

After reading this file, report:

```text
[AgentSkills][PROMPT][START] ::sdd_tdd
Source: .agentskills/prompts/sdd_tdd.md
```

Use this prompt only for strict Convergence work. Follow SDD and TDD in this exact order. Do not skip a phase.

## Phase 1: Spec

Do not change application code or tests. Read `AGENTS.md` and `SESSION_BRIEF.md`, inspect the current implementation and tests, then report:

- current behavior
- confirmed expected behavior
- mismatch
- impact and regression risks
- conditions the test must fix in place
- likely target files
- planned file changes
- unanswered questions

Stop and wait for user permission to record the adopted specification in `SESSION_BRIEF.md`. Do not call Phase 1 complete until that specification artifact has been saved. After permission, create it from `.agentskills/briefs/SESSION_BRIEF.template.md` when absent, or update it when present. Write only the confirmed specification, target, non-target, prohibitions, and verification method, then report:

```text
[AgentSkills][PROMPT][END] ::sdd_tdd
Completed: Phase 1 Spec
Next action: Start Phase 2 Test.
```

## Phase 2: Test

Reproduce with an existing test or add the smallest failing test. Do not edit production code. Do not change an existing expectation to fit current behavior. Report the command and failing-test evidence. If the project has no usable test harness, identify the smallest project-native harness and obtain user approval before continuing. Do not implement without the required SDD specification artifact and test evidence.

## Phase 3: Implement

After permission, make the smallest production change that passes the confirmed test. Re-run the relevant test and report its passing evidence. Do not change test expectations, touch out-of-scope files, or perform unrelated refactoring.

## Phase 4: Review

Read `diff-review.md`. Review unstaged, staged, and untracked changes against `SESSION_BRIEF.md`. Stage explicit paths only after `OK`, then perform a scope-isolated self-review of `AGENTS.md`, `SESSION_BRIEF.md`, `git status`, and `git diff --cached`. Under the default `agentskills.reviewPolicy=auto`, if its overall result is `OK`, record it with `bash .agentskills/reviewers/record-manual-review.sh --runtime codex-self-review --status OK`. Report it as `SELF-REVIEW`, not an independent review. Under `independent`, use an external reviewer runtime instead; do not record a self-review for gate approval.

## Phase 5: Gate

Run the gate script and report every check. On failure, do not immediately patch the code. Read `failure-analysis.md` and perform cause analysis only.

For each later phase completed after permission, report the same `PROMPT END` line with the completed phase and next action. If a required specification, test, or instruction is unavailable, report `PROMPT BLOCKER` with the reason instead of `PROMPT END`.
