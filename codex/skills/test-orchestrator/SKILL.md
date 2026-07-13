---
name: test-orchestrator
description: Codex CLI用のテスト計画・Unit/E2E・目視確認・結果記録スキル。実行前に shared/test-orchestrator.md を読み、サブエージェントがない場合はCodex自身が各フェーズを順番に実行する。
---

# Test Orchestrator for Codex CLI

この入口は Codex CLI 用。作業前に AgentSkills リポジトリルートの `shared/test-orchestrator.md` を読むこと。シンボリックリンク経由で相対パスが解決できない場合は、この Skill ディレクトリのリンク先をたどってリポジトリルートを特定する。

Codex 固有の前提:

- Claude Code の Agent tool や `~/.claude/agents` は使わない
- 実行可能なローカルコマンド、テストコマンド、コンテナ操作を確認してから進める
- 目視確認補助は、対象プロジェクトで Playwright と `generate-player.ts` が利用できる場合のみ行う
- 実行できない外部ツールや未設定の環境は、未実行として記録する
