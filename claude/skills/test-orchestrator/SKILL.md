---
name: test-orchestrator
description: テストの計画・実行・目視確認を統合管理するClaude Code用司令塔スキル。共通手順は shared/test-orchestrator.md を読み、Claude Codeでは test-planner, unit-runner, e2e-runner, e2e-visual-verify サブエージェントを必要に応じて呼び出す。
---

# Test Orchestrator for Claude Code

この入口は Claude Code 用。実行前に AgentSkills リポジトリルートの `shared/test-orchestrator.md` を読むこと。シンボリックリンク経由で相対パスが解決できない場合は、この Skill ディレクトリのリンク先をたどってリポジトリルートを特定する。

## Claude Code 固有の運用

- サブエージェントは `claude/agents/` または互換用のルート `agents/` から `~/.claude/agents/` にリンクして使う
- 計画は `test-planner`
- ユニットテストは `unit-runner`
- E2E テストは `e2e-runner`
- 動画・スクリーンショット・HTML プレイヤー生成は `e2e-visual-verify`
- 実行補助ファイルはこのスキル配下の `generate-player.ts`, `run-visual-verify.sh`, `templates/test-plan.md` を正とする

サブエージェントを使えない環境では、共有本文のフェーズをメインコンテキストで順番に実行する。
