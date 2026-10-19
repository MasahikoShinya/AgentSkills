# Strict SDD + TDD Workflow

After reading this file, report:

```text
[AgentSkills][PROMPT][START] ::sdd_tdd
Source: .agentskills/prompts/sdd_tdd.md
```

Use this prompt only for strict Convergence work. Follow SDD and TDD in this exact order. Do not skip a phase. Read project-root `REVIEW_LESSONS.md` when present and apply only lessons relevant to the requested target.

## Invocation Modes

`::sdd_tdd <request>` is the default continuous mode. When the request provides a confirmed, bounded expected behavior and scope, continue from Spec through Gate without asking for phase-by-phase permission. The invocation itself authorizes recording the specification, adding and running scoped tests, making the scoped implementation, reviewing, staging explicit task paths, and running Gate; do not ask conversationally whether to proceed at any of those boundaries. It never commits, pushes, merges, changes test expectations for convenience, or broadens the confirmed scope.

`::sdd_tdd --step <request>` is the step mode. Complete only the recorded current Phase, then report `PROMPT END` and wait for the next user instruction. It preserves the approval stops described below.

Japanese continuation shorthand is accepted. Treat `進めて`, `進めてください`, `続けて`, `続けてください`, `続行`, and `再開` as equivalent continuation signals after trimming whitespace and terminal punctuation; never ask the user to restate one of those phrases in a more polite form. For a shorthand, first resume the one unfinished `sdd_tdd` workflow when present, using its stored request. If no unfinished `sdd_tdd` workflow exists, adopt exactly one draft `SDD Handoff` when it is the only applicable draft plan, using that handoff's `Request` as the canonical request. If neither source is unique, report `PROMPT BLOCKER` and ask which concrete work to continue; do not treat the shorthand itself as a new request.

Before any work with a canonical request, run `bash .agentskills/workflows/workflow-state.sh show sdd_tdd "<exact request>"` (or the equivalent `common/` path). If it reports an unfinished state, resume only at its recorded `Next phase`; do not infer a phase from conversation history or restart Spec. The request must match the original request text. If it reports no state or an already-complete state, start a new workflow with `bash .agentskills/workflows/workflow-state.sh start sdd_tdd spec "<request>"`. A legacy-state `BLOCKER` has no request identity and must be reviewed before the explicitly shown `discard-legacy` command is run. Any other `BLOCKER` stops the command without editing.

When starting a new workflow, search `docs/plans/` for a `## SDD Handoff` block whose `Request` exactly matches the canonical request and whose `Status` is `draft`. The invocation is the user's adoption signal. If exactly one matching draft exists, read it first and validate that its unresolved decisions, scope, and verification are no longer ambiguous. Only then change its handoff fields to `Status: adopted` and `Adopted by: ::sdd_tdd`, and use it as the adopted-plan input for Phase 1. If no matching draft exists, continue with the standalone Phase 1 procedure. If more than one matching draft exists, or validation finds ambiguity, report `PROMPT BLOCKER`; do not choose a plan, mark it adopted, or start tests.

Execute only the phase reported as `Next phase`. In step mode, stop immediately after completing and recording that phase. In default continuous mode, proceed through the next recorded phase in the mandatory order.

In continuous mode, stop with `PROMPT BLOCKER` instead of continuing only when any of the following requires a product or safety judgment:

- expected behavior, scope, or non-targets are ambiguous;
- existing staged or unstaged changes cannot be separated from this task;
- no project-native test or reproducible check can be identified;
- the change requires a destructive, externally visible, security-sensitive, or otherwise irreversible operation.

An individual test, review, gate, or hook failure is work evidence, not a conversational stop. Diagnose it, make the smallest scoped correction, and rerun the relevant verification and later phases automatically. Continue until the confirmed behavior passes, unless the diagnosis requires one of the judgments above; then report exactly that question as `PROMPT BLOCKER`. An individual gate check may emit `WARNING` for information. Report it, but continue when the final `GATE` or `HOOK` status is `PASS`.

## Phase 1: Spec

Do not change application code or tests. Read `AGENTS.md` and `SESSION_BRIEF.md`. When an adopted-plan input exists, treat its confirmed behavior, scope, non-scope, risks, implementation outline, and verification as the starting point. Inspect only the plan's named files and tests plus changes since the plan that could invalidate it; do not repeat its broad repository survey. Confirm the plan still matches current behavior, resolve no new product decisions by inference, and report only changed facts, deviations, and remaining risks. When no adopted-plan input exists, inspect the current implementation and tests as before. Then report:

- current behavior
- confirmed expected behavior
- mismatch
- impact and regression risks
- conditions the test must fix in place
- likely target files
- planned file changes
- unanswered questions

After the adopted specification has been saved, run `bash .agentskills/workflows/workflow-state.sh advance sdd_tdd test` before reporting the next action.

In step mode, stop and wait for user permission to record the adopted specification in `SESSION_BRIEF.md`. In default continuous mode, record it immediately only when the request is sufficiently unambiguous. Do not call Phase 1 complete until that specification artifact has been saved. Create it from `.agentskills/briefs/SESSION_BRIEF.template.md` when absent, or update it when present. When an adopted plan was used, record its path and only the confirmed specification, target, non-target, prohibitions, and verification method; the plan remains the exploration record and `SESSION_BRIEF.md` remains the review basis.

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

In step mode, make the smallest production change after permission. In default continuous mode, make it immediately after the required test evidence. Re-run the relevant test and report its passing evidence. If it does not pass, diagnose and correct it within the confirmed scope, then rerun it; do not ask to continue merely because it failed. Do not change test expectations, touch out-of-scope files, or perform unrelated refactoring.

After Phase 3 completes, advance the workflow state to `review`.

## Phase 4: Review

Read `diff-review.md`. Review unstaged, staged, and untracked changes against `SESSION_BRIEF.md`. Stage explicit task paths only after `OK`; do not alter paths that were staged before this workflow started. Then perform a scope-isolated self-review of `AGENTS.md`, `SESSION_BRIEF.md`, `git status`, and `git diff --cached`. Under the default `agentskills.reviewPolicy=auto`, if its overall result is `OK`, record it with `bash .agentskills/reviewers/record-manual-review.sh --runtime codex-self-review --status OK`. Report it as `SELF-REVIEW`, not an independent review. Under `independent`, use an external reviewer runtime instead; do not record a self-review for gate approval. In default continuous mode, correct concrete in-scope findings and rerun review automatically; stop only when a finding or staging boundary requires a product or safety judgment.

After Phase 4 completes, advance the workflow state to `gate`.

## Phase 5: Gate

Run the gate script and report every check. On failure, diagnose the cause, make the smallest in-scope correction, and rerun the necessary verification and gate automatically. A passing gate ends the continuous mode; do not commit unless the user separately requests it.

After Phase 5 passes, advance the workflow state to `complete`.

For each later phase completed in step mode, report the same `PROMPT END` line with the completed phase and next action. In default continuous mode, report one `PROMPT END` after Phase 5 with the test, review, and gate results. If a required specification, test, or instruction is unavailable, report `PROMPT BLOCKER` with the reason instead of `PROMPT END`.
