---
name: cowork-chrome-launcher
description: Codex CLI用のCowork Chrome接続手順参照スキル。shared/cowork-chrome-launcher.md を読むが、Claude in Chrome互換MCPが利用できない環境では実行不可として案内する。
---

# Cowork Chrome Launcher for Codex CLI

この入口は Codex CLI 用。必要時に AgentSkills リポジトリルートの `shared/cowork-chrome-launcher.md` を読むこと。シンボリックリンク経由で相対パスが解決できない場合は、この Skill ディレクトリのリンク先をたどってリポジトリルートを特定する。

Codex 固有の前提:

- 通常の Codex CLI には `mcp__Claude_in_Chrome__*` ツールがないため、接続先固定は実行できない
- 互換 MCP ツールが明示的に提供されている場合だけ、共有本文の手順を実行する
- ツールがない場合は、Cowork / Claude Desktop 側でこのスキルを使うよう案内する
