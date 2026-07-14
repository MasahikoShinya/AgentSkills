# Test Plan

After reading this file, report:

```text
[AgentSkills][PROMPT][START] ::test-plan
Source: .agentskills/prompts/test-plan.md
```

Use this prompt only in Expansion mode to turn a proposed change into acceptance criteria and a test plan before SDD + TDD. Do not modify application source, production tests, package configuration, or test results.

First locate the installed `test-orchestrator` skill and read its `SKILL.md`. Use its planning phase only: invoke the `test-planner` workflow, identify unit and E2E coverage, and do not run unit, E2E, or visual test execution phases.

Write the resulting plan to `docs/test-plans/<slug>.md`, where `<slug>` is a short ASCII name for the feature or change. Include confirmed acceptance criteria, test cases, boundaries, error cases, test-level allocation, prerequisites, and unresolved questions. Treat the plan as a draft until the user adopts it.

If the `test-orchestrator` skill or its planning capability is unavailable, report `PROMPT BLOCKER` with the required skill name and this manual planning instruction: read `test-orchestrator/SKILL.md` in an agent-enabled runtime, then invoke only its `test-planner` phase. Do not silently replace the skill with an invented workflow.
