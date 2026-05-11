# ClaudeSkills

Claude Code および Cowork（Claude Desktop）用のカスタムスキル・サブエージェント集。

> **Claude Code と Cowork はスキル読み込み方式が異なる。** Claude Code は `~/.claude/skills/` の symlink を読み、Cowork は `.skill` パッケージのインストールが必要。詳細は「[Claude Code と Cowork のスキル読み込みの違い](#claude-code-と-cowork-のスキル読み込みの違い重要)」を参照。

## 構成

### スキル

| スキル名 | バージョン | 説明 | 主な対応 |
|----------|------------|------|---------|
| `test-orchestrator` | v1.1.0 | テスト計画・実行・目視確認を統合管理する司令塔（サブエージェントを呼び出す） | Claude Code |
| `code-review` | v1.0.0 | Claude Opus + Codex による独立レビュー・クロスレスポンス・統合レポート生成 | Claude Code |
| `cowork-chrome-launcher` | v2.0.0 | Cowork の Chrome 操作で `list_connected_browsers` + `select_browser` による自動接続先固定（Connect クリック不要）。Mac/Windows 両対応 | **Cowork**（Claude Code でも動く） |

### サブエージェント（`~/.claude/agents/` に配置）

隔離コンテキストで実行される実働部隊。結果のサマリーだけがメインコンテキストに返る。

| エージェント名 | 親スキル | 説明 |
|----------------|----------|------|
| `test-planner` | test-orchestrator | テスト項目の洗い出しとUnit/E2E振り分け |
| `unit-runner` | test-orchestrator | ユニットテスト実行・カバレッジ測定・自律修正 |
| `e2e-runner` | test-orchestrator | E2Eテスト実行・DB環境管理・自律修正 |
| `e2e-visual-verify` | test-orchestrator | E2Eテストの動画録画・スクリーンショット・目視確認素材の生成 |
| `code-reviewer` | code-review | Claude Opusによる独立レビュー・クロスレスポンス |
| `code-critic` | code-review | Codexによる独立レビュー・クロスレスポンス |

### アーキテクチャ

```
test-orchestrator（スキル・メインコンテキスト）
    |  Agent tool で呼び出し
    |--- test-planner（隔離）--- 計画だけ返す
    |--- unit-runner（隔離）--- 結果だけ返す
    |--- e2e-runner（隔離）--- 結果だけ返す
    |--- e2e-visual-verify（隔離）--- 動画・スクショパスだけ返す
    |
    メインコンテキストで結果をまとめてユーザーに報告

code-review（スキル・メインコンテキスト）
    |  Phase 1: 並列独立レビュー
    |--- code-reviewer（Opus・隔離）--- レビュー結果A
    |--- code-critic（Codex・隔離）--- レビュー結果B
    |
    |  Phase 2: 並列クロスレスポンス
    |--- code-reviewer（Opus・隔離）--- Codex指摘への根拠付き応答
    |--- code-critic（Codex・隔離）--- Opus指摘への根拠付き応答
    |
    メインコンテキストで統合レポート（Agreed / Single / Disputed）
```

## セットアップ

### 前提条件

- Claude Code がインストールされていること
- Git がインストールされていること
- code-review スキルを使用する場合: Codex MCP サーバーが設定されていること（[codex-mcp](https://github.com/nicobailon/codex-mcp) 等）

### Claude Code と Cowork のスキル読み込みの違い（重要）

このリポジトリのスキルを使う際、**Claude Code（CLI）と Cowork（Claude Desktop アプリ）はスキル読み込みの仕組みが根本的に異なる**ため、それぞれに合わせたインストールが必要。

| クライアント | スキル読み込み方式 | このリポジトリでのインストール手順 |
|---|---|---|
| **Claude Code (CLI / IDE 統合 / Conductor)** | `~/.claude/skills/` 配下のディレクトリ（symlink 可）から読む | このリポジトリを clone して `~/.claude/skills/` に symlink を張る（次節「WSL2 / Linux / macOS」「Windows」参照） |
| **Cowork (Claude Desktop)** | アプリ本体に `.skill` パッケージをインストールする方式（symlink は読まない） | 各スキルを `.skill` ファイルにパッケージし、Claude Desktop アプリにドラッグ＆ドロップして「Save skill」（後述「Cowork（Claude Desktop）で使う場合」参照） |

つまり**Cowork で使いたいスキルは、別途 `.skill` ファイル化して個別にインストール**する必要がある。Claude Code 用に symlink を張ってあっても Cowork は読まない。

#### 複数環境を併用する場合

同一ユーザーが複数環境で同じスキルを使う運用なら、**それぞれの環境で独立に手順を踏む**：

- Mac で Claude Code → Mac 側で clone + symlink
- Mac で Cowork → Mac の Claude Desktop に `.skill` をインストール
- Windows で Cowork → Windows の Claude Desktop に `.skill` をインストール
- WSL で Claude Code → WSL 内で clone + symlink

各環境は独立しているので干渉しない。更新時はそれぞれで pull / 再インストール。

### WSL2 / Linux / macOS

```bash
# スキルディレクトリに移動（なければ作成）
mkdir -p ~/.claude/skills ~/.claude/agents
cd ~/.claude/skills

# リポジトリをクローン
git clone https://github.com/MasahikoShinya/ClaudeSkills.git

# スキルのシンボリックリンクを作成
ln -s ClaudeSkills/test-orchestrator test-orchestrator
ln -s ClaudeSkills/code-review code-review
ln -s ClaudeSkills/cowork-chrome-launcher cowork-chrome-launcher

# サブエージェントのシンボリックリンクを作成
cd ~/.claude/agents
ln -s ../skills/ClaudeSkills/agents/test-planner.md test-planner.md
ln -s ../skills/ClaudeSkills/agents/unit-runner.md unit-runner.md
ln -s ../skills/ClaudeSkills/agents/e2e-runner.md e2e-runner.md
ln -s ../skills/ClaudeSkills/agents/e2e-visual-verify.md e2e-visual-verify.md
ln -s ../skills/ClaudeSkills/agents/code-reviewer.md code-reviewer.md
ln -s ../skills/ClaudeSkills/agents/code-critic.md code-critic.md
```

### Windows (PowerShell 管理者権限)

```powershell
# ディレクトリ作成
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\skills"
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\agents"
Set-Location "$env:USERPROFILE\.claude\skills"

# リポジトリをクローン
git clone https://github.com/MasahikoShinya/ClaudeSkills.git

# スキルのシンボリックリンク
New-Item -ItemType SymbolicLink -Path "test-orchestrator" -Target "ClaudeSkills\test-orchestrator"
New-Item -ItemType SymbolicLink -Path "code-review" -Target "ClaudeSkills\code-review"
New-Item -ItemType SymbolicLink -Path "cowork-chrome-launcher" -Target "ClaudeSkills\cowork-chrome-launcher"

# サブエージェントのシンボリックリンク
Set-Location "$env:USERPROFILE\.claude\agents"
New-Item -ItemType SymbolicLink -Path "test-planner.md" -Target "..\skills\ClaudeSkills\agents\test-planner.md"
New-Item -ItemType SymbolicLink -Path "unit-runner.md" -Target "..\skills\ClaudeSkills\agents\unit-runner.md"
New-Item -ItemType SymbolicLink -Path "e2e-runner.md" -Target "..\skills\ClaudeSkills\agents\e2e-runner.md"
New-Item -ItemType SymbolicLink -Path "e2e-visual-verify.md" -Target "..\skills\ClaudeSkills\agents\e2e-visual-verify.md"
New-Item -ItemType SymbolicLink -Path "code-reviewer.md" -Target "..\skills\ClaudeSkills\agents\code-reviewer.md"
New-Item -ItemType SymbolicLink -Path "code-critic.md" -Target "..\skills\ClaudeSkills\agents\code-critic.md"
```

### Claude Code にセットアップを任せる

別 PC・新規環境への展開、または単一スキル追加時は、以下のプロンプトを Claude Code に渡せば clone / symlink / 実行権限付与まで自動で処理できる。OS 判定もするので、macOS・Linux・WSL・Windows のどれでもそのまま使える。

**macOS / Linux / WSL の場合:**

```
https://github.com/MasahikoShinya/ClaudeSkills.git リポジトリの cowork-chrome-launcher スキルを、Claude Code / Cowork から使えるようにセットアップしてほしい。

やること：
1. リポジトリが未クローンなら ~/.claude/skills/ にクローン、既にあれば git pull で最新化
2. ~/.claude/skills/cowork-chrome-launcher というシンボリックリンクを作成し、(clone 先)/cowork-chrome-launcher を指すようにする（既存ならスキップ）
3. open-cowork-chrome.command に実行権限が無ければ chmod +x で付与
4. 結果をまとめて報告（リンク先・権限・確認コマンド）

完了したら最後に「Claude デスクトップアプリを再起動 → 新規セッションで試せ」と念押ししてほしい。
```

**Windows (PowerShell) の場合:**

```
https://github.com/MasahikoShinya/ClaudeSkills.git リポジトリの cowork-chrome-launcher スキルを、Cowork から使えるようにセットアップしてほしい。

やること：
1. リポジトリが未クローンなら %USERPROFILE%\.claude\skills\ にクローン、既にあれば git pull で最新化
2. %USERPROFILE%\.claude\skills\cowork-chrome-launcher という NTFS シンボリックリンクを作成し、(clone 先)\cowork-chrome-launcher を指すようにする（既存ならスキップ）
3. リンク作成に管理者権限または開発者モード ON が必要なら、先に案内する
4. 結果をまとめて報告（リンク先・確認コマンド）

完了したら最後に「Claude デスクトップアプリを再起動 → 新規セッションで試せ」と念押ししてほしい。
```

他スキルを追加する時も、`cowork-chrome-launcher` 部分をスキル名に差し替えれば同じ形で使える。

## Cowork（Claude Desktop）で使う場合

Cowork（Claude Desktop アプリ）は `~/.claude/skills/` を読まず、**`.skill` パッケージファイルをアプリに直接インストールする方式**で動く。symlink を張るだけでは Cowork から認識されない。各スキルを個別に `.skill` ファイル化して Cowork にインストールする手順が必要。

### スキルを `.skill` にパッケージする

このリポジトリのスキルフォルダ（例：`cowork-chrome-launcher`）を zip 化して拡張子を `.skill` にすれば、Cowork にインストール可能なパッケージになる。

**macOS / Linux / WSL：**

```bash
cd ~/.claude/skills/ClaudeSkills
zip -r cowork-chrome-launcher.skill cowork-chrome-launcher -x "*.DS_Store" -x "*/__pycache__/*"
# 出力: ~/.claude/skills/ClaudeSkills/cowork-chrome-launcher.skill
```

WSL から Windows の Cowork に渡したい場合は、出力した `.skill` を Windows 側にコピー：

```bash
cp cowork-chrome-launcher.skill /mnt/c/Users/<ユーザー名>/Desktop/
```

**Windows ネイティブ（PowerShell）：**

```powershell
Compress-Archive `
  -Path "$env:USERPROFILE\.claude\skills\ClaudeSkills\cowork-chrome-launcher" `
  -DestinationPath "$env:USERPROFILE\Desktop\cowork-chrome-launcher.zip" -Force
Rename-Item "$env:USERPROFILE\Desktop\cowork-chrome-launcher.zip" "cowork-chrome-launcher.skill"
```

**skill-creator スキルを使う場合（インストール済みなら）：**

skill-creator が同じ環境にインストールされていれば、`package_skill.py` で同等のことができる：

```bash
cd ~/.claude/skills/skill-creator
python3 -m scripts.package_skill ~/.claude/skills/ClaudeSkills/cowork-chrome-launcher ~/Desktop
```

### Cowork にインストールする

1. 出来上がった `.skill` ファイルを **Claude Desktop アプリ**（Cowork モード）にドラッグ＆ドロップ
2. チャットに「**Save skill**」ボタンが出るのでクリック
3. インストール完了

または、Cowork のチャットでファイルを presented_files 経由で出してもらって「Save skill」ボタンから入れる方法もある。

### 反映と動作確認

1. **Claude Desktop アプリを完全終了**（Mac: Cmd+Q、Windows: タスクトレイから「終了」）
2. 再起動
3. 新規 Cowork セッションを開いて「使えるスキル一覧を教えて」で対象スキルが入っているか確認

### 更新時の手順

このリポジトリを `git pull` で更新した後、Cowork 側にも反映するには：

1. `.skill` を再パッケージ（上記コマンドを再実行）
2. Cowork で再インストール（古い同名スキルは上書きされる）
3. Claude Desktop 再起動

### Claude Code にこの作業を任せる場合

`.skill` パッケージング＋ Windows へのコピーまでを Claude Code に委ねるプロンプト例：

**WSL の Claude Code に渡す場合（→ Windows Cowork 用）：**

```
~/.claude/skills/ClaudeSkills の cowork-chrome-launcher スキルを、Windows の Cowork（Claude Desktop）に
インストールできる .skill ファイル形式にパッケージしてほしい。

手順：
1. cd ~/.claude/skills/ClaudeSkills && git pull origin main で最新化
2. cowork-chrome-launcher フォルダを zip 化して .skill 形式にする
   （例: zip -r cowork-chrome-launcher.skill cowork-chrome-launcher -x "*.DS_Store" -x "*/__pycache__/*"）
3. 出来上がった cowork-chrome-launcher.skill を /mnt/c/Users/<Windowsユーザー名>/Desktop/ にコピー
4. 完了後、「Windows のデスクトップに .skill を置いた。Claude Desktop アプリにドラッグ＆ドロップして
   Save skill → アプリ再起動 → 新規セッションで動作確認」と次の手順を案内してほしい
```

**Windows ネイティブの Claude Code（または PowerShell ベース）：**

```
%USERPROFILE%\.claude\skills\ClaudeSkills の cowork-chrome-launcher スキルを、Cowork に
インストールできる .skill ファイルにパッケージしてほしい。

手順：
1. cd $env:USERPROFILE\.claude\skills\ClaudeSkills; git pull origin main で最新化
2. PowerShell で cowork-chrome-launcher フォルダを Compress-Archive で zip 化
3. 拡張子を .skill にリネーム
4. デスクトップに置いて、Claude Desktop アプリへのドラッグ＆ドロップ → Save skill → 再起動 → 動作確認
   までの手順を案内してほしい
```

## セットアップの確認

```bash
# スキル
ls -la ~/.claude/skills/ | grep -E "(test-orchestrator|code-review|cowork-chrome-launcher)"

# サブエージェント
ls -la ~/.claude/agents/

# 期待される出力:
# ~/.claude/skills/
#   test-orchestrator -> ClaudeSkills/test-orchestrator
#   code-review -> ClaudeSkills/code-review
#   cowork-chrome-launcher -> ClaudeSkills/cowork-chrome-launcher
#
# ~/.claude/agents/
#   test-planner.md -> .../ClaudeSkills/agents/test-planner.md
#   unit-runner.md -> .../ClaudeSkills/agents/unit-runner.md
#   e2e-runner.md -> .../ClaudeSkills/agents/e2e-runner.md
#   e2e-visual-verify.md -> .../ClaudeSkills/agents/e2e-visual-verify.md
#   code-reviewer.md -> .../ClaudeSkills/agents/code-reviewer.md
#   code-critic.md -> .../ClaudeSkills/agents/code-critic.md
```

## 更新

### Claude Code 用（symlink 経由）

```bash
# WSL / Linux / macOS
cd ~/.claude/skills/ClaudeSkills
git pull origin main
```

```powershell
# Windows
cd $env:USERPROFILE\.claude\skills\ClaudeSkills
git pull origin main
```

symlink で繋がっているので、`git pull` だけで `~/.claude/skills/<skill>` 側にも変更が反映される。Claude Code を再起動して新しいスキルを読み込ませる。

### Cowork 用（`.skill` 再インストール）

リポジトリを `git pull` で更新しても、**Cowork 側のスキルは自動更新されない**。`.skill` を再パッケージして Claude Desktop に再インストールする必要がある：

1. 「[Cowork（Claude Desktop）で使う場合](#coworkclaude-desktopで使う場合)」セクションの手順で `.skill` を再パッケージ
2. Claude Desktop アプリにドラッグ＆ドロップ → 「Save skill」（同名スキルが上書きされる）
3. Claude Desktop を再起動して新版を読み込ませる

複数環境で使っている場合は、それぞれの環境で個別に更新する。

## コミュニティスキル（オプション）

必要に応じて [awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) から個別にインストール可能。グローバルではなくプロジェクトローカル（`<project>/.claude/skills/`）への配置を推奨。

---

## スキル詳細

### test-orchestrator (v1.1.0)

テストの計画・実行・目視確認を統合管理する司令塔スキル。
実際の作業は `~/.claude/agents/` のサブエージェントに委譲し、メインコンテキストでは結果の集約と報告のみ行う。

**サブエージェント（`agents/` に配置、`~/.claude/agents/` にリンク）:**
| 名前 | 役割 | 実行場所 |
|------|------|----------|
| `test-planner` | テスト計画作成 | 隔離コンテキスト |
| `unit-runner` | ユニットテスト実行・自律修正 | 隔離コンテキスト |
| `e2e-runner` | E2Eテスト実行・DB管理 | 隔離コンテキスト |
| `e2e-visual-verify` | 動画録画・スクショ・目視確認素材生成 | 隔離コンテキスト |

**使用例:**
```
User: このプロジェクトのテストを実行して
User: ユニットテストだけ実行して
User: テスト計画を作成して
User: E2Eの動作確認をして
```

詳細は [test-orchestrator/SKILL.md](./test-orchestrator/SKILL.md) を参照。

---

### code-review (v1.0.0)

2つの異なるAIモデル（Claude Opus + Codex）による独立レビューとクロスレスポンスを統合し、信頼度付きのレビューレポートを生成するスキル。矛盾する指摘はAIが裁定せず、人間の判断に委ねる。

**フロー:**
```
1. 並列独立レビュー（Opus + Codex が別々にレビュー）
2. 並列クロスレスポンス（互いの指摘に根拠付きで応答）
3. 統合レポート（Agreed / Single / Disputed に分類）
```

**サブエージェント（`agents/` に配置、`~/.claude/agents/` にリンク）:**
| 名前 | 役割 | 実行場所 |
|------|------|----------|
| `code-reviewer` | Claude Opusによる独立レビュー・クロスレスポンス | 隔離コンテキスト |
| `code-critic` | Codexによる独立レビュー・クロスレスポンス | 隔離コンテキスト |

**前提条件:**
- Codex MCP サーバーが設定されていること（`mcp__codex__codex` が利用可能）

**使用例:**
```
User: このコードをレビューして
User: 変更をレビューして
User: PR #123 をレビューして
User: セキュリティ観点でレビューして
```

詳細は [code-review/SKILL.md](./code-review/SKILL.md) を参照。

---

### cowork-chrome-launcher (v2.0.0)

Cowork で Chrome 操作する際に、`list_connected_browsers` で接続中の Chrome 一覧を取得し、`isLocal=true`（Cowork が動いているこの PC のローカル Chrome）でフィルタした上で `select_browser` で deviceId 直指定で固定する、**ユーザー介入ゼロの自動接続先固定スキル**。Chrome Sync によるクロスデバイス誤接続を構造的に防ぎつつ、Connect ボタンクリックや名前入力ダイアログといった煩わしい UI を一切出さない。Cowork プロファイルが閉じている場合は Terminal コマンド／Dock ショートカット／Finder ダブルクリックで起動するようユーザーを誘導する。

**v1 → v2 の主な変更:**
- v1：`switch_browser` でブロードキャスト → ユーザーが Connect ボタンを押す（毎セッション操作必要）
- v2：`list_connected_browsers` + `select_browser` で deviceId 直指定（**操作不要、完全自動**）

**同梱物:**
| 内容 | 説明 |
|------|------|
| `scripts/open-cowork-chrome.command` | Mac 用起動スクリプト（Local State から Cowork プロファイルを case-insensitive に検出して起動） |
| `scripts/open-cowork-chrome.bat` | Windows 用起動スクリプト（同上） |
| `references/setup.md` | Cowork 専用プロファイルの作成、拡張のインストール、自動起動・Dock ショートカット設定、トラブルシューティング |

**使用例:**
```
User: Chrome で Yahoo を開いて
User: このサイトのスクショを撮って
User: ウェブページの内容を要約して
User: Cowork で Chrome が動かないんだけど
User: Cowork プロファイルってどう作るの？
```

**前提条件:**
- Cowork 専用の Chrome プロファイル（Google アカウント未ログイン）が作成済み
- そのプロファイルに `Claude for Chrome` 拡張がインストール・サインイン済み
- Cowork で使う場合は `.skill` 形式でパッケージして Claude Desktop にインストール
- セットアップ未完了の場合は `references/setup.md` を参照

詳細は [cowork-chrome-launcher/SKILL.md](./cowork-chrome-launcher/SKILL.md) を参照。

---

## 変更履歴

### 2026-04-16

- **cowork-chrome-launcher v1.0.0**: Cowork の Chrome 操作前にプロファイル接続を確認・誘導する運用スキルを追加

### 2026-05-11

- **e2e-visual-verify**: カーソル可視化を実証済み実装に同期。赤い矢印(#FF3333) → 白フィル+黒輪郭の矢印SVG + 青いリップルクリック演出。`injectCursor`/`ensureCursor` → `attachCursorOverlay`（`addInitScript`でSPA遷移後も自動再注入）

### 2026-04-08

- **e2e-visual-verify**: プレイヤー生成を固定スクリプト（`scripts/generate-player.ts`）に変更。毎回同一デザインのHTMLを出力

### 2026-04-07

- **e2e-visual-verify**: エージェント定義を実装済みコード（showTitle/showResult）に統一
- **e2e-visual-verify**: スクリーンショットをシナリオ名でディレクトリ分けして紐づけ
- **e2e-visual-verify**: プレイヤーをサイドバー廃止→動画下にシナリオ一覧+スクリーンショット表示に変更

### 2026-04-06

- **code-review v1.0.0**: Claude Opus + Codex による独立レビュー・クロスレスポンス・統合レポート生成スキルを追加
- **code-reviewer / code-critic**: code-review用サブエージェントを追加
- 廃止スキル（response-workflow, serena-memory-manager, error-reporting-format）を削除
- README整理 — 廃止スキル削除、コミュニティスキルをオプション化

### 2026-04-05

- **e2e-visual-verify**: テスト完了後にプレイヤーを自動でブラウザオープンする機能を追加
- **error-reporting-format**: サブエージェントに統合、スキル廃止

### 2026-04-04

- サブエージェントを `~/.claude/agents/` 対応に分離
- README更新 — サブエージェント構成とセットアップ手順を追加

### 2026-04-03

- **response-workflow v1.2.0**: 入力分解、TDD、デグレ対策を追加
- **response-workflow v1.0.0**: スキル追加
- **error-reporting-format**: スキル追加
- **serena-memory-manager**: スキル追加
- **test-orchestrator v1.1.0**: 更新

### 初回リリース

- **test-orchestrator v1.0.0**: テスト計画・実行・目視確認の司令塔スキルを追加
- コミュニティスキル（awesome-claude-skills）のセットアップスクリプトを追加

## ライセンス

MIT License
