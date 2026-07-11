# Agent Model Configuration

`auto` uses the runtime default. Concrete model names are intentionally project-specific and may be changed without editing the common rules.

| Runtime | Expansion | Convergence | Review | Review escalation | Failure analysis |
|---|---|---|---|---|---|
| Claude Code | auto | auto | auto | auto | auto |
| Codex | auto | auto | auto | auto | auto |
| Gemini | auto | auto | auto | auto | auto |

Operational review thresholds are stored in local Git config. Defaults:

```text
agentskills.reviewEscalateLines=300
agentskills.reviewEscalateFiles=10
```
