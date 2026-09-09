# Plan

Report `[AgentSkills][PROMPT][START] ::plan` after reading this file. Use `::plan <request>` in Expansion mode before implementation. Inspect only the request, relevant files, existing tests, and repository conventions. Write a draft at `docs/plans/<slug>.md` with this handoff block before its body:

```md
## SDD Handoff

- Request: `<the exact ::plan request>`
- Status: draft
- Adopted by: pending
```

The body must contain purpose, current context, proposed behavior, scope and non-scope, alternatives, risks, implementation outline, verification, and unresolved decisions. Do not create an external task, edit application source or production tests, stage, commit, push, create a PR, or modify Git configuration. The plan is not adopted until the user confirms it. A later `::sdd_tdd <the exact request>` is that adoption signal: it selects exactly one matching draft plan, changes its handoff status to `adopted`, and uses it as the Phase 1 input. End with `PROMPT END`.
