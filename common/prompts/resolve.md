# Resolve

After reading this file, report:

```text
[AgentSkills][PROMPT][START] ::resolve
Source: .agentskills/prompts/resolve.md
```

Use this prompt for a bounded review finding, regression, or confirmed defect. Do not create a task, a new design document, or a new `SESSION_BRIEF.md` solely because this command was used. If an existing brief applies, use it as the current specification. Read project-root `REVIEW_LESSONS.md` when present and apply only lessons relevant to the requested target.

## Continuous Execution and Recovery

Choose the next action from the user instructions, confirmed scope, and current evidence. If one recommended action is clear, execute it without asking for confirmation; the existence of theoretical alternatives does not require a pause. If multiple viable options remain and those inputs do not justify choosing one, stop the dependent work and present the concrete options, their tradeoffs, and the decision needed. Do not invent a preference to eliminate a real unresolved choice, and do not manufacture options merely to ask permission. Continue independent work while awaiting the decision. This rule governs judgment within the authorized task; it does not supply unavailable credentials or authorize operations outside the request.

Before yielding for user input, apply the continuation test: if the only useful reply would be “continue”, “proceed”, or “進めて”, do not stop. Execute that next action under the existing request. Ordinary implementation choices with one evidence-backed recommendation, target discovery, cause investigation, missing checks that can be run, and correctable review findings are agent work. Unresolved choices between viable options follow the decision rule above. Explicit analysis-only commands remain analysis-only.

The default invocation authorizes all required phases and bounded corrections within the confirmed scope. Progress reports, analysis results, and nested prompt `END` markers are not permission checkpoints; continue the parent workflow until its completion condition is met. Preserve explicit `--step` stops.

Before treating a test, review, gate, or hook failure as a workflow blocker, read `failure-analysis.md` and analyze the evidence without editing. Then apply the smallest evidence-backed, in-scope correction and rerun the affected verification, diff review, staged review, and gate as applicable. Continue recovery until the requested completion condition is met; there is no fixed retry or remediation count. A repeated failure or uncertain cause requires further investigation, a revised hypothesis, or a different verification method, not a request to continue. Do not repeat an identical failed action without new evidence. Ask the user only when progress requires a concrete product or scope decision unavailable from existing instructions, a conflict over inseparable user changes, unavailable credentials or external input, or authorization for an operation outside the request. Before stopping, complete all independent authorized work and identify why further investigation or another authorized approach cannot remove that dependency. Never bypass a failing gate, weaken expectations, or fabricate review evidence. A failed commit attempt remains stopped until the gate passes.

Recovery happens within the recorded current phase; do not advance failed phases or rewind state. Revalidate downstream evidence after any correction. Review prompts remain read-only; the parent workflow performs corrections after the review returns. The expected failing test in SDD Phase 2 is required evidence, not a recovery failure.

When blocked, state the concrete missing decision, evidence, or permission and the smallest input needed. Do not ask only for “continue” when existing authorization is sufficient. A continuation request resumes the active recorded request; use its stored original request text for state checks rather than treating “continue” as a new request identity.

## Invocation Modes

`::resolve <request>` is the default continuous mode. Before editing, report the requested outcome, evidence, target files, non-target files, verification, and whether the request is sufficiently bounded. If the required behavior is unclear, report `PROMPT BLOCKER` and ask for clarification. When the request is confirmed and bounded, continue through Gate without phase-by-phase permission. It does not create or update `SESSION_BRIEF.md` solely for this command, and it never commits, pushes, or merges.

`::resolve --step <request>` is the step mode. Complete only the recorded current Phase, then report `PROMPT END` and wait for the next user instruction. It preserves the approval stops described below.

`::resolve --reset` is the dedicated state-reset operation. It accepts no request text and cannot be combined with `--step`; reject `::resolve --reset <request>` and `::resolve --step --reset` with `PROMPT BLOCKER`. Run only `bash .agentskills/workflows/workflow-state.sh reset resolve` before reporting `PROMPT END`. The script displays the workflow, stored request identity when available, next phase, recorded time, initial staged paths, and state path before archiving only `resolve.state` and `resolve.initial-staged` under `.git/agentskills/workflows/archive/`. It must not change source files, Git worktree or staged changes, commits, branches, pull requests, or Git configuration. A `BLOCKER`, including no resettable state, stops the operation.

Before any work, run `bash .agentskills/workflows/workflow-state.sh show resolve "<exact request>"` (or the equivalent `common/` path). If it reports an unfinished state, resume only at its recorded `Next phase`; do not infer a phase from conversation history or restart an already-recorded phase. The request must match the original request text. If it reports no state or an already-complete state, start a new workflow with `bash .agentskills/workflows/workflow-state.sh start resolve inspect "<request>"`. A legacy-state `BLOCKER` has no request identity and must be reviewed before the explicitly shown `discard-legacy` command is run. Any other `BLOCKER` stops the command without editing.

Execute only the phase reported as `Next phase`:

- `inspect`: confirm the bounded outcome, evidence, targets, non-targets, and verification, then advance to `implement`.
- `implement`: make the smallest correction, then advance to `verify`.
- `verify`: run the relevant verification, then advance to `review` only when it passes.
- `review`: run `diff-review.md`, stage explicit task paths after `OK`, perform the required staged self-review, then advance to `gate`.
- `gate`: run the gate and advance to `complete` only when it passes.

In step mode, stop immediately after completing and recording the selected phase. In default continuous mode, proceed through the next recorded phase in order.

In default continuous mode, attempt the bounded recovery above first for actionable verification or review failures. Stop with `PROMPT BLOCKER` only when investigation and recovery establish an actual user or external dependency in the following:

- expected behavior, scope, or non-targets are ambiguous;
- existing staged or unstaged changes cannot be separated from this task;
- no relevant test or project-native verification can be identified;
- the relevant verification does not pass;
- the final diff review reports `WARNING` or `BLOCKER`;
- the final `GATE` or `HOOK` status is `BLOCKER` or `FAIL`;
- the correction requires a destructive, externally visible, security-sensitive, or otherwise irreversible operation.

These statuses are diagnostics, not automatic end-of-turn conditions. Investigate and correct them under the existing request; an unresolved dependency must name the actual missing input. Risk labels alone do not revoke authorization already given for the operation.

An individual gate check may emit `WARNING` for information. Report it, but continue when the final `GATE` or `HOOK` status is `PASS`. After a test, review, gate, or hook failure, follow Continuous Execution and Recovery; analysis must precede each correction.

In step mode, make the smallest coherent change after the user has authorized the correction. In default continuous mode, make it immediately after confirming the request is bounded. Use existing relevant tests when available, or the smallest project-native verification for the target. Do not weaken test expectations for convenience. Do not perform unrelated refactoring.

## Prevention Checkpoint

After relevant verification passes and before final diff review, classify the resolved finding exactly once:

- `regression-test`: a new or strengthened regression test prevents recurrence;
- `brief`: the confirmed behavior must be clarified in `SESSION_BRIEF.md`;
- `rule`: a reusable project rule belongs in `AGENTS.md`;
- `workflow-test`: a prompt, script, or kit regression test prevents recurrence;
- `none`: an existing prevention is sufficient or the finding is not reusable.

Do not create a lesson for ordinary implementation history. Update project-root `REVIEW_LESSONS.md` only when the reusable prevention is not already clear from its linked test, rule, or workflow guard. Each entry must state its applicability, one concrete prevention, verification, and a review finding or incident identifier when available. Update an existing entry instead of creating a duplicate. Do not record rejected ideas or parent-conversation history.

Report exactly one line before the final diff review:

```text
[AgentSkills][PREVENTION] regression-test | brief | rule | workflow-test | none
```

Before any user-requested commit, run `diff-review.md`, stage explicit paths, and perform a scope-isolated self-review of `AGENTS.md`, `SESSION_BRIEF.md`, `git status`, and `git diff --cached` without relying on the implementation conversation. Under the default `agentskills.reviewPolicy=auto`, if the overall result is `OK`, record it with `bash .agentskills/reviewers/record-manual-review.sh --runtime codex-self-review --status OK`, then run the gate. Report this as `SELF-REVIEW`, not an independent review. Under `independent`, use an external reviewer runtime instead; do not record a self-review for gate approval. Do not commit unless the final gate status is `PASS`.

In default continuous mode, after relevant verification passes, run `diff-review.md`, stage only explicit task paths after `OK`, and do not alter paths that were staged before the workflow began. Perform the same scope-isolated staged self-review and gate sequence. A passing gate ends the workflow; leave the verified task paths staged and do not commit unless the user separately requests it.

After review completes, advance the workflow state to `gate`. After Gate passes, advance it to `complete`.

After completing the requested resolution, report `PROMPT END` with the verification performed and any remaining limitation. In default continuous mode, report one `PROMPT END` after Gate with the verification, review, and gate results. In step mode, report `PROMPT END` after the completed Phase and its recorded next Phase. If evidence or permission is unavailable, report `PROMPT BLOCKER` instead of `PROMPT END`.
