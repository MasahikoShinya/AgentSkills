# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Repository Overview

AgentSkills is a Japanese skill/workflow repository for AI agents. It is being migrated from the legacy `ClaudeSkills` layout to a tool-neutral layout that can be shared by Claude Code, Codex CLI, and Gemini CLI.

All skill definitions and documentation are written in Japanese unless a tool-specific format requires English.

## Architecture

```text
shared/
  Tool-neutral workflows, review criteria, output formats, templates

claude/
  Claude Code / Cowork entry files
  skills/<skill-name>/SKILL.md
  agents/*.md

codex/
  Codex CLI entry files
  skills/<skill-name>/SKILL.md

gemini/
  Gemini CLI entry files
  commands/<skill-name>.toml

Legacy compatibility:
  test-orchestrator/
  code-review/
  cowork-chrome-launcher/
  agents/
```

## Current Skills

- `test-orchestrator`: test planning, unit/E2E execution, visual verification, result recording
- `code-review`: independent review, cross-response, integrated report
- `cowork-chrome-launcher`: Cowork / Claude Desktop Chrome connection selection

## Key Conventions

- Common, tool-neutral content belongs in `shared/`.
- Claude Code specific entry files belong in `claude/skills/<skill-name>/SKILL.md`.
- Codex CLI specific entry files belong in `codex/skills/<skill-name>/SKILL.md`.
- Gemini CLI command entries belong in `gemini/commands/<skill-name>.toml`.
- Claude subagents belong in `claude/agents/`. The legacy root `agents/` directory remains for compatibility.
- Existing root-level skill directories remain compatibility shims during migration and must not be removed casually.
- Every `SKILL.md` must have YAML frontmatter with `name` and `description`.
- Keep `shared/` free of Claude Code Agent tool, `~/.claude`, Codex MCP, or Gemini-specific command syntax unless the workflow itself is inherently about that product.

## Development Workflow

There is no build system, linter, or test suite. Validate changes by checking:

- file layout matches README
- `SKILL.md` frontmatter is present and valid
- tool-specific entry files point to the matching `shared/*.md`
- symlink examples remain accurate
- legacy Claude Code usage is still documented

When changing a skill:

1. Update the corresponding `shared/<skill-name>.md` if the workflow or output format changes.
2. Update each relevant entry file under `claude/`, `codex/`, and `gemini/`.
3. If Claude subagents or resources change, keep `claude/agents/` and compatibility `agents/` in sync when applicable.
4. Update README when installation paths, skill lists, or migration instructions change.

## Safety

This repo may have local, uncommitted user changes. Do not revert unrelated modifications. Do not delete legacy root-level skill directories unless the user explicitly asks for a breaking migration.
