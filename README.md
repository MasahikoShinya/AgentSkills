# AgentSkills

AI エージェント用のスキル・ワークフロー集。Claude Code だけでなく、Codex CLI / Gemini CLI でも同じレビュー観点、テスト手順、出力形式を共有できる構成を目指す。

このリポジトリは以前 `ClaudeSkills` として運用していた。既存のルート直下 Skill は互換用に残しつつ、新しい標準配置は `shared/`, `claude/`, `codex/`, `gemini/` に分ける。

## 目的

- 共通の手順・レビュー観点・出力形式を `shared/` に集約する
- Claude Code / Codex CLI / Gemini CLI の入口ファイルを分ける
- 既存の Claude Code 用 Skill とサブエージェント運用を壊さない
- シンボリックリンクで各ツールに必要な Skill だけを配置できるようにする

## ディレクトリ構成

```text
AgentSkills/
  README.md
  CLAUDE.md

  shared/
    test-orchestrator.md
    code-review.md
    cowork-chrome-launcher.md
    test-plan-template.md

  claude/
    skills/
      test-orchestrator/
        SKILL.md
        generate-player.ts
        run-visual-verify.sh
        templates/test-plan.md
      code-review/
        SKILL.md
      cowork-chrome-launcher/
        SKILL.md
        references/setup.md
        scripts/open-cowork-chrome.command
        scripts/open-cowork-chrome.bat
    agents/
      test-planner.md
      unit-runner.md
      e2e-runner.md
      e2e-visual-verify.md
      code-reviewer.md
      code-critic.md

  codex/
    skills/
      test-orchestrator/SKILL.md
      code-review/SKILL.md
      cowork-chrome-launcher/SKILL.md

  gemini/
    commands/
      test-orchestrator.toml
      code-review.toml
      cowork-chrome-launcher.toml

  # 互換用: 旧 ClaudeSkills 配置
  test-orchestrator/
  code-review/
  cowork-chrome-launcher/
  agents/
```

## shared/ の役割

`shared/` は特定ツールに依存しない本文を置く場所。

- `shared/test-orchestrator.md`: テスト計画、Unit/E2E、目視確認、`test-results.md` 記録
- `shared/code-review.md`: レビュー観点、独立レビュー、クロスレスポンス、Agreed/Single/Disputed 出力
- `shared/cowork-chrome-launcher.md`: Cowork Chrome 接続先固定フロー
- `shared/test-plan-template.md`: テスト計画書テンプレート

Claude Code の Agent tool、Codex CLI の実行環境、Gemini CLI の command 形式などは `shared/` に混ぜず、各ツール側の入口ファイルに書く。

## Skill 一覧

| Skill | 共通本文 | Claude | Codex | Gemini |
|---|---|---|---|---|
| `test-orchestrator` | `shared/test-orchestrator.md` | `claude/skills/test-orchestrator/SKILL.md` | `codex/skills/test-orchestrator/SKILL.md` | `gemini/commands/test-orchestrator.toml` |
| `code-review` | `shared/code-review.md` | `claude/skills/code-review/SKILL.md` | `codex/skills/code-review/SKILL.md` | `gemini/commands/code-review.toml` |
| `cowork-chrome-launcher` | `shared/cowork-chrome-launcher.md` | `claude/skills/cowork-chrome-launcher/SKILL.md` | `codex/skills/cowork-chrome-launcher/SKILL.md` | `gemini/commands/cowork-chrome-launcher.toml` |

`cowork-chrome-launcher` は Cowork / Claude Desktop の `Claude in Chrome` 互換 MCP がある環境向け。Codex CLI / Gemini CLI では、同等ツールがない限り実行不可として案内する。

## Claude Code での使い方

Claude Code は `~/.claude/skills/` の Skill ディレクトリと `~/.claude/agents/` のサブエージェントを読む。新構成では `claude/skills/` と `claude/agents/` をリンクする。

ディレクトリ全体をリンクする例:

```bash
mkdir -p ~/.claude
ln -s ~/Git/AgentSkills/claude/skills ~/.claude/skills
ln -s ~/Git/AgentSkills/claude/agents ~/.claude/agents
```

既に `~/.claude/skills` や `~/.claude/agents` が存在する場合は、ディレクトリ全体を置き換えず、個別にリンクする。

```bash
mkdir -p ~/.claude/skills ~/.claude/agents

ln -s ~/Git/AgentSkills/claude/skills/test-orchestrator ~/.claude/skills/test-orchestrator
ln -s ~/Git/AgentSkills/claude/skills/code-review ~/.claude/skills/code-review
ln -s ~/Git/AgentSkills/claude/skills/cowork-chrome-launcher ~/.claude/skills/cowork-chrome-launcher

ln -s ~/Git/AgentSkills/claude/agents/test-planner.md ~/.claude/agents/test-planner.md
ln -s ~/Git/AgentSkills/claude/agents/unit-runner.md ~/.claude/agents/unit-runner.md
ln -s ~/Git/AgentSkills/claude/agents/e2e-runner.md ~/.claude/agents/e2e-runner.md
ln -s ~/Git/AgentSkills/claude/agents/e2e-visual-verify.md ~/.claude/agents/e2e-visual-verify.md
ln -s ~/Git/AgentSkills/claude/agents/code-reviewer.md ~/.claude/agents/code-reviewer.md
ln -s ~/Git/AgentSkills/claude/agents/code-critic.md ~/.claude/agents/code-critic.md
```

旧 `ClaudeSkills` 配置を使っている既存環境は、そのまま動作する。移行時にリンク先を `ClaudeSkills/<skill>` から `AgentSkills/claude/skills/<skill>` へ切り替える。

## Codex CLI での使い方

Codex 用入口は `codex/skills/` に置く。Codex 側の Skill 読み込み先として `~/.agents/skills` を使う想定の例:

```bash
mkdir -p ~/.agents
ln -s ~/Git/AgentSkills/codex/skills ~/.agents/skills
```

既に `~/.agents/skills` が存在する場合は個別 Skill をリンクする。

```bash
mkdir -p ~/.agents/skills
ln -s ~/Git/AgentSkills/codex/skills/test-orchestrator ~/.agents/skills/test-orchestrator
ln -s ~/Git/AgentSkills/codex/skills/code-review ~/.agents/skills/code-review
ln -s ~/Git/AgentSkills/codex/skills/cowork-chrome-launcher ~/.agents/skills/cowork-chrome-launcher
```

Codex 用 `SKILL.md` は Claude Code のサブエージェントを前提にしない。共通本文を読み、Codex が利用できるローカルコマンド、Git、GitHub、テスト環境の範囲で実行する。

## Gemini CLI での使い方

Gemini CLI 用入口は `gemini/commands/` に `.toml` として置く。Gemini CLI 側の commands 読み込み先として `~/.gemini/commands` を使う想定の例:

```bash
mkdir -p ~/.gemini
ln -s ~/Git/AgentSkills/gemini/commands ~/.gemini/commands
```

既に `~/.gemini/commands` が存在する場合は、個別 command をリンクする。

```bash
mkdir -p ~/.gemini/commands
ln -s ~/Git/AgentSkills/gemini/commands/test-orchestrator.toml ~/.gemini/commands/test-orchestrator.toml
ln -s ~/Git/AgentSkills/gemini/commands/code-review.toml ~/.gemini/commands/code-review.toml
ln -s ~/Git/AgentSkills/gemini/commands/cowork-chrome-launcher.toml ~/.gemini/commands/cowork-chrome-launcher.toml
```

Gemini 側の `.toml` 仕様は環境差があり得るため、現時点では `name`, `description`, `prompt` の最小構成にしている。

## シンボリックリンク例

ユーザー指定の代表例:

```bash
# Claude Code
ln -s ~/Git/AgentSkills/claude/skills ~/.claude/skills

# Codex
ln -s ~/Git/AgentSkills/codex/skills ~/.agents/skills

# Gemini CLI
ln -s ~/Git/AgentSkills/gemini/commands ~/.gemini/commands
```

既存ディレクトリがある場合は、全体リンクではなく個別リンクを使う。

```bash
mkdir -p ~/.agents/skills
ln -s ~/Git/AgentSkills/codex/skills/code-review ~/.agents/skills/code-review
```

## 新しい Skill を追加するとき

1. まず `shared/<skill-name>.md` にツール非依存の本文を書く
2. Claude Code 用に `claude/skills/<skill-name>/SKILL.md` を作り、frontmatter の `name` と `description` を設定する
3. Codex CLI 用に `codex/skills/<skill-name>/SKILL.md` を作り、同じ `shared/` 本文を参照する
4. Gemini CLI 用に `gemini/commands/<skill-name>.toml` を作る
5. Claude 専用サブエージェントが必要なら `claude/agents/` に置き、README のリンク例を更新する
6. スクリプト、参照資料、テンプレート、assets は、そのツール固有なら各ツール配下、共通なら `shared/` に置く
7. 旧 `ClaudeSkills` 互換が必要な間は、ルート直下の互換 Skill も必要に応じて同期する

命名は小文字英数字とハイフンを使う。

## ClaudeSkills から AgentSkills への移行

移行は段階的に行う。

1. リポジトリ名を `ClaudeSkills` から `AgentSkills` に変更または再 clone する
2. 既存の `~/.claude/skills/<skill>` リンクはすぐには消さない
3. 新しいリンク先 `~/Git/AgentSkills/claude/skills/<skill>` を個別に作る
4. Claude Code で対象 Skill が読み込まれることを確認する
5. 問題なければ旧 `ClaudeSkills/<skill>` へのリンクを外す
6. Codex / Gemini では `codex/skills/` と `gemini/commands/` を新規にリンクする

旧ディレクトリ互換:

- `test-orchestrator/`
- `code-review/`
- `cowork-chrome-launcher/`
- `agents/`

これらは既存の Claude Code 運用を壊さないため当面残す。新規追加や大きな変更は、新構成の `shared/` と `claude/`, `codex/`, `gemini/` を優先する。

## Cowork / Claude Desktop の .skill パッケージ

Cowork は symlink ではなく `.skill` パッケージをインストールする方式。`claude/skills/cowork-chrome-launcher/` の入口は `shared/` を参照するため、単体フォルダだけを `.skill` 化すると共有本文が同梱されない。現時点で Cowork に単体インストールする場合は、互換用のルート直下 `cowork-chrome-launcher/` を使うか、パッケージ手順側で `shared/cowork-chrome-launcher.md` も同梱する。

詳細な Chrome プロファイル作成、拡張インストール、起動スクリプト登録、トラブルシューティングは `claude/skills/cowork-chrome-launcher/references/setup.md` を参照する。

## 開発メモ

- このリポジトリ自体にはビルドシステムやテストスイートはない
- Markdown の frontmatter、リンク、シンボリックリンク例を中心に確認する
- 既存の未コミット変更がある場合は、無関係な変更を戻さない

## Agent Workflow Kit / Common Rules

Claude Code / Codex 共通で使えるエージェント運用ルール、収束フェーズ用プロンプト、Git Hook、gate script を `common/` に追加しています。

詳細は `common/README.md` と `common/docs/design.md` を参照してください。
