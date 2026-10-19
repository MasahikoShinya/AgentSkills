# Strict SDD + TDD Workflow

After reading this file, report:

```text
[AgentSkills][PROMPT][START] ::sdd_tdd
Source: .agentskills/prompts/sdd_tdd.md
```

Use this prompt only for strict Convergence work. Follow SDD and TDD in this exact order. Do not skip a phase. Read project-root `REVIEW_LESSONS.md` when present and apply only lessons relevant to the requested target.

## Continuous Execution and Recovery

Choose the next action from the user instructions, confirmed scope, and current evidence. If one recommended action is clear, execute it without asking for confirmation; the existence of theoretical alternatives does not require a pause. If multiple viable options remain and those inputs do not justify choosing one, stop the dependent work and present the concrete options, their tradeoffs, and the decision needed. Do not invent a preference to eliminate a real unresolved choice, and do not manufacture options merely to ask permission. Continue independent work while awaiting the decision. This rule governs judgment within the authorized task; it does not supply unavailable credentials or authorize operations outside the request.

Before yielding for user input, apply the continuation test: if the only useful reply would be “continue”, “proceed”, or “進めて”, do not stop. Execute that next action under the existing request. Ordinary implementation choices with one evidence-backed recommendation, target discovery, cause investigation, missing checks that can be run, and correctable review findings are agent work. Unresolved choices between viable options follow the decision rule above. Explicit analysis-only commands remain analysis-only.

The default invocation authorizes all required phases and bounded corrections within the confirmed scope. Progress reports, analysis results, and nested prompt `END` markers are not permission checkpoints; continue the parent workflow until its completion condition is met. Preserve explicit `--step` stops.

Before treating a test, review, gate, or hook failure as a workflow blocker, read `failure-analysis.md` and analyze the evidence without editing. Then apply the smallest evidence-backed, in-scope correction and rerun the affected verification, diff review, staged review, and gate as applicable. Continue recovery until the requested completion condition is met; there is no fixed retry or remediation count. A repeated failure or uncertain cause requires further investigation, a revised hypothesis, or a different verification method, not a request to continue. Do not repeat an identical failed action without new evidence. Ask the user only when progress requires a concrete product or scope decision unavailable from existing instructions, a conflict over inseparable user changes, unavailable credentials or external input, or authorization for an operation outside the request. Before stopping, complete all independent authorized work and identify why further investigation or another authorized approach cannot remove that dependency. Never bypass a failing gate, weaken expectations, or fabricate review evidence. A failed commit attempt remains stopped until the gate passes.

Recovery happens within the recorded current phase; do not advance failed phases or rewind state. Revalidate downstream evidence after any correction. Review prompts remain read-only; the parent workflow performs corrections after the review returns. The expected failing test in SDD Phase 2 is required evidence, not a recovery failure.

When blocked, state the concrete missing decision, evidence, or permission and the smallest input needed. Do not ask only for “continue” when existing authorization is sufficient. A continuation request resumes the active recorded request; use its stored original request text for state checks rather than treating “continue” as a new request identity.

## Invocation Modes

`::sdd_tdd <request>` is the default continuous mode. When the request provides a confirmed, bounded expected behavior and scope, continue from Spec through Gate without asking for phase-by-phase permission. It never commits, pushes, merges, changes test expectations for convenience, or broadens the confirmed scope.

`::sdd_tdd --step <request>` is the step mode. Complete only the recorded current Phase, then report `PROMPT END` and wait for the next user instruction. It preserves the approval stops described below.

Before any work, run `bash .agentskills/workflows/workflow-state.sh show sdd_tdd "<exact request>"` (or the equivalent `common/` path). If it reports an unfinished state, resume only at its recorded `Next phase`; do not infer a phase from conversation history or restart Spec. The request must match the original request text. If it reports no state or an already-complete state, start a new workflow with `bash .agentskills/workflows/workflow-state.sh start sdd_tdd spec "<request>"`. A legacy-state `BLOCKER` has no request identity and must be reviewed before the explicitly shown `discard-legacy` command is run. Any other `BLOCKER` stops the command without editing.

When starting a new workflow, search `docs/plans/` for a `## SDD Handoff` block whose `Request` exactly matches the `::sdd_tdd` request and whose `Status` is `draft`. The invocation is the user's adoption signal. If exactly one matching draft exists, read it first and validate that its unresolved decisions, scope, and verification are no longer ambiguous. Only then change its handoff fields to `Status: adopted` and `Adopted by: ::sdd_tdd`, and use it as the adopted-plan input for Phase 1. If no matching draft exists, continue with the standalone Phase 1 procedure. If more than one matching draft exists, or validation finds ambiguity, report `PROMPT BLOCKER`; do not choose a plan, mark it adopted, or start tests.

Execute only the phase reported as `Next phase`. In step mode, stop immediately after completing and recording that phase. In default continuous mode, proceed through the next recorded phase in the mandatory order.

In continuous mode, attempt the bounded recovery above first for actionable verification or review failures. Stop with `PROMPT BLOCKER` only when investigation and recovery establish an actual user or external dependency in the following:

- expected behavior, scope, or non-targets are ambiguous;
- existing staged or unstaged changes cannot be separated from this task;
- no project-native test or reproducible check can be identified;
- the relevant test does not provide the required failing or passing evidence;
- the final diff review reports `WARNING` or `BLOCKER`;
- the final `GATE` or `HOOK` status is `BLOCKER` or `FAIL`;
- the change requires a destructive, externally visible, security-sensitive, or otherwise irreversible operation.

These statuses are diagnostics, not automatic end-of-turn conditions. Investigate and correct them under the existing request; an unresolved dependency must name the actual missing input. Risk labels alone do not revoke authorization already given for the operation.

An individual gate check may emit `WARNING` for information. Report it, but continue when the final `GATE` or `HOOK` status is `PASS`. After a test, review, gate, or hook failure, follow Continuous Execution and Recovery; analysis must precede each correction.

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

Reproduce with an existing test or add the smallest failing test. Do not edit production code. Do not change an existing expectation to fit current behavior. Report the command and failing-test evidence. If the project has no usable test harness, identify the smallest project-native harness; in step mode obtain user approval before continuing, and in default continuous mode establish the smallest project-native harness or reproducible check within the confirmed scope and continue. Report `PROMPT BLOCKER` only if doing so requires a concrete new decision or unavailable external input. Do not implement without the required SDD specification artifact and test evidence.

After Phase 2 completes, advance the workflow state to `implement`.

## Phase 3: Implement

In step mode, make the smallest production change after permission. In default continuous mode, make it immediately after the required test evidence. Re-run the relevant test and report its passing evidence. If it does not pass, follow Continuous Execution and Recovery before advancing. Do not change test expectations, touch out-of-scope files, or perform unrelated refactoring.

After Phase 3 completes, advance the workflow state to `review`.

## Phase 4: Review

Read `diff-review.md`. Review unstaged, staged, and untracked changes against `SESSION_BRIEF.md`. Stage explicit task paths only after `OK`; do not alter paths that were staged before this workflow started. Then perform a scope-isolated self-review of `AGENTS.md`, `SESSION_BRIEF.md`, `git status`, and `git diff --cached`. Under the default `agentskills.reviewPolicy=auto`, if its overall result is `OK`, record it with `bash .agentskills/reviewers/record-manual-review.sh --runtime codex-self-review --status OK`. Report it as `SELF-REVIEW`, not an independent review. Under `independent`, use an external reviewer runtime instead; do not record a self-review for gate approval. In default continuous mode, recover bounded review findings before repeating review; investigate an uncertain staging boundary and isolate task changes; stop only if inseparable user changes require a concrete decision.

After Phase 4 completes, advance the workflow state to `gate`.

## Phase 5: Gate

Run the gate script and report every check. On failure, analyze first and follow Continuous Execution and Recovery. Advance only after the gate passes. A passing gate ends the continuous mode; do not commit unless the user separately requests it.

After Phase 5 passes, advance the workflow state to `complete`.

For each later phase completed in step mode, report the same `PROMPT END` line with the completed phase and next action. In default continuous mode, report one `PROMPT END` after Phase 5 with the test, review, and gate results. If a required specification, test, or instruction is unavailable, report `PROMPT BLOCKER` with the reason instead of `PROMPT END`.
