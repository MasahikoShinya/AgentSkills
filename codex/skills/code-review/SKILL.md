---
name: code-review
description: Codex CLI用のコードレビュースキル。shared/code-review.md の観点と出力形式に従い、利用可能な範囲で差分、ファイル、PR、シンボルをレビューする。
---

# Code Review for Codex CLI

この入口は Codex CLI 用。レビュー前に AgentSkills リポジトリルートの `shared/code-review.md` を読むこと。シンボリックリンク経由で相対パスが解決できない場合は、この Skill ディレクトリのリンク先をたどってリポジトリルートを特定する。

Codex 固有の前提:

- Claude Opus サブエージェントや Codex MCP への自己委譲は前提にしない
- 複数レビュアーが使えない場合は単独レビューとして出力する
- GitHub PR や CI が対象の場合は、利用可能な GitHub ツールまたはローカル git 情報を確認する
- テストを実行していない場合は、未実行と残リスクを明記する
