# Resolve

After reading this file, report:

```text
[AgentSkills][PROMPT][START] ::resolve
Source: .agentskills/prompts/resolve.md
```

Use this prompt for a bounded review finding, regression, or confirmed defect. Do not create a task, a new design document, or a new `SESSION_BRIEF.md` solely because this command was used. If an existing brief applies, use it as the current specification.

Before editing, report the requested outcome, evidence, target files, non-target files, verification, and whether the request is sufficiently bounded. If the required behavior is unclear, report `PROMPT BLOCKER` and ask for clarification.

When the user has authorized the correction, make the smallest coherent change. Use existing relevant tests when available; do not weaken test expectations for convenience. Do not perform unrelated refactoring.

Before any user-requested commit, run `diff-review.md`, stage explicit paths, and perform a scope-isolated self-review of `AGENTS.md`, `SESSION_BRIEF.md`, `git status`, and `git diff --cached` without relying on the implementation conversation. Under the default `agentskills.reviewPolicy=auto`, if the overall result is `OK`, record it with `bash .agentskills/reviewers/record-manual-review.sh --runtime codex-self-review --status OK`, then run the gate. Report this as `SELF-REVIEW`, not an independent review. Under `independent`, use an external reviewer runtime instead; do not record a self-review for gate approval. Do not commit unless the final gate status is `PASS`.

After completing the requested resolution, report `PROMPT END` with the verification performed and any remaining limitation. If evidence or permission is unavailable, report `PROMPT BLOCKER` instead of `PROMPT END`.
