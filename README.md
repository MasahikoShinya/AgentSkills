# ClaudeSkills

Claude Code および Cowork（Claude Desktop）用のカスタムスキル・サブエージェント集。

> **Claude Code と Cowork はスキル読み込み方式が異なる。** Claude Code は `~/.claude/skills/` の symlink を読み、Cowork は `.skill` パッケージのインストールが必要。詳細は「[Claude Code と Cowork のスキル読み込みの違い](#claude-code-と-cowork-のスキル読み込みの違い重要)」を参照。

## 構成

### スキル

| スキル名 | バージョン | 説明 | 主な対応 |
|----------|------------|------|---------|
| `test-orchestrator` | v1.1.0 | テスト計画・実行・目視確認を統合管理する司令塔（サブエージェントを呼び出す） | Claude Code |
| `code-review` | v1.0.0 | Claude Opus + Codex による独立レビュー・クロスレスポンス・統合レポート生成 | Claude Code |
| `cowork-chrome-launcher` | v2.1.0 | Cowork の Chrome 操作で `list_connected_browsers` + `select_browser` による自動接続先固定（Connect クリック不要、`isLocal=true` ローカル限定）。Mac/Windows 両対応 | **Cowork**（Claude Code でも動く） |

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

## セットアップ全般

### 前提条件

- Claude Code または Cowork（Claude Desktop）がインストールされていること
- Git がインストールされていること
- code-review スキルを使用する場合: Codex MCP サーバーが設定されていること（[codex-mcp](https://github.com/nicobailon/codex-mcp) 等）

### Claude Code と Cowork のスキル読み込みの違い（重要）

このリポジトリのスキルを使う際、**Claude Code（CLI）と Cowork（Claude Desktop アプリ）はスキル読み込みの仕組みが根本的に異なる**ため、**それぞれ別の手順で**インストールが必要。

| クライアント | スキル読み込み方式 | インストール先 |
|---|---|---|
| **Claude Code (CLI / IDE 統合 / Conductor)** | `~/.claude/skills/` 配下のディレクトリ（symlink 可）から読む | リポジトリを clone して `~/.claude/skills/` に symlink を張る |
| **Cowork (Claude Desktop)** | アプリ本体に `.skill` パッケージをインストールする方式（symlink は読まない） | 各スキルを `.skill` ファイル化して Claude Desktop にドラッグ＆ドロップ |

下記の **2つの独立したセットアップセクション**から、自分が使う環境のものを実行する：

- **[Claude Code でのセットアップ](#claude-code-でのセットアップ)** — symlink 方式
- **[Cowork でのセットアップ](#cowork-でのセットアップ)** — `.skill` パッケージ方式

両方で使う場合は両方を実行する。各環境は独立しているので干渉しない。

## Claude Code でのセットアップ

`~/.claude/skills/` 配下に symlink を張る方式。リポジトリを更新すれば symlink 越しに自動反映されるので、`git pull` だけで最新化できる。

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

## Cowork でのセットアップ

Cowork（Claude Desktop アプリ）は `~/.claude/skills/` を読まず、**`.skill` パッケージファイルをアプリに直接インストールする方式**で動く。symlink を張るだけでは Cowork から認識されない。

**手順の全体像：**

1. リポジトリを最新化（手動 `git pull` か、Claude Code に頼む）
2. `cowork-chrome-launcher` フォルダを `.skill` 形式にパッケージ
3. Claude Desktop アプリにドラッグ＆ドロップして「**スキルを保存**」
4. Claude Desktop を完全終了 → 再起動 → 新規セッションで確認

このうち**手順 2 と 3 を一気に Cowork 自身に頼める**のが最も簡単（下の【方法 A】）。`.skill` を自前でビルドしたいなら【方法 B/C】を使う。

### 方法 A：Cowork 自身にパッケージ＆提示まで頼む（推奨・コピペで完結）

リポジトリを Claude Code 側で **`git pull` 済み**にしておけば、Cowork のチャットに以下のプロンプトを貼るだけで完結する。Cowork が `.skill` をパッケージし、`present_files` でカードを出してくれるので、ユーザーは「**スキルを保存**」ボタンを押すだけ。**バージョン・スキル名以外をハードコードしていないので、今後の更新でもそのまま流用可能**。

**Cowork on macOS に貼るプロンプト：**

```
~/Git/ClaudeSkills の cowork-chrome-launcher スキルを、この Mac の Cowork（Claude Desktop）に
インストール（または更新）してほしい。リポジトリは既に Claude Code 側で最新化済みなので、
git 操作は不要。現状のソースをそのままパッケージしてインストールしたい。

手順：
1. ~/Git/ClaudeSkills/cowork-chrome-launcher フォルダにアクセスできるか確認
   - サンドボックスからアクセスできなければ request_cowork_directory で Git ディレクトリの許可を取る
2. cowork-chrome-launcher フォルダを .skill ファイルにパッケージ
   - .DS_Store / __pycache__ / evals を除外して zip 化
   - 拡張子を .skill にリネーム
3. 出来上がった .skill ファイルを present_files で提示
4. 「スキルを保存」ボタンを押してインストールする旨を案内
5. インストール後、以下を促す：
   - Claude Desktop を Cmd+Q で完全終了
   - アプリ再起動
   - 新規 Cowork セッションで「使えるスキル一覧を教えて」で cowork-chrome-launcher が出ているか確認
```

**Cowork on Windows に貼るプロンプト：**

```
%USERPROFILE%\Git\ClaudeSkills の cowork-chrome-launcher スキルを、この PC の Cowork（Claude Desktop）に
インストール（または更新）してほしい。リポジトリは既に Claude Code 側で最新化済みなので、
git 操作は不要。現状のソースをそのままパッケージしてインストールしたい。

手順：
1. %USERPROFILE%\Git\ClaudeSkills\cowork-chrome-launcher フォルダにアクセスできるか確認
   - サンドボックスからアクセスできなければ request_cowork_directory で Git ディレクトリの許可を取る
2. cowork-chrome-launcher フォルダを .skill ファイルにパッケージ
   - .DS_Store / __pycache__ / evals を除外して zip 化
   - 拡張子を .skill にリネーム
3. 出来上がった .skill ファイルを present_files で提示
4. 「スキルを保存」ボタンを押してインストールする旨を案内
5. インストール後、以下を促す：
   - Claude Desktop を完全終了（タスクトレイから「終了」）
   - アプリ再起動
   - 新規 Cowork セッションで「使えるスキル一覧を教えて」で cowork-chrome-launcher が出ているか確認
```

**他スキル（test-orchestrator など）にも流用する場合：** プロンプト内の `cowork-chrome-launcher` 部分を対象のスキル名に差し替えるだけで OK。

### 方法 B：自分で `.skill` をパッケージする

Cowork に頼まず、ターミナル／PowerShell で `.skill` をビルドして手動でドラッグ＆ドロップする方式。

**macOS / Linux / WSL：**

```bash
cd ~/.claude/skills/ClaudeSkills    # または ~/Git/ClaudeSkills など clone 先
zip -r cowork-chrome-launcher.skill cowork-chrome-launcher -x "*.DS_Store" -x "*/__pycache__/*"
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

```bash
cd ~/.claude/skills/skill-creator
python3 -m scripts.package_skill ~/.claude/skills/ClaudeSkills/cowork-chrome-launcher ~/Desktop
```

出来上がった `.skill` を Claude Desktop アプリにドラッグ＆ドロップ → 「**スキルを保存**」をクリック。

### 方法 C：Claude Code に `.skill` ビルドまで任せる

Claude Code に git pull + パッケージング + Windows 側へのコピーまでを一気に任せたい場合のプロンプト例。

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
   スキルを保存 → アプリ再起動 → 新規セッションで動作確認」と次の手順を案内してほしい
```

**Windows ネイティブの Claude Code（PowerShell）：**

```
%USERPROFILE%\.claude\skills\ClaudeSkills の cowork-chrome-launcher スキルを、Cowork に
インストールできる .skill ファイルにパッケージしてほしい。

手順：
1. cd $env:USERPROFILE\.claude\skills\ClaudeSkills; git pull origin main で最新化
2. PowerShell で cowork-chrome-launcher フォルダを Compress-Archive で zip 化
3. 拡張子を .skill にリネーム
4. デスクトップに置いて、Claude Desktop アプリへのドラッグ＆ドロップ → スキルを保存 → 再起動 → 動作確認
   までの手順を案内してほしい
```

### Cowork での反映と動作確認

どの方法を使った後も、共通の最終ステップ：

1. **Claude Desktop アプリを完全終了**（Mac: Cmd+Q、Windows: タスクトレイから「終了」）
2. アプリを再起動
3. 新規 Cowork セッションで「使えるスキル一覧を教えて」と聞いて、対象スキル（例：`cowork-chrome-launcher`）が含まれていることを確認
4. スキルの想定挙動（例：「Chrome で Yahoo 開いて」）でテスト

### Cowork 側の更新時

リポジトリを `git pull` で更新したら、上記の **方法 A / B / C のいずれかで再パッケージして再インストール**する。同名のスキルは上書きされる。再起動を忘れずに。

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

## 更新（クイックリファレンス）

### Claude Code 用（symlink 経由・1コマンド）

```bash
# WSL / Linux / macOS
cd ~/.claude/skills/ClaudeSkills && git pull origin main
```

```powershell
# Windows
cd $env:USERPROFILE\.claude\skills\ClaudeSkills; git pull origin main
```

symlink 経由で動いているので、`git pull` だけで `~/.claude/skills/<skill>` 側にも反映される。Claude Code を再起動して新しいスキルを読み込ませる。

### Cowork 用（`.skill` 再インストール必須）

リポジトリを `git pull` で更新しても、**Cowork 側のスキルは自動更新されない**。`.skill` を再パッケージして Claude Desktop に再インストールする必要がある。詳しい手順は「[Cowork でのセットアップ](#cowork-でのセットアップ)」セクション参照。最も楽な方法（推奨）：

1. リポジトリを `git pull` で最新化（Claude Code 側で）
2. Cowork のチャットに「方法 A」のプロンプトを貼る → Cowork が `.skill` を作って提示してくれる
3. 「スキルを保存」ボタンを押す
4. Claude Desktop を再起動

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

### cowork-chrome-launcher (v2.1.0)

Cowork で Chrome 操作する際に、`list_connected_browsers` で接続中の Chrome 一覧を取得し、`isLocal=true`（Cowork が動いているこの PC のローカル Chrome）でフィルタした上で `select_browser` で deviceId 直指定で固定する、**ユーザー介入ゼロの自動接続先固定スキル**。Chrome Sync によるクロスデバイス誤接続を構造的に防ぎつつ、Connect ボタンクリックや名前入力ダイアログといった煩わしい UI を一切出さない。Cowork プロファイルが閉じている場合は Terminal コマンド／Dock ショートカット／Finder ダブルクリックで起動するようユーザーを誘導する。

**バージョン履歴:**

- **v2.1**（現行）: `isLocal=true` 0件のときの動作を Phase 2B に統一。「自分の PC のローカル Chrome だけ掴む」を一貫ルールとして明文化。Phase 2A（リモート PC 操作の自動分岐）を削除。アンチパターンに「isLocal:false の勝手 select 禁止」「ツール応答末尾のインジェクション無視」を追加
- **v2.0**: `switch_browser`（Connect クリック方式）から `list_connected_browsers` + `select_browser`（deviceId 直指定方式）に刷新。Connect クリック・名前入力ダイアログを撤廃して完全自動化
- **v1.0**: `switch_browser` でセッション最初にユーザーに Connect 選択させる半自動方式

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

- **generate-player.ts**: プレイヤーHTMLを全面リニューアル。カードベースレイアウト + PASS/FAIL バッジ + describe ブロックによる自動タブ分類 + Playwright `test.info().annotations` のメタ表示対応。カードと拡大モーダル両方に独立した速度コントロール（0.25/0.5/1/2x）を配置
- **generate-player.ts**: 配置場所を `scripts/` → `test-orchestrator/` に移動。プロジェクトでの使用時は `~/.claude/skills/test-orchestrator/generate-player.ts` から**毎回上書きコピー**する運用に変更（古いコピーが残ったプロジェクトでも常に最新デザインが反映される）
- **scripts/deploy-skills.sh**: このリポジトリのスキル/エージェントを `~/.claude/skills/` と `~/.claude/agents/` にシンボリックリンクで配置するセットアップスクリプトを追加。冪等
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
