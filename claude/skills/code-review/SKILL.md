---
name: code-review
description: Claude Code用のコードレビュースキル。共通観点は shared/code-review.md を読み、Claude Codeでは code-reviewer と code-critic サブエージェントで独立レビュー、クロスレスポンス、統合レポートを行う。
---

# Code Review for Claude Code

この入口は Claude Code 用。レビュー前に AgentSkills リポジトリルートの `shared/code-review.md` を読むこと。シンボリックリンク経由で相対パスが解決できない場合は、この Skill ディレクトリのリンク先をたどってリポジトリルートを特定する。

## Claude Code 固有の運用

- `code-reviewer` は Claude 側の独立レビューとクロスレスポンスを担当する
- `code-critic` は Codex MCP を使った独立レビューとクロスレスポンスを担当する
- Phase 2 の独立レビューと Phase 3 のクロスレスポンスは、可能なら並列で実行する
- 2つの結果をメインコンテキストで統合し、Agreed / Single / Disputed に分類する
- Codex MCP が使えない場合は、単独レビューとして実行し、その制約をレポートに明記する
