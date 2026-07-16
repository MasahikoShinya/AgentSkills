# Strict SDD + TDD Workflow

After reading this file, report:

```text
[AgentSkills][PROMPT][START] ::sdd_tdd
Source: .agentskills/prompts/sdd_tdd.md
```

Use this prompt only for strict Convergence work. Follow SDD and TDD in this exact order. Do not skip a phase.

## Invocation Modes

`::sdd_tdd <request>` is the default continuous mode. When the request provides a confirmed, bounded expected behavior and scope, continue from Spec through Gate without asking for phase-by-phase permission. It never commits, pushes, merges, changes test expectations for convenience, or broadens the confirmed scope.

`::sdd_tdd --step <request>` is the step mode. Complete only the recorded current Phase, then report `PROMPT END` and wait for the next user instruction. It preserves the approval stops described below.

Before any work, run `bash .agentskills/workflows/workflow-state.sh show sdd_tdd` (or the equivalent `common/` path). If it reports an unfinished state, resume only at its recorded `Next phase`; do not infer a phase from conversation history or restart Spec. If it reports no state or an already-complete state, start a new workflow with `bash .agentskills/workflows/workflow-state.sh start sdd_tdd spec`. Any other `BLOCKER` stops the command without editing.

Execute only the phase reported as `Next phase`. In step mode, stop immediately after completing and recording that phase. In default continuous mode, proceed through the next recorded phase in the mandatory order.

In continuous mode, stop with `PROMPT BLOCKER` instead of continuing when any of the following applies:

- expected behavior, scope, or non-targets are ambiguous;
- existing staged or unstaged changes cannot be separated from this task;
- no project-native test or reproducible check can be identified;
- the relevant test does not provide the required failing or passing evidence;
- the final diff review reports `WARNING` or `BLOCKER`;
- the final `GATE` or `HOOK` status is `BLOCKER` or `FAIL`;
- the change requires a destructive, externally visible, security-sensitive, or otherwise irreversible operation.

An individual gate check may emit `WARNING` for information. Report it, but continue when the final `GATE` or `HOOK` status is `PASS`. After a test, review, gate, or hook failure, read `failure-analysis.md` and report the analysis only. Do not apply another correction in the same continuous run.

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

After the adopted specification has been saved, run `bash .agentskills/workflows/workflow-state.sh advance sdd_tdd test` before reporting the next action.

In step mode, stop and wait for user permission to record the adopted specification in `SESSION_BRIEF.md`. In default continuous mode, record it immediately only when the request is sufficiently unambiguous. Do not call Phase 1 complete until that specification artifact has been saved. Create it from `.agentskills/briefs/SESSION_BRIEF.template.md` when absent, or update it when present. Write only the confirmed specification, target, non-target, prohibitions, and verification method.

In step mode, then report:

```text
[AgentSkills][PROMPT][END] ::sdd_tdd
Completed: Phase 1 Spec
Next action: Start Phase 2 Test.
```

## Phase 2: Test

Reproduce with an existing test or add the smallest failing test. Do not edit production code. Do not change an existing expectation to fit current behavior. Report the command and failing-test evidence. If the project has no usable test harness, identify the smallest project-native harness; in step mode obtain user approval before continuing, and in default continuous mode stop with `PROMPT BLOCKER`. Do not implement without the required SDD specification artifact and test evidence.

After Phase 2 completes, advance the workflow state to `implement`.

## Phase 3: Implement

In step mode, make the smallest production change after permission. In default continuous mode, make it immediately after the required test evidence. Re-run the relevant test and report its passing evidence. If it does not pass, stop and read `failure-analysis.md`. Do not change test expectations, touch out-of-scope files, or perform unrelated refactoring.

After Phase 3 completes, advance the workflow state to `review`.

## Phase 4: Review

Read `diff-review.md`. Review unstaged, staged, and untracked changes against `SESSION_BRIEF.md`. Stage explicit task paths only after `OK`; do not alter paths that were staged before this workflow started. Then perform a scope-isolated self-review of `AGENTS.md`, `SESSION_BRIEF.md`, `git status`, and `git diff --cached`. Under the default `agentskills.reviewPolicy=auto`, if its overall result is `OK`, record it with `bash .agentskills/reviewers/record-manual-review.sh --runtime codex-self-review --status OK`. Report it as `SELF-REVIEW`, not an independent review. Under `independent`, use an external reviewer runtime instead; do not record a self-review for gate approval. In default continuous mode, a `WARNING`, `BLOCKER`, or uncertain staging boundary stops the workflow.

After Phase 4 completes, advance the workflow state to `gate`.

## Phase 5: Gate

Run the gate script and report every check. On failure, do not immediately patch the code. Read `failure-analysis.md` and perform cause analysis only. A passing gate ends the continuous mode; do not commit unless the user separately requests it.

After Phase 5 passes, advance the workflow state to `complete`.

For each later phase completed in step mode, report the same `PROMPT END` line with the completed phase and next action. In default continuous mode, report one `PROMPT END` after Phase 5 with the test, review, and gate results. If a required specification, test, or instruction is unavailable, report `PROMPT BLOCKER` with the reason instead of `PROMPT END`.
