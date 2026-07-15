# Claude Code Workflow Rules

The project-root `AGENTS.md` is the source of truth for common agent behavior. Read it before starting work and follow it together with this file.

In Convergence mode:

1. Read the project-root `SESSION_BRIEF.md`.
2. Read the matching file under `.agentskills/prompts/` (or `common/prompts/` in the AgentSkills repository).
3. Display the rule, brief, prompt, mode, and phase actually used.

For `::ui-mock` and `::test-plan`, use Expansion mode and read the matching prompt. For `::test-plan`, use the installed `test-orchestrator` skill only for its planning phase; do not run its test execution phases.

For `::sdd_tdd`, do not start tests until the adopted specification has been written to `SESSION_BRIEF.md`, and do not implement until failing-test or reproduction evidence has been obtained. With `::sdd_tdd --auto <request>`, continue through Gate without phase-by-phase approval only when the request is confirmed and bounded; stop for ambiguity, mixed existing changes, missing project-native test evidence, a final review `WARNING` / `BLOCKER`, a final `GATE` / `HOOK` `BLOCKER` / `FAIL`, or high-risk operations. An individual gate-check `WARNING` is informational when the final status is `PASS`.

For `::resolve --auto <request>`, use the command as authorization for a confirmed, bounded correction. Do not create or update `SESSION_BRIEF.md` solely for this command. Continue through relevant verification, diff review, explicit task-path staging, staged self-review, and Gate; do not commit, push, or merge. Stop for ambiguity, mixed existing changes, missing verification, a final review `WARNING` / `BLOCKER`, a final `GATE` / `HOOK` `BLOCKER` / `FAIL`, or high-risk operations. An individual gate-check `WARNING` is informational when the final status is `PASS`.

For an independent review, read `.agentskills/prompts/subagent-review.md`. Do not use the parent agent's conversation history, reasoning, implementation intent, or previous attempts as evidence. Base the review on `AGENTS.md`, `SESSION_BRIEF.md`, `git status`, `git diff`, `git diff --cached`, and required current file contents only.

For `::pr-review`, read `.agentskills/prompts/pr-review.md` and run the matching `inspect-pull-request.sh` script. Use GitHub PR metadata, checks, and base/head diff as evidence. Do not merge or otherwise change the PR unless the user separately asks.

For `::help`, read `.agentskills/prompts/workflow-help.md` and display its compact help without running hooks, reviewers, or setup scripts.

The reviewer must not edit code, tests, staging, or `SESSION_BRIEF.md`. Return `OK`, `WARNING`, or `BLOCKER` with concrete findings.
