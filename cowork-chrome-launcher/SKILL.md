---
name: cowork-chrome-launcher
description: Cowork で Chrome / ブラウザ操作が必要になったら、実作業の前に必ずこのスキルを使うこと。このスキルは (1) `list_connected_browsers` で接続中の Chrome 一覧を取得し、(2) `isLocal: true`（Cowork が動いている PC のローカル Chrome）を自動判別して、(3) `select_browser` で deviceId 直指定で固定する、という**ユーザー介入ゼロの接続先固定フロー**を提供する。これにより Chrome Sync によるクロスデバイス誤接続を構造的に防ぎつつ、Connect ボタンクリックや名前入力ダイアログといった煩わしい UI を一切出さずに済む。ユーザーが「Chrome で」「ブラウザで」「〇〇のサイトを開いて」「ウェブページを読んで」「スクショを撮って」「フォームに入力して」「この URL を開いて」など、Cowork のブラウザ操作を必要とする依頼をした場合、**実作業の前に必ずこのスキルを発動**すること。また「Cowork で Chrome が動かない」「プロファイルの作り方」「別 PC でも Cowork を使いたい」など環境構築系の質問が出たときも、同梱の `references/setup.md` を案内するためにこのスキルを使うこと。Claude はサンドボックスから Chrome を直接起動できない前提で、Chrome の起動はユーザーの Terminal 実行 / Dock ショートカットクリック / Login Items 自動起動に委ねるが、接続先解決はこのスキルが完全自動で担う。
---

# Cowork Chrome Launcher (v2)

Cowork で Chrome 操作する際の「どの PC を掴むか」問題を、**`list_connected_browsers` + `select_browser` の組み合わせ**で完全自動化する運用スキル。Connect ボタンや名前入力など、ユーザーの追加操作を一切要求しない。

## ⚠️ 最重要ルール（最初に読むこと）

**Claude は自分では Chrome を起動できない。** サンドボックスの外にあるユーザーの Chrome アプリに対して、以下はすべて**不可能**なので試さない：

- Bash で `open` / `chrome.exe` を叩く → サンドボックス内 Linux が動くだけで Mac/Windows には届かない
- プラグインや MCP を検索する → このスキルが提供する以上の起動手段はない
- `request_cowork_directory` などで Chrome を探す → 用途違い

**Chrome の起動は常にユーザーの手元の動作（Terminal コマンド / Dock ショートカット / Login Items による自動起動）に委ねる。** スキルは「どの Chrome を選ぶか」だけ自動化し、「Chrome の起動」は誘導するだけ。

**Connect ボタンの broadcast（`switch_browser`）は v1 で使っていたが v2 では原則使わない。** `list_connected_browsers` + `select_browser` で deviceId を直指定すれば、Connect ボタン UI を出さずに接続先を固定できる。スキル発動のたびに Connect クリックを要求するのはユーザー体験として悪い。

## 背景：なぜ v2 で書き換えたか

v1 では `switch_browser` をセッション最初に呼んでブロードキャスト → ユーザーに Connect ボタンクリックを依頼する設計だった。これは silent 誤接続を防ぐ目的としては機能したが、以下の問題があった：

- 毎セッション開始時に Connect クリックが必要で煩雑
- 初回 Connect 時に名前入力ボックスが出てさらに煩雑
- ユーザーが操作を忘れるとタイムアウト挙動が読めない

v2 では `list_connected_browsers` で候補リストを取得した上で、`isLocal: true`（Cowork セッションが動いているこの PC 上の Chrome）でフィルタして自動的に絞り込む。これにより Connect ボタン UI を一切出さずに、かつ silent 誤接続も発生しない設計が実現した。

## Activation Triggers

以下のいずれかに該当する発話・状況で発動する。

- ブラウザ／Chrome 関連の操作依頼： "Chrome で", "ブラウザで", "サイトを開いて", "ウェブページを読んで", "スクショを撮って", "フォームに入力して", "この URL を開いて"
- `mcp__Claude_in_Chrome__*` 系ツールを呼ぼうとしている直前
- Cowork の Chrome 設定に関する質問： "Cowork で Chrome が動かない", "プロファイルの作り方", "Cowork Chrome のセットアップ", "別 PC でも使いたい"

## Execution Protocol

### Phase 1: 接続先の自動解決（v2 のキモ）

**セッション内で Chrome 操作が初めて必要になったら、必ずこの Phase を実行する。** 同一セッション内で2回目以降の Chrome 操作では再実行不要（`select_browser` で固定された接続先は sticky に保持される）。

#### Phase 1a: 接続中の Chrome 一覧を取得

```
mcp__Claude_in_Chrome__list_connected_browsers を呼ぶ
```

応答は以下のような配列：

```json
[
  {
    "deviceId": "d1b765f5-...",
    "name": "cowork",
    "osPlatform": "macOS",
    "isLocal": true
  },
  {
    "deviceId": "b11fb8f2-...",
    "name": "cowork",
    "osPlatform": "Windows",
    "isLocal": false
  }
]
```

#### Phase 1b: `isLocal: true` でフィルタ

応答配列から `isLocal: true` の要素のみ抽出する。`isLocal: true` は「**この Cowork セッションが動いている PC のローカル Chrome**」を意味する。Cowork が Mac で動いていれば Mac の Cowork Chrome、Windows で動いていれば Windows の Cowork Chrome が `true` になる。

#### Phase 1c: フィルタ結果による分岐

**結果が1件 → そのまま `select_browser` で固定**

最も一般的なケース。ユーザーへの確認なしで以下を実行：

```
mcp__Claude_in_Chrome__select_browser(deviceId=<その1件の deviceId>)
```

**結果が0件 → ローカル Chrome が起動していない（Phase 2B へ）**

このPCの Cowork プロファイル Chrome が閉じている、または拡張がインストールされていない。Phase 2B に進んでユーザーに起動を案内する。

**結果が複数件 → 同一 PC で複数の Cowork Chrome が動いている特殊ケース**

通常は1件しか返らないが、念のため。ユーザーに `AskUserQuestion` で選んでもらう。各候補の `deviceId` を選択肢に並べる。

#### Phase 1d: 接続テスト

```
mcp__Claude_in_Chrome__tabs_context_mcp(createIfEmpty=true) を呼ぶ
```

成功すれば Phase 3 へ。エラーなら Phase 2C へ。

### Phase 2A: 候補が `isLocal: false` だけのケース

Phase 1a の応答が「`isLocal: true` 0件、`isLocal: false` 複数件」の場合。Cowork が動いている PC の Chrome は閉じているが、他 PC の Chrome は起動中。

通常は望ましくない状態（リモート PC を Cowork で操作するのは稀）。次を確認：

> このPCの Cowork プロファイル Chrome が起動していません。他 PC（{osPlatform 一覧}）の Chrome が見えていますが、そちらを使いますか？それともこのPCで Cowork Chrome を起動しますか？

ユーザーが他 PC を選べば `select_browser` で固定。このPCで起動したいなら Phase 2B へ。

### Phase 2B: 拡張未接続（Chrome を起動する必要がある）

`list_connected_browsers` で1件も返らない、またはこのPCのものが無い状態。

#### 手順

1. **ユーザーの OS を確認** — 会話の文脈から Mac か Windows か分からない場合は「Mac ですか Windows ですか」と一行で聞く
2. **起動方法を優先度順に案内**（ユーザーの環境に合わせて1つ選ばせる）
3. **ユーザーが「起動した」と返答したら Phase 1a を再実行**

#### Mac の場合の案内メッセージ例

> Cowork プロファイル Chrome が起動していません。以下のいずれかの方法で起動してください：
>
> **方法1: Dock ショートカット（事前に登録済みの場合）**
> Dock に「Cowork Chrome 起動」アイコンを登録していればクリック1発で起動します。
>
> **方法2: Terminal コマンド**
> ターミナル（Spotlight で「ターミナル」検索）を開いて以下を貼り付け→Enter：
>
> ```
> ~/Git/ClaudeSkills/cowork-chrome-launcher/scripts/open-cowork-chrome.command
> ```
>
> **方法3: Finder からダブルクリック**
> Finder で `~/Git/ClaudeSkills/cowork-chrome-launcher/scripts/` に移動し、`open-cowork-chrome.command` をダブルクリック。
>
> 初回は macOS Gatekeeper の警告が出ることがあります。「システム設定 → プライバシーとセキュリティ」で下の方の「このまま開く」をクリックして許可してください。
>
> Cowork プロファイル Chrome が立ち上がったら教えてください。接続先解決を再試行します。

#### Windows の場合の案内メッセージ例

> Cowork プロファイル Chrome が起動していません。以下のいずれかの方法で起動してください：
>
> **方法1: スタートアップ登録済みの場合**
> 登録してあればログイン直後に自動起動しているはず。タスクバーで Chrome を確認してください。
>
> **方法2: ダブルクリック起動**
> Explorer で `%USERPROFILE%\Git\ClaudeSkills\cowork-chrome-launcher\scripts\` に移動し、`open-cowork-chrome.bat` をダブルクリック。
>
> **方法3: PowerShell から実行**
>
> ```
> & "$env:USERPROFILE\Git\ClaudeSkills\cowork-chrome-launcher\scripts\open-cowork-chrome.bat"
> ```
>
> 初回は Windows SmartScreen の警告が出ることがあります。「詳細情報」→「実行」で進めてください。
>
> Cowork プロファイル Chrome が立ち上がったら教えてください。接続先解決を再試行します。

### Phase 2C: その他のエラー

`tabs_context_mcp` 等で予期せぬエラーが出た場合。1〜2回リトライ、それでもダメなら Claude デスクトップアプリの再起動を案内する。

### Phase 3: 通常作業

`tabs_context_mcp` で既存タブを把握したうえで、`navigate` / `read_page` / `form_input` 等の MCP ツールで依頼された作業を進める。**Phase 1 を踏まずに突然 `navigate` から叩かないこと**。silent 誤接続の原因になる。

## セッション中の接続先切り替え

「やっぱり別 PC で操作したい」という場合は、再度 Phase 1a を実行して候補一覧を取り直し、必要に応じて `select_browser` で別の deviceId に切り替える。あるいは明示的に `switch_browser` を呼ぶ運用も可（Connect ボタン経由で物理的に選びたいケース）。

## セットアップ系の質問が来た時

「Cowork の Chrome セットアップ」「プロファイルの作り方」「別 PC でも使いたい」「閉じた Chrome を楽に起動したい」系の質問が来た場合は、`references/setup.md` の該当セクションを読んで回答する。主な内容：

- アカウントなし Chrome プロファイル（Cowork 専用）の作成手順
- Claude for Chrome 拡張のインストール／メインプロファイルからの削除
- Login Items / スタートアップフォルダへの起動スクリプト登録（自動起動化）
- Dock ショートカットによるワンクリック起動（Chrome を閉じた時の復旧用）
- Automator で `.app` 化するオプション
- Chrome Sync による誤接続の回避方針

詳細は [`references/setup.md`](./references/setup.md) を参照。

## スクリプト同梱物

`scripts/` に Mac / Windows 両対応の起動スクリプトを置いている。どちらも Chrome の `Local State` JSON を**case-insensitive に**読んで「Cowork」「cowork」等の表示名を持つプロファイルの内部ディレクトリを自動検出し、そのプロファイルで Chrome を起動する。

- **Mac**: `scripts/open-cowork-chrome.command`
- **Windows**: `scripts/open-cowork-chrome.bat`

## ケース別チートシート

セッション冒頭の `list_connected_browsers` の応答による分岐：

| `isLocal: true` の数 | `isLocal: false` の数 | 挙動 |
|---|---|---|
| 1 | 任意 | 自動で `select_browser`、ユーザー操作なし |
| 0 | 0 | Phase 2B（このPCで Cowork Chrome 起動を案内） |
| 0 | 1+ | Phase 2A（リモートで進めるか、このPCで起動するか確認） |
| 2+ | 任意 | `AskUserQuestion` でこのPCの候補から選んでもらう（稀） |

## アンチパターン集（やってはいけない）

過去のセッションで観測された失敗パターン。同じ罠にハマらないこと。

1. **`tabs_context_mcp` をいきなり叩く** — Phase 1（list + select）を経由しないと、Cowork が silent に他 PC の Chrome を掴む可能性がある。必ず Phase 1 を先に通すこと
2. **`switch_browser` を Phase 1 の代わりに呼ぶ** — Connect ボタンクリックと名前入力をユーザーに強いるので体験が悪い。`list + select` 経路で済むなら `switch_browser` は不要
3. **Bash で `open -a "Google Chrome"` や `chrome.exe` を実行する** — サンドボックス内 Linux で走るだけでユーザーの Mac/Windows には届かない
4. **`computer://` リンクで .command / .bat を起動しようとする** — Cowork の実装上、クリックで実行まで至らない（テスト済み）。代わりに Terminal コマンドを提示するか、事前登録済みの Dock ショートカットを案内する
5. **プラグインや MCP を検索して起動手段を探し回る** — このスキル以外に起動手段はない、無駄に context を食うだけ
6. **パスだけ提示して「ダブルクリックしてください」で終わる** — ユーザーがパスをどう開くか分からなくなる。必ず Terminal コマンド or Dock ショートカットの「クリックで起動する方法」を具体的に提示
7. **ユーザーに OS を聞かず適当なスクリプトを案内する** — Mac なのに .bat を渡す、逆も然り

## 注意事項

- Claude サンドボックスから直接 Chrome を起動する手段はない（最重要ルールの再掲）
- v2 の `isLocal` フィルタは「Cowork が動いている PC」を判定基準にする。Mac で Cowork を起動していれば Mac 側、Windows なら Windows 側が自動選択される。**ユーザーが普通に「自分が今使っている PC で Cowork を使う」運用なら、これで誤接続は構造的に発生しない**
- 両 PC で Cowork が同時に動いている場合（Mac の Cowork セッションと Windows の Cowork セッションが並行）、それぞれが自分の `isLocal: true` を選ぶので独立して動作する
- スクリプトの `PROFILE_NAME` は case-insensitive 比較なので、「Cowork」「cowork」「COWORK」どれでも動く
