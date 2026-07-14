# Diff Review

After reading this file, report:

```text
[AgentSkills][PROMPT][START] ::diff-review
Source: .agentskills/prompts/diff-review.md
```

Review only. Do not modify code, tests, staging, or `SESSION_BRIEF.md`.

Use `SESSION_BRIEF.md`, `git status`, `git diff`, `git diff --cached`, and relevant untracked files as evidence. Check:

- every change is necessary for the confirmed purpose
- no non-target or prohibited area changed
- existing behavior is not unintentionally removed or weakened
- test expectations were not changed for implementation convenience
- the change is the smallest coherent diff
- refactoring is directly required
- security, authorization, data integrity, and public contracts remain valid
- required changes are not left unstaged or untracked

Output exactly one overall result: `OK`, `WARNING`, or `BLOCKER`. List findings with file, line when known, evidence, reason, and recommended next action. Do not fix findings.

After the result, report `PROMPT END` with `Execution: completed` and the same overall result. If evidence cannot be collected, report `PROMPT BLOCKER` with the missing input or failed command instead of `PROMPT END`.
