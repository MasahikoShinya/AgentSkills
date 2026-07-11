# Claude Code Workflow Rules

The project-root `AGENTS.md` is the source of truth for common agent behavior. Read it before starting work and follow it together with this file.

In Convergence mode:

1. Read the project-root `SESSION_BRIEF.md`.
2. Read the matching file under `.agentskills/prompts/` (or `common/prompts/` in the AgentSkills repository).
3. Display the rule, brief, prompt, mode, and phase actually used.

For an independent review, read `.agentskills/prompts/subagent-review.md`. Do not use the parent agent's conversation history, reasoning, implementation intent, or previous attempts as evidence. Base the review on `AGENTS.md`, `SESSION_BRIEF.md`, `git status`, `git diff`, `git diff --cached`, and required current file contents only.

The reviewer must not edit code, tests, staging, or `SESSION_BRIEF.md`. Return `OK`, `WARNING`, or `BLOCKER` with concrete findings.
