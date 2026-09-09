# Test Plan

After reading this file, report:

```text
[AgentSkills][PROMPT][START] ::test-plan
Source: .agentskills/prompts/test-plan.md
```

Use this prompt only in Expansion mode to turn a proposed change into acceptance criteria and a test plan before SDD + TDD. Do not modify application source, production tests, package configuration, or test results.

First locate the installed `test-orchestrator` skill and read its `SKILL.md`. When the current runtime can invoke its `test-planner` workflow, use its planning phase only. Identify unit and E2E coverage, and do not run unit, E2E, or visual test execution phases.

When `test-orchestrator` or its `test-planner` execution capability is unavailable, use the Codex-compatible fallback instead of reporting `PROMPT BLOCKER`. In the main agent context, inspect only the proposed change, relevant application code, existing tests, and project-native test commands. Derive acceptance criteria, unit and E2E coverage, boundaries, error cases, and prerequisites. Do not claim that a subagent ran, and do not run tests or modify application source, production tests, package configuration, or test results.

Write the resulting plan to `docs/test-plans/<slug>.md`, where `<slug>` is a short ASCII name for the feature or change. Include confirmed acceptance criteria, test cases, boundaries, error cases, test-level allocation, prerequisites, and unresolved questions. Treat the plan as a draft until the user adopts it.

Report the runtime used in the result: `test-planner` when that workflow ran, or `Codex fallback` when the current runtime performed the planning directly. In both cases, keep the plan as a draft until the user adopts it.
