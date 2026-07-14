# UI Mock

After reading this file, report:

```text
[AgentSkills][PROMPT][START] ::ui-mock
Source: .agentskills/prompts/ui-mock.md
```

Use this prompt only in Expansion mode to make an inspectable UI specification artifact before SDD + TDD. Do not modify application source, production assets, tests, package configuration, or Git hooks.

Create one self-contained static HTML mock at `docs/ui-mocks/<slug>.html`. Choose a short ASCII `<slug>` from the requested screen or feature. The mock must show the intended information hierarchy, empty/loading/error states when relevant, primary and secondary actions, and responsive behavior. Use only local HTML and CSS; do not add dependencies, remote assets, or tracking code.

Before writing the mock, report assumptions and unresolved product decisions. After writing it, report its path, the decisions represented, and open questions that must be resolved before adoption. The mock is a draft specification artifact, not production UI. Do not start `::sdd_tdd` until the user adopts the relevant decisions.

If the request does not identify a screen, user, or primary workflow, report `PROMPT BLOCKER` and ask for those details instead of creating a generic mock.
