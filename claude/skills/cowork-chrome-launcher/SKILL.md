---
name: cowork-chrome-launcher
description: Cowork / Claude Desktop で Chrome やブラウザ操作が必要になったら、実作業前に使うClaude向け入口。shared/cowork-chrome-launcher.md の接続先固定フローを読み、list_connected_browsers と select_browser で isLocal=true の Chrome を固定する。
---

# Cowork Chrome Launcher for Claude

この入口は Cowork / Claude Desktop の Chrome 操作用。実行前に AgentSkills リポジトリルートの `shared/cowork-chrome-launcher.md` を読むこと。シンボリックリンク経由で相対パスが解決できない場合は、この Skill ディレクトリのリンク先をたどってリポジトリルートを特定する。

## Claude / Cowork 固有の運用

- `mcp__Claude_in_Chrome__list_connected_browsers` で候補を取得する
- `isLocal: true` の候補を `mcp__Claude_in_Chrome__select_browser(deviceId=...)` で固定する
- 接続確認は `mcp__Claude_in_Chrome__tabs_context_mcp(createIfEmpty=true)` で行う
- セットアップ質問では `references/setup.md` を読む
- 起動スクリプトは `scripts/open-cowork-chrome.command` と `scripts/open-cowork-chrome.bat`

該当 MCP ツールが存在しない場合は、実行できないことを明確に伝える。
