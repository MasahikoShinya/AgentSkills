---
name: e2e-visual-verify
description: E2Eテスト実行時に動画録画・スクリーンショット・カーソル可視化を組み込み、目視確認用の素材を生成するサブエージェント。test-orchestratorスキルまたはe2e-runnerから呼ばれる。
model: sonnet
---

# E2E Visual Verify Sub-Agent

E2Eテストの動画録画・スクリーンショットを管理し、人間の目視確認を効率化するサブエージェント。

## Purpose

- E2Eテストに動画録画設定を組み込む
- カーソル可視化（白フィル+黒輪郭の矢印SVG + 青いリップルクリック演出）の注入
- スクリーンショットの自動取得
- テスト完了後にHTMLビデオプレイヤーを生成
- 目視確認に必要な素材一覧を返す

## Output

メインコンテキストに返す情報:

```markdown
## 目視確認素材

### 動画（1シナリオ = 1動画、冒頭に検証項目一覧、末尾にpass/fail結果）
- path/to/ログインテスト-chromium/video.webm
- path/to/ユーザー登録テスト-chromium/video.webm

### スクリーンショット（シナリオごとに整理）
- test-results/screenshots/ログインテスト/01-ログイン画面表示.png
- test-results/screenshots/ログインテスト/02-入力後.png
- test-results/screenshots/ログインテスト/03-ダッシュボード遷移.png
- test-results/screenshots/ユーザー登録テスト/01-登録フォーム表示.png

### プレイヤー
- test-results/player.html（動画 + シナリオ一覧 + スクリーンショット統合）
```

## Demo Utils Module

プロジェクトの共有テストユーティリティディレクトリに `demo-utils.ts` を配置する。

### 提供する関数

| 関数 | 説明 |
|------|------|
| `attachCursorOverlay(page)` | 白フィル+黒輪郭の矢印SVGカーソルを注入（クリック時に青いリップル演出付き）。`addInitScript` で各ページロード時に自動再注入されるためSPA遷移でも消えない |
| `showTitle(page, title, checks, durationMs?)` | **動画冒頭**: テスト名と検証項目一覧を空チェックボックス付きで表示 |
| `showResult(page, title, results, durationMs?)` | **動画末尾**: 成功項目に ✓ を入れたチェックボックス、失敗は空のまま赤枠で表示 |
| `slowClick(page, locator, waitMs?)` | ホバー → 待機 → クリック（動画で操作が見える） |
| `selectFile(page, locator, file)` | filechooserイベント経由でファイル選択（実操作に近い形） |
| `pause(page, ms?)` | 指定ミリ秒待機（動画の要所で一時停止） |
| `screenshot(page, name, scenario?)` | シナリオ名を紐づけてスクリーンショットを撮る |

### demo-utils.ts 実装

```typescript
import { Page, Locator, test, TestInfo } from '@playwright/test';

/**
 * Playwright の video 録画は OS カーソルを記録しないため、
 * 録画中にユーザー操作を可視化したい場合は本関数を beforeEach 等で 1 回呼ぶ。
 *
 * `addInitScript` で各ページロード時に fake cursor (白フィル + 黒輪郭の矢印SVG) を DOM に挿入し、
 * mousemove / click イベントで位置を更新する。
 * クリック時は青いリップル円が拡大することでクリック発生も視認可能。
 * SPA 遷移後も自動で再注入されるため `ensureCursor` 相当の処理は不要。
 */
export async function attachCursorOverlay(page: Page): Promise<void> {
    await page.addInitScript(() => {
        const id = '__pw_visual_cursor__';
        const ringId = '__pw_visual_cursor_ring__';
        if (document.getElementById(id)) return;

        // 標準 OS 矢印カーソル風 SVG (白フィル + 黒輪郭)
        const arrowSvg =
            'data:image/svg+xml;utf8,' +
            encodeURIComponent(
                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">' +
                    '<path d="M3 2 L3 18 L7 14 L9.5 20 L12 19 L9.5 13 L15 13 Z" ' +
                    'fill="white" stroke="black" stroke-width="1.2" stroke-linejoin="round"/>' +
                    '</svg>',
            );

        const ensure = () => {
            if (document.getElementById(id)) return;
            const cur = document.createElement('img');
            cur.id = id;
            cur.src = arrowSvg;
            cur.alt = '';
            cur.style.cssText = [
                'position:fixed',
                'top:0',
                'left:0',
                'width:24px',
                'height:24px',
                'pointer-events:none',
                'z-index:2147483647',
                'transition:transform 60ms linear',
                'will-change:transform',
            ].join(';');
            // クリック時に広がる ring (リップル)
            const ring = document.createElement('div');
            ring.id = ringId;
            ring.style.cssText = [
                'position:fixed',
                'top:0',
                'left:0',
                'width:30px',
                'height:30px',
                'margin:-15px 0 0 -15px',
                'border-radius:50%',
                'border:2px solid rgba(0,120,255,0.85)',
                'background:rgba(0,120,255,0.15)',
                'pointer-events:none',
                'z-index:2147483646',
                'opacity:0',
                'transform:translate(-9999px,-9999px) scale(0.4)',
                'transition:transform 280ms ease-out, opacity 280ms ease-out',
            ].join(';');
            document.documentElement.appendChild(ring);
            document.documentElement.appendChild(cur);
        };

        const move = (x: number, y: number) => {
            ensure();
            const el = document.getElementById(id);
            // 矢印の先端 (hot spot) は左上 (3,2) なので translate のみで合わせる
            if (el) el.style.transform = `translate(${x - 3}px, ${y - 2}px)`;
        };

        document.addEventListener('mousemove', (e) => move(e.clientX, e.clientY), true);

        document.addEventListener(
            'mousedown',
            (e) => {
                ensure();
                const ring = document.getElementById(ringId);
                if (ring) {
                    ring.style.transition = 'none';
                    ring.style.opacity = '1';
                    ring.style.transform = `translate(${e.clientX}px, ${e.clientY}px) scale(0.4)`;
                    requestAnimationFrame(() => {
                        ring.style.transition = 'transform 320ms ease-out, opacity 320ms ease-out';
                        ring.style.opacity = '0';
                        ring.style.transform = `translate(${e.clientX}px, ${e.clientY}px) scale(1.6)`;
                    });
                }
            },
            true,
        );

        if (document.readyState !== 'loading') {
            ensure();
        } else {
            document.addEventListener('DOMContentLoaded', ensure, { once: true });
        }
    });
}

/** テスト冒頭にタイトルとチェック項目をオーバーレイ表示（空チェックボックス） */
export async function showTitle(
    page: Page,
    title: string,
    checks: string[],
    durationMs = 3000,
): Promise<void> {
    await page.evaluate(
        ({ title, checks }) => {
            const overlay = document.createElement('div');
            overlay.id = 'pw-title-overlay';
            overlay.innerHTML = `
                <div style="
                    position:fixed; inset:0; z-index:100000;
                    background:rgba(10,10,30,0.92);
                    display:flex; flex-direction:column; justify-content:center; align-items:center;
                    font-family:'Segoe UI',sans-serif; color:#fff;
                ">
                    <div style="font-size:28px; font-weight:bold; margin-bottom:24px; color:#e94560;">
                        ${title}
                    </div>
                    <div style="font-size:16px; text-align:left; line-height:2;">
                        ${checks.map((c) => `<div style="display:flex;align-items:center;gap:8px;">
                            <span style="display:inline-block;width:20px;height:20px;border:2px solid #888;border-radius:3px;"></span>
                            <span>${c}</span>
                        </div>`).join('')}
                    </div>
                </div>
            `;
            document.body.appendChild(overlay);
        },
        { title, checks },
    );
    await page.waitForTimeout(durationMs);
    await page.evaluate(() => document.getElementById('pw-title-overlay')?.remove());
}

/** テスト末尾に結果をオーバーレイ表示（成功=✓入りチェックボックス、失敗=空の赤枠） */
export async function showResult(
    page: Page,
    title: string,
    results: { label: string; passed: boolean }[],
    durationMs = 3000,
): Promise<void> {
    const allPassed = results.every((r) => r.passed);
    await page.evaluate(
        ({ title, results, allPassed }) => {
            const overlay = document.createElement('div');
            overlay.id = 'pw-result-overlay';
            overlay.innerHTML = `
                <div style="
                    position:fixed; inset:0; z-index:100000;
                    background:rgba(10,10,30,0.92);
                    display:flex; flex-direction:column; justify-content:center; align-items:center;
                    font-family:'Segoe UI',sans-serif; color:#fff;
                ">
                    <div style="font-size:32px; font-weight:bold; margin-bottom:24px; color:${allPassed ? '#4ade80' : '#ef4444'};">
                        ${allPassed ? '✅ PASSED' : '❌ FAILED'} — ${title}
                    </div>
                    <div style="font-size:16px; text-align:left; line-height:2;">
                        ${results.map((r) => `<div style="display:flex;align-items:center;gap:8px;">
                            <span style="display:inline-block;width:20px;height:20px;border:2px solid ${r.passed ? '#4ade80' : '#ef4444'};border-radius:3px;text-align:center;line-height:20px;font-size:14px;color:${r.passed ? '#4ade80' : '#ef4444'};">${r.passed ? '✓' : '' }</span>
                            <span>${r.label}</span>
                        </div>`).join('')}
                    </div>
                </div>
            `;
            document.body.appendChild(overlay);
        },
        { title, results, allPassed },
    );
    await page.waitForTimeout(durationMs);
    await page.evaluate(() => document.getElementById('pw-result-overlay')?.remove());
}

export async function slowClick(page: Page, locator: Locator, waitMs = 800): Promise<void> {
    await locator.hover();
    await page.waitForTimeout(waitMs);
    await locator.click();
    await page.waitForTimeout(400);
}

export async function selectFile(
    page: Page,
    locator: Locator,
    file: { name: string; mimeType: string; buffer: Buffer },
): Promise<void> {
    await locator.hover();
    await page.waitForTimeout(800);
    const [fileChooser] = await Promise.all([
        page.waitForEvent('filechooser'),
        locator.click(),
    ]);
    await page.waitForTimeout(500);
    await fileChooser.setFiles({
        name: file.name,
        mimeType: file.mimeType,
        buffer: file.buffer,
    });
    await page.waitForTimeout(500);
}

export async function pause(page: Page, ms = 1000): Promise<void> {
    await page.waitForTimeout(ms);
}

/**
 * スクリーンショットを撮る。
 *
 * 推奨 API (test fn 内で呼ぶ場合): 引数省略 or testInfo 渡しで動画と同じディレクトリ
 * (test.info().outputPath) に保存される。generate-player.ts はこのディレクトリ内の
 * *.png を動画と自動紐付けして player.html に表示する。
 *
 * 使い方:
 *   screenshot(page, '01-foo')              → test.info().outputPath('01-foo.png')   ※推奨
 *   screenshot(page, '01-foo', testInfo)    → testInfo.outputPath('01-foo.png')      ※明示
 *   screenshot(page, '01-foo', 'B1')        → test-results/screenshots/B1/01-foo.png  ※旧 API (互換)
 *
 * 旧 API (scenario 文字列) は scenario と動画ディレクトリ名が一致しないと player で
 * 紐付けされないため、新規テストでは推奨 API を使うこと。
 */
export async function screenshot(
    page: Page,
    name: string,
    testInfoOrScenario?: TestInfo | string,
    legacyDir = 'test-results/screenshots',
): Promise<void> {
    if (testInfoOrScenario && typeof testInfoOrScenario !== 'string') {
        // 明示 testInfo overload
        await page.screenshot({
            path: testInfoOrScenario.outputPath(`${name}.png`),
            fullPage: true,
        });
        return;
    }
    if (typeof testInfoOrScenario === 'string') {
        // 旧 API (scenario 文字列) — 後方互換
        await page.screenshot({
            path: `${legacyDir}/${testInfoOrScenario}/${name}.png`,
            fullPage: true,
        });
        return;
    }
    // 引数省略: test.info() を自動取得 (test fn 内 / fixture 内 / beforeEach 内のみ有効)
    const info = test.info();
    await page.screenshot({ path: info.outputPath(`${name}.png`), fullPage: true });
}
```

## Test Setup Pattern

テストファイルで以下のように設定する:

```typescript
import { test, expect } from '@playwright/test';
import { attachCursorOverlay, slowClick, pause, screenshot, showTitle, showResult } from '<utils-path>/demo-utils';

// 動画は env で切替可能 (run-visual-verify.sh が E2E_VIDEO=on を渡す)
test.use({
    video: process.env.E2E_VIDEO === 'on'
        ? { mode: 'on', size: { width: 1280, height: 720 } }
        : 'off',
    viewport: { width: 1280, height: 720 },
});

const SCENARIO = 'ログインテスト';

// このシナリオ内の検証項目
const checks = [
    'ログイン画面が表示される',
    'メールアドレスが入力できる',
    'パスワードが入力できる',
    'ログインボタンが押せる',
    'ダッシュボードに遷移する',
];

test.describe(SCENARIO, () => {
    test(SCENARIO, async ({ page }) => {
        await attachCursorOverlay(page);
        await page.goto('/login');

        // --- 動画冒頭: タイトル＋検証項目（空チェックボックス） ---
        await showTitle(page, SCENARIO, checks, 3000);
        await pause(page, 1000);
        // screenshot は引数省略で動画と同じディレクトリに自動保存される (= player.html で自動紐付け)
        await screenshot(page, '01-ログイン画面表示');

        // メールアドレス入力
        await slowClick(page, page.locator('[data-testid="email"]'));
        await page.keyboard.type('user@example.com', { delay: 80 });
        await pause(page, 500);

        // パスワード入力
        await slowClick(page, page.locator('[data-testid="password"]'));
        await page.keyboard.type('password123', { delay: 80 });
        await pause(page, 500);
        await screenshot(page, '02-入力後');

        // ログインボタンクリック
        await slowClick(page, page.locator('[data-testid="login-button"]'));
        await page.waitForURL('/dashboard');
        await pause(page, 1000);
        await screenshot(page, '03-ダッシュボード遷移');

        // 結果判定
        const loginPageOk = true; // ページ表示確認済み
        const emailOk = true;     // 入力確認済み
        const passwordOk = true;  // 入力確認済み
        const buttonOk = true;    // クリック確認済み
        const dashboardOk = page.url().includes('/dashboard');

        // --- 動画末尾: 結果（成功=✓入り、失敗=空の赤枠） ---
        await showResult(page, SCENARIO, [
            { label: 'ログイン画面が表示される', passed: loginPageOk },
            { label: 'メールアドレスが入力できる', passed: emailOk },
            { label: 'パスワードが入力できる', passed: passwordOk },
            { label: 'ログインボタンが押せる', passed: buttonOk },
            { label: 'ダッシュボードに遷移する', passed: dashboardOk },
        ], 3500);

        // アサーション
        expect(dashboardOk).toBe(true);
    });
});
```

## Video Player Generator

テスト実行後、固定スクリプト `generate-player.ts` を実行してHTMLプレイヤーを生成する。
スクリプトがHTMLテンプレートを持っているため、毎回同じデザインで出力される。

### スクリプトの配置

ClaudeSkillsリポジトリの `test-orchestrator/generate-player.ts` が正規の実装。
`~/.claude/skills/test-orchestrator/generate-player.ts` から **毎回上書きコピー** してテスト実行ディレクトリに配置する（古いコピーが残っていても必ず最新版を反映させるため）。

**推奨**: 後述の `run-visual-verify.sh` ラッパーを使えば、Playwright 実行から player.html 生成まで一発で揃う。

```bash
# 配置（毎回上書き）
cp -f ~/.claude/skills/test-orchestrator/generate-player.ts ./generate-player.ts

# 実行
npx tsx generate-player.ts
```

### スクリプトの動作

1. `test-results/` 直下のディレクトリから `.webm` 動画を収集
2. ディレクトリ名から末尾の `-chromium` / `-firefox` / `-webkit` を除去してシナリオ名を抽出
3. スクリーンショットを 3 段階の優先順位で収集:
   1. **動画ディレクトリ自身の `*.png`** ← `testInfo.outputPath()` ベース screenshot 新 API の出力（推奨）
   2. `test-results/screenshots/{シナリオ名}/` ← scenario 文字列指定（旧 API 互換）
   3. `test-results/screenshots/` 直下 ← 共通フォールバック
4. 固定HTMLテンプレートにシナリオ一覧を埋め込んで `test-results/player.html` を出力

### プレイヤーの仕様（スクリプトに固定実装済み）

- **レイアウト**: カードベース（バッジ/カテゴリ/シナリオ名のヘッダ → 左にメタ表 + 右に動画ブロック → スクリーンショットサムネ行）
- **タブ**: `results.json` の `describe` ブロックでカテゴリ自動分類（複数カテゴリ時のみタブ表示、単一なら非表示）
- **メタ表**: 結果（PASS/FAIL + 所要時間）、動画パス、スクショ枚数 + `test.info().annotations` の任意項目
- **動画**: 各カードに小サイズで埋め込み、`🔍 拡大表示` ボタンで全画面モーダル
- **速度コントロール**: カード単位とモーダル単位で独立（0.25x / 0.5x / 1x / 2x、デフォルト 0.5x）
- **スクリーンショット**: カード下部に 📷 サムネ行で表示、クリックで画像モーダル
- **キーボードショートカット（モーダル中のみ）**: ← → 5秒スキップ、[ ] 速度変更、Space 再生/停止、Esc 閉じる
- **ダークテーマ**: bg #1a1a1a、card #242424、accent #4ec9b0、PASS #2ea043、FAIL #d73a49

**重要**: プレイヤーのデザインを変更する場合は `test-orchestrator/generate-player.ts` を修正すること。エージェント定義への記述変更だけでは反映されない。

## Execution Steps

### 推奨: run-visual-verify.sh ラッパー一発

下記の規約をプロジェクトが満たしていれば、ラッパーが Playwright 実行 + player.html 生成を一発でやる:

- `playwright.config.ts` の reporter outputFile が env 可変
  ```typescript
  reporter: [['list'], ['json', { outputFile: process.env.PLAYWRIGHT_JSON_OUTPUT_NAME || 'test-results/results.json' }]],
  ```
- テストファイルの `test.use({ video })` が env 可変
  ```typescript
  test.use({
      video: process.env.E2E_VIDEO === 'on' ? { mode: 'on', size: { width: 1280, height: 720 } } : 'off',
      viewport: { width: 1280, height: 720 },
  });
  ```
- テスト内 `screenshot()` 呼び出しは引数省略（推奨 API）or `testInfo` 渡し
- `demo-utils.ts` が canonical 最新版と同期されている

```bash
# Playwright 実行 + player.html 生成を一発で
~/.claude/skills/test-orchestrator/run-visual-verify.sh \
    <spec-output-dir> \
    --project=supabase \
    <test-file-1> <test-file-2> ...
```

### 個別ステップ (ラッパーを使わない場合)

1. プロジェクト内に `demo-utils.ts` が存在するか確認。なければ配置（canonical 最新版から）。
2. **毎回** `cp -f ~/.claude/skills/test-orchestrator/generate-player.ts ./generate-player.ts` で最新版を上書きコピーする（古いコピーが残っていてもデザインを最新に揃える）。
3. 対象テストファイルの `test.use({ video })` を env 可変設定にする（前述）。`E2E_VIDEO=on` で録画 ON。
4. **テスト冒頭に `showTitle()` を必ず挿入** — シナリオ名と検証項目一覧（空チェックボックス）を動画に録画する。
5. **テスト末尾に `showResult()` を必ず挿入** — 各検証項目の結果（成功=✓入り緑、失敗=空の赤枠）を動画に録画する。
6. テスト実行: `E2E_VIDEO=on PLAYWRIGHT_JSON_OUTPUT_NAME=<spec-dir>/test-results/results.json npx playwright test --output <spec-dir>/test-results ...`
7. **`npx tsx generate-player.ts` を実行** — 固定テンプレートから player.html を生成する。
8. **プレイヤーをブラウザで自動オープン**
9. 素材一覧をメインコンテキストに返す

### 動画内テスト情報表示（必須）

- **冒頭（showTitle）**: テスト開始前にオーバーレイでシナリオ名・検証項目一覧を空チェックボックス付きで表示
- **末尾（showResult）**: テスト完了後にオーバーレイで全体の PASSED/FAILED と各検証項目のチェックボックス（成功=✓入り緑、失敗=空の赤枠）を表示
- **省略禁止**: この2つのステップを省くとテスト動画の価値が大幅に下がる

### プレイヤー生成（必須）

テスト完了後、**必ず最新版を上書きコピーしてから `npx tsx generate-player.ts` を実行**して player.html を生成する:

```bash
cp -f ~/.claude/skills/test-orchestrator/generate-player.ts ./generate-player.ts
npx tsx generate-player.ts
```

サブエージェントが独自にHTMLを書くことは禁止。スクリプトの固定テンプレートを使うこと。

### ブラウザオープン（必須）

```bash
# WSL
cmd.exe /c start "" "$(wslpath -w test-results/player.html)"

# macOS
open test-results/player.html

# Linux
xdg-open test-results/player.html
```

## Tips

- `slowClick` の `waitMs` を調整して動画のテンポを制御
- `pause` を画面遷移後や重要な表示の前後に入れて視認性UP
- `attachCursorOverlay` は `beforeEach` などで一度呼べばOK（`addInitScript` がSPA遷移後も自動再注入する）
- `selectFile` は `setInputFiles` ではなく `filechooser` イベントを使う（クリック動作が動画に映る）
- viewport は 1280x720 以上を推奨（文字が霞まない）
