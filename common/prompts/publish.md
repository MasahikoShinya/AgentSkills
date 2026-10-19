# Publish

Report `[AgentSkills][PROMPT][START] ::publish` after reading this file. This is the only command that may commit, push, and create a draft PR.

Choose the next action from the user instructions, confirmed scope, and current evidence. If one recommended action is clear, execute it without asking for confirmation; the existence of theoretical alternatives does not require a pause. If multiple viable options remain and those inputs do not justify choosing one, stop the dependent work and present the concrete options, their tradeoffs, and the decision needed. Do not invent a preference to eliminate a real unresolved choice, and do not manufacture options merely to ask permission. Continue independent work while awaiting the decision. This rule governs judgment within the authorized task; it does not supply unavailable credentials or authorize operations outside the request.

Accepted forms:

```text
::publish
::publish --loop
```

The invocation also authorizes local preparation of the explicit publication scope: run missing project-native verification, diff review, explicit-path staging, staged review, and gate. Follow AGENTS.md Continuous Execution and Recovery for bounded failures. Do not fabricate evidence, bypass independent-review policy, or start unrelated implementation. If a matching unfinished workflow exists, resume it using its stored exact request and complete it before publishing; a different or invalid workflow remains a blocker. Nested read-only prompts return to this procedure without ending the publish operation.

First run `::scope` procedure and inspect Git status, staged and unstaged diffs, applicable `SESSION_BRIEF.md`, workflow state, review, and final gate evidence. Stop with `PROMPT BLOCKER` if the scope is mixed, candidate paths are not explicit, or required verification/review/gate evidence or workflow completion remains unavailable after authorized preparation and bounded recovery. Never stage unrelated paths and never use `git add .`, `git add -A`, or unrestricted `git add -u`.

Before any external write, resolve the PR base with `bash .agentskills/workflows/resolve-pr-base.sh`. Its output is the required base branch. The default policy is:

- `feature/*`, `fix/*`, `hotfix/*`, `chore/*`, `docs/*`, and `refactor/*` target `develop`.
- `develop`, `main`, and unknown branch names are blocked rather than relying on GitHub's default branch.
- No repository-local PR-base override is allowed; `::publish` never creates a PR targeting `main`.

Before any external write, display the exact paths to stage, commit message, source branch, resolved base branch, remote, and draft PR title. The original `::publish` invocation authorizes this publish operation; do not request a second conversational confirmation. Stage only the displayed paths, re-check the staged diff, commit, and push the current branch. If an open PR for the current branch already exists (prefer the PR recorded by `publish-state.sh`), confirm that its base branch equals the resolved base; stop with `PROMPT BLOCKER` when it differs. Otherwise create a draft PR with `gh pr create --draft --base "$base_branch"` and record its number and URL with `bash .agentskills/workflows/publish-state.sh record <number> <url>`. Report the commit SHA, PR URL, resolved base branch, and recorded PR number. Never merge or convert the draft PR to ready for review.

`::publish` ends after that one publish operation. `::publish --loop` continues as follows:

1. Run `::pr-review` against the PR created or reused above.
2. If its overall result is `OK`, report success and end.
3. If it reports a bounded, actionable finding with concrete evidence, run `::resolve <finding>` for that finding. Do not infer requirements beyond the finding, and preserve the `::resolve` safety stops.
4. After every completed resolution, run the same publish procedure to commit and push its explicit paths to the existing PR, then run `::pr-review` again.
5. Repeat until PR review is `OK`; there is no fixed retry or remediation count. Investigate repeated findings and failing checks, revise the correction from evidence, and continue. New findings within the confirmed publication scope are covered by the original invocation. Stop with `PROMPT BLOCKER` only when a concrete user decision, unavailable external input, or authorization outside the request is necessary; identify that dependency rather than asking to continue. Do not repeat an identical failed correction without new evidence.

`::publish --loop` never merges, marks a draft ready, comments on a PR, changes Git configuration, or creates a second PR for the same branch. End with `PROMPT END`, including the PR number, each remediation cycle, and the final PR-review result.
