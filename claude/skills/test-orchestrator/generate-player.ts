/**
 * テスト結果ディレクトリからHTMLプレイヤーを生成するスクリプト。
 * test-results/ 内の .webm 動画と各種スクリーンショット、results.json のメタを収集し、
 * カードベースのレポート player.html を出力する。
 *
 * Usage: npx tsx generate-player.ts
 *
 * --- 設計方針 ---
 * - 完全に決定的: 同じ入力なら毎回同じHTMLを出力
 * - results.json があれば describe ブロックでタブ自動分類、無ければフラット表示
 * - スクリーンショット収集は 3 段階の優先順位:
 *   1) 動画ディレクトリ自身の *.png   ← testInfo.outputPath() ベース screenshot 新 API
 *   2) screenshots/<scenarioName>/    ← scenario 文字列指定 (旧 API 互換)
 *   3) screenshots/ 直下              ← 共通フォールバック
 * - test.info().annotations に積まれた情報はメタ表に追加表示（オプション）
 *   例: test.info().annotations.push({ type: 'screen', description: '/login' });
 */
import * as fs from 'fs';
import * as path from 'path';

const TEST_RESULTS_DIR = path.resolve(__dirname, 'test-results');
const SCREENSHOTS_DIR = path.join(TEST_RESULTS_DIR, 'screenshots');
const RESULTS_JSON_PATH = path.join(TEST_RESULTS_DIR, 'results.json');
const OUTPUT_PATH = path.join(TEST_RESULTS_DIR, 'player.html');

interface Annotation { type: string; description: string; }

interface ScenarioMeta {
    category: string;       // describe ブロック名 / 'すべて'
    status: 'passed' | 'failed' | 'unknown';
    duration?: number;      // ms
    annotations: Annotation[];
    specTitle?: string;     // results.json から取得した spec.title (= 「B1. ...」「W2. ...」付き)
}

interface Scenario {
    name: string;           // 動画ディレクトリ名 (sanitized)
    displayName: string;    // 表示用シナリオ名 (= specTitle 優先、無ければ name)
    videoPath: string;
    screenshots: { name: string; path: string }[];
    meta: ScenarioMeta;
}

interface Category {
    name: string;
    scenarios: Scenario[];
    pass: number;
    fail: number;
}

// ---------- results.json 読み込み ----------

function loadResultsJson(): any | null {
    if (!fs.existsSync(RESULTS_JSON_PATH)) return null;
    try {
        return JSON.parse(fs.readFileSync(RESULTS_JSON_PATH, 'utf-8'));
    } catch {
        return null;
    }
}

/**
 * Playwrightのresults.jsonから、シナリオ名に対応するメタ情報を引く。
 * - describeチェーンの末尾をカテゴリとする
 * - 紐付けは 2 段階の優先順位:
 *   1) result.attachments[].path (video.webm) のディレクトリ名と scenarioName の完全一致
 *      (Playwright が test title を sanitize + ハッシュ短縮した動画ディレクトリ名は title からは
 *       再生成困難なので、attachments のパスを正として使うのが最も確実)
 *   2) spec.title が scenarioName に含まれる (旧ロジック、フォールバック)
 * - ファイル単位のスイート (.ts/.tsx で終わるタイトル) はカテゴリから除外
 */
function lookupMeta(scenarioName: string, results: any): ScenarioMeta {
    const fallback: ScenarioMeta = { category: 'すべて', status: 'unknown', annotations: [] };
    if (!results?.suites) return fallback;

    function matchesByAttachment(result: any): boolean {
        if (!result || !Array.isArray(result.attachments)) return false;
        for (const att of result.attachments) {
            if (att?.name === 'video' && typeof att?.path === 'string') {
                // attachment path: .../<test-results>/<videoDirName>/video.webm
                const normalizedPath = att.path.replace(/\\/g, '/');
                const m = normalizedPath.match(/\/([^/]+)\/video\.webm$/);
                const attachmentScenario = m?.[1]?.replace(/-chromium$|-firefox$|-webkit$/, '');
                if (attachmentScenario === scenarioName) return true;
            }
        }
        return false;
    }

    function recurse(suite: any, chain: string[]): ScenarioMeta | null {
        const title: string | undefined = suite.title;
        const isFileSuite = !!title && /\.(ts|tsx|js|jsx)$/.test(title);
        const newChain = (title && !isFileSuite) ? [...chain, title] : chain;

        if (Array.isArray(suite.specs)) {
            for (const spec of suite.specs) {
                const allResults = Array.isArray(spec.tests)
                    ? spec.tests.flatMap((test: any) => Array.isArray(test.results) ? test.results : [])
                    : [];
                const attachmentResult = allResults.find(matchesByAttachment);
                const matchB = typeof spec.title === 'string' && scenarioName.includes(spec.title);
                if (attachmentResult || matchB) {
                    const testResult = attachmentResult ?? allResults[allResults.length - 1];
                    const specAnnotations: Annotation[] = Array.isArray(spec.annotations) ? spec.annotations : [];
                    const resultAnnotations: Annotation[] = Array.isArray(testResult?.annotations) ? testResult.annotations : [];
                    return {
                        category: newChain.length > 0 ? newChain[newChain.length - 1] : 'すべて',
                        status: (testResult?.status === 'passed' || testResult?.status === 'failed') ? testResult.status : 'unknown',
                        duration: typeof testResult?.duration === 'number' ? testResult.duration : undefined,
                        annotations: [...specAnnotations, ...resultAnnotations],
                        specTitle: typeof spec.title === 'string' ? spec.title : undefined,
                    };
                }
            }
        }
        if (Array.isArray(suite.suites)) {
            for (const child of suite.suites) {
                const found = recurse(child, newChain);
                if (found) return found;
            }
        }
        return null;
    }

    for (const suite of results.suites) {
        const found = recurse(suite, []);
        if (found) return found;
    }
    return fallback;
}

// ---------- シナリオ収集 ----------

function collectScenarios(): Scenario[] {
    const scenarios: Scenario[] = [];
    if (!fs.existsSync(TEST_RESULTS_DIR)) return scenarios;

    const results = loadResultsJson();

    const entries = fs.readdirSync(TEST_RESULTS_DIR, { withFileTypes: true });
    for (const entry of entries) {
        if (!entry.isDirectory() || entry.name === 'screenshots') continue;

        const videoPath = path.join(TEST_RESULTS_DIR, entry.name, 'video.webm');
        if (!fs.existsSync(videoPath)) continue;

        const scenarioName = entry.name.replace(/-chromium$|-firefox$|-webkit$/, '');
        const screenshots: { name: string; path: string }[] = [];

        // 1) 動画ディレクトリ自身の *.png を最優先で収集
        //    (= testInfo.outputPath() ベース screenshot 新 API の出力 + Playwright 自動撮影 screenshot)
        const videoDir = path.join(TEST_RESULTS_DIR, entry.name);
        const localFiles = fs.readdirSync(videoDir, { withFileTypes: true })
            .filter(f => f.isFile() && /\.(png|jpg|jpeg)$/i.test(f.name))
            .map(f => f.name)
            .sort();
        for (const file of localFiles) {
            screenshots.push({
                name: file.replace(/\.(png|jpg|jpeg)$/i, ''),
                path: `${entry.name}/${file}`,
            });
        }

        // 2) screenshots/<scenarioName>/ を探す (旧 API 互換: scenario 文字列指定)
        const scenarioScreenshotDir = path.join(SCREENSHOTS_DIR, scenarioName);
        if (screenshots.length === 0 && fs.existsSync(scenarioScreenshotDir)) {
            const files = fs.readdirSync(scenarioScreenshotDir)
                .filter(f => /\.(png|jpg|jpeg)$/i.test(f))
                .sort();
            for (const file of files) {
                screenshots.push({
                    name: file.replace(/\.(png|jpg|jpeg)$/i, ''),
                    path: `screenshots/${scenarioName}/${file}`,
                });
            }
        }
        // 3) screenshots/ 直下を共通フォールバックとして収集
        if (screenshots.length === 0 && fs.existsSync(SCREENSHOTS_DIR)) {
            const files = fs.readdirSync(SCREENSHOTS_DIR, { withFileTypes: true })
                .filter(f => f.isFile() && /\.(png|jpg|jpeg)$/i.test(f.name))
                .map(f => f.name)
                .sort();
            for (const file of files) {
                screenshots.push({
                    name: file.replace(/\.(png|jpg|jpeg)$/i, ''),
                    path: `screenshots/${file}`,
                });
            }
        }

        const meta = lookupMeta(scenarioName, results);
        scenarios.push({
            name: scenarioName,
            displayName: meta.specTitle ?? scenarioName,
            videoPath: `${entry.name}/video.webm`,
            screenshots,
            meta,
        });
    }

    return scenarios.sort((a, b) => a.displayName.localeCompare(b.displayName));
}

// ---------- カテゴリ分類 ----------

function groupByCategory(scenarios: Scenario[]): Category[] {
    const map = new Map<string, Category>();
    for (const s of scenarios) {
        const cat = s.meta.category || 'すべて';
        if (!map.has(cat)) map.set(cat, { name: cat, scenarios: [], pass: 0, fail: 0 });
        const c = map.get(cat)!;
        c.scenarios.push(s);
        if (s.meta.status === 'passed') c.pass++;
        else if (s.meta.status === 'failed') c.fail++;
    }
    return Array.from(map.values());
}

// ---------- HTML生成ヘルパー ----------

function escapeHtml(s: string): string {
    return s
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function formatDuration(ms?: number): string {
    if (typeof ms !== 'number') return '—';
    return (ms / 1000).toFixed(1) + 's';
}

function badgeHtml(status: ScenarioMeta['status']): string {
    if (status === 'passed') return '<span class="badge pass">PASS</span>';
    if (status === 'failed') return '<span class="badge fail">FAIL</span>';
    return '<span class="badge unknown">—</span>';
}

function metaListHtml(scenario: Scenario): string {
    const m = scenario.meta;
    const rows: string[] = [];
    rows.push(`<dt>結果</dt><dd>${badgeHtml(m.status)} ${formatDuration(m.duration)}</dd>`);
    rows.push(`<dt>動画</dt><dd><code>${escapeHtml(scenario.videoPath)}</code></dd>`);
    rows.push(`<dt>スクリーンショット</dt><dd>${scenario.screenshots.length} 枚</dd>`);
    for (const ann of m.annotations) {
        rows.push(`<dt>${escapeHtml(ann.type)}</dt><dd>${escapeHtml(ann.description)}</dd>`);
    }
    return `<dl>${rows.join('')}</dl>`;
}

function cardHtml(scenario: Scenario, idx: number): string {
    const cardId = `card-${idx}`;
    const screenshotsHtml = scenario.screenshots.length > 0
        ? `<div class="screenshot-row">${scenario.screenshots.map(ss =>
            `<span class="screenshot-thumb" data-src="${escapeHtml(ss.path)}">${escapeHtml(ss.name)}</span>`
        ).join('')}</div>`
        : '';

    return `
<section class="card" id="${cardId}">
  <header class="card-head">
    ${badgeHtml(scenario.meta.status)}
    <span class="type-badge">${escapeHtml(scenario.meta.category)}</span>
    <h2>${escapeHtml(scenario.displayName)}</h2>
  </header>
  <div class="card-body">
    <div class="meta">${metaListHtml(scenario)}</div>
    <div class="video-block">
      <video class="prompt-video" controls preload="metadata" data-card-id="${cardId}">
        <source src="${escapeHtml(scenario.videoPath)}" type="video/webm">
      </video>
      <div class="video-controls">
        <span class="label">Speed:</span>
        <button class="speed-btn" data-speed="0.25">0.25x</button>
        <button class="speed-btn active" data-speed="0.5">0.5x</button>
        <button class="speed-btn" data-speed="1">1x</button>
        <button class="speed-btn" data-speed="2">2x</button>
      </div>
      <button class="enlarge-btn" data-card-id="${cardId}">🔍 拡大表示</button>
    </div>
  </div>
  ${screenshotsHtml}
</section>`;
}

function categoryPanelHtml(category: Category, isFirst: boolean): string {
    const activeAttr = isFirst ? ' data-active' : '';
    const cards = category.scenarios.map((s, i) => cardHtml(s, `${category.name}-${i}` as any)).join('');
    return `<div class="panel" data-panel="${escapeHtml(category.name)}"${activeAttr}>
<div class="cards">${cards}</div>
</div>`;
}

function tabsHtml(categories: Category[]): string {
    if (categories.length <= 1) return '';
    const tabs = categories.map((c, i) => {
        const total = c.scenarios.length;
        const activeAttr = i === 0 ? ' data-active' : '';
        return `<button class="tab" data-tab="${escapeHtml(c.name)}"${activeAttr}>${escapeHtml(c.name)} <span class="count">${c.pass}/${total}</span></button>`;
    }).join('');
    return `<div class="tabs">${tabs}</div>`;
}

// ---------- HTMLテンプレート ----------

function generateHtml(scenarios: Scenario[]): string {
    const categories = groupByCategory(scenarios);
    const totalPass = scenarios.filter(s => s.meta.status === 'passed').length;
    const totalFail = scenarios.filter(s => s.meta.status === 'failed').length;
    const totalUnknown = scenarios.length - totalPass - totalFail;

    const panels = categories.map((c, i) => categoryPanelHtml(c, i === 0)).join('');
    const tabs = tabsHtml(categories);

    const summaryParts: string[] = [`<b>合計</b>: ${scenarios.length} シナリオ`];
    if (totalPass > 0) summaryParts.push(`<span class="pass-count">PASS ${totalPass}</span>`);
    if (totalFail > 0) summaryParts.push(`<span class="fail-count">FAIL ${totalFail}</span>`);
    if (totalUnknown > 0) summaryParts.push(`<span class="unknown-count">未判定 ${totalUnknown}</span>`);

    return `<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<title>E2E Visual Verify — Player</title>
<style>
:root {
  --bg:#1a1a1a; --card:#242424; --border:#3a3a3a;
  --text:#e0e0e0; --muted:#9a9a9a;
  --accent:#4ec9b0; --pass:#2ea043; --fail:#d73a49; --warn:#d29922;
}
* { box-sizing: border-box; }
body { font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif; margin:0; padding:24px; background:var(--bg); color:var(--text); }
h1 { margin:0 0 4px; font-size:22px; }
.subtitle { color:var(--muted); margin:0 0 24px; font-size:13px; }
.summary-bar { display:flex; gap:16px; padding:10px 14px; background:#1f1f1f; border-radius:4px; font-size:13px; margin-bottom:24px; }
.summary-bar .pass-count { color:var(--pass); font-weight:bold; }
.summary-bar .fail-count { color:var(--fail); font-weight:bold; }
.summary-bar .unknown-count { color:var(--muted); font-weight:bold; }
.tabs { display:flex; gap:4px; flex-wrap:wrap; border-bottom:2px solid var(--border); margin-bottom:20px; }
.tab { background:transparent; color:var(--muted); border:none; border-bottom:2px solid transparent; padding:10px 16px; cursor:pointer; font-size:13px; font-weight:500; margin-bottom:-2px; }
.tab[data-active] { color:var(--accent); border-bottom-color:var(--accent); }
.tab:hover { color:var(--text); }
.tab .count { font-size:11px; color:var(--muted); margin-left:4px; }
.panel { display:none; flex-direction:column; gap:20px; }
.panel[data-active] { display:flex; }
.cards { display:flex; flex-direction:column; gap:20px; }
.card { background:var(--card); border:1px solid var(--border); border-radius:8px; overflow:hidden; }
.card-head { padding:14px 18px; border-bottom:1px solid var(--border); display:flex; flex-wrap:wrap; gap:8px; align-items:center; }
.card-head h2 { margin:0; font-size:15px; font-weight:500; flex-basis:100%; }
.badge { display:inline-block; padding:3px 9px; border-radius:4px; font-size:11px; font-weight:bold; letter-spacing:0.5px; }
.badge.pass { background:var(--pass); color:white; }
.badge.fail { background:var(--fail); color:white; }
.badge.unknown { background:#3a3a3a; color:var(--muted); }
.type-badge { display:inline-block; padding:2px 8px; border-radius:3px; background:#1f1f1f; color:var(--muted); font-size:11px; }
.card-body { display:grid; grid-template-columns:1fr 360px; gap:20px; padding:18px; }
@media (max-width:900px) { .card-body { grid-template-columns:1fr; } }
.meta dl { margin:0; display:grid; grid-template-columns:140px 1fr; gap:5px 12px; font-size:13px; }
.meta dt { color:var(--muted); white-space:nowrap; }
.meta dd { margin:0; word-break:break-word; }
code { background:#1a1a1a; padding:2px 6px; border-radius:3px; font-family:Consolas,monospace; font-size:12px; }
.video-block { display:flex; flex-direction:column; gap:8px; }
video.prompt-video { width:100%; max-width:360px; background:#000; border-radius:4px; display:block; }
.video-controls { display:flex; gap:6px; align-items:center; flex-wrap:wrap; }
.video-controls .label { color:var(--muted); font-size:11px; }
.speed-btn { padding:4px 10px; border:1px solid var(--border); border-radius:4px; background:transparent; color:var(--muted); cursor:pointer; font-size:11px; transition:all 0.15s; }
.speed-btn:hover { border-color:var(--accent); color:var(--accent); }
.speed-btn.active { background:var(--accent); border-color:var(--accent); color:black; font-weight:bold; }
.enlarge-btn { margin-top:4px; padding:6px 12px; background:var(--accent); color:black; border:none; border-radius:4px; cursor:pointer; font-size:12px; font-weight:bold; align-self:flex-start; }
.enlarge-btn:hover { opacity:0.85; }
.screenshot-row { padding:0 18px 18px; display:flex; gap:8px; flex-wrap:wrap; }
.screenshot-thumb { display:flex; align-items:center; gap:5px; padding:5px 10px; background:#1f1f1f; border-radius:4px; cursor:pointer; font-size:11px; color:var(--muted); transition:all 0.15s; }
.screenshot-thumb:hover { background:#2a2a2a; color:var(--accent); }
.screenshot-thumb::before { content:'📷'; }
.modal { display:none; position:fixed; inset:0; background:rgba(0,0,0,0.92); z-index:1000; align-items:center; justify-content:center; flex-direction:column; gap:12px; padding:72px 24px 24px; overflow:auto; }
.modal.open { display:flex; }
.modal video { width:min(90vw, 1600px); max-height:calc(100vh - 200px); background:#000; }
.modal-img { max-width:90vw; max-height:calc(100vh - 160px); }
.modal-controls { display:flex; gap:8px; align-items:center; }
.modal-close { position:absolute; top:18px; right:24px; width:42px; height:42px; font-size:22px; color:white; background:rgba(0,0,0,0.55); border:1px solid rgba(255,255,255,0.3); border-radius:50%; cursor:pointer; display:flex; align-items:center; justify-content:center; }
.modal-close:hover { background:rgba(220,60,60,0.85); }
.modal-title { position:absolute; top:24px; left:30px; right:90px; color:white; font-size:14px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; pointer-events:none; }
.modal-nav { position:absolute; top:50%; transform:translateY(-50%); width:48px; height:48px; font-size:24px; color:white; background:rgba(0,0,0,0.55); border:1px solid rgba(255,255,255,0.3); border-radius:50%; cursor:pointer; display:flex; align-items:center; justify-content:center; }
.modal-nav:hover { background:rgba(78,201,176,0.85); color:black; }
.modal-prev { left:24px; }
.modal-next { right:24px; }
.modal-caption { color:#ccc; font-size:12px; }
.shortcuts-help { color:var(--muted); font-size:11px; }
kbd { background:#2a2a2a; padding:2px 6px; border-radius:3px; border:1px solid var(--border); font-family:monospace; font-size:10px; color:var(--text); }
</style>
</head>
<body>
<h1>E2E Visual Verify — Player</h1>
<p class="subtitle">${scenarios.length} シナリオ（自動生成）</p>

<div class="summary-bar">${summaryParts.map(s => `<span>${s}</span>`).join('')}</div>

${tabs}

${panels}

<div class="modal" id="video-modal">
  <button class="modal-close" id="modal-close">✕</button>
  <span class="modal-title" id="modal-title"></span>
  <video controls id="modal-video"></video>
  <div class="modal-controls">
    <span class="label" style="color:#9a9a9a;font-size:11px;">Speed:</span>
    <button class="speed-btn modal-speed" data-speed="0.25">0.25x</button>
    <button class="speed-btn modal-speed active" data-speed="0.5">0.5x</button>
    <button class="speed-btn modal-speed" data-speed="1">1x</button>
    <button class="speed-btn modal-speed" data-speed="2">2x</button>
  </div>
  <div class="shortcuts-help">
    <kbd>←</kbd> <kbd>→</kbd> 5秒スキップ &nbsp;
    <kbd>[</kbd> <kbd>]</kbd> 速度変更 &nbsp;
    <kbd>Space</kbd> 再生/停止 &nbsp;
    <kbd>Esc</kbd> 閉じる
  </div>
</div>

<div class="modal" id="image-modal">
  <button class="modal-close" id="image-modal-close">✕</button>
  <button class="modal-nav modal-prev" id="image-modal-prev" title="前へ (←)">‹</button>
  <button class="modal-nav modal-next" id="image-modal-next" title="次へ (→)">›</button>
  <img class="modal-img" id="modal-image" src="" alt="">
  <div class="modal-caption" id="modal-caption"></div>
</div>

<script>
// タブ切替
document.querySelectorAll('.tab').forEach((tab) => {
  tab.addEventListener('click', () => {
    const target = tab.dataset.tab;
    document.querySelectorAll('.tab').forEach((t) => t.removeAttribute('data-active'));
    document.querySelectorAll('.panel').forEach((p) => p.removeAttribute('data-active'));
    tab.setAttribute('data-active', '');
    document.querySelector('.panel[data-panel="' + target + '"]')?.setAttribute('data-active', '');
  });
});

// 各カード内のビデオに速度ボタン連動
document.querySelectorAll('.card').forEach((card) => {
  const video = card.querySelector('video.prompt-video');
  if (!video) return;
  video.playbackRate = 0.5;
  card.querySelectorAll('.video-controls .speed-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      video.playbackRate = parseFloat(btn.dataset.speed);
      card.querySelectorAll('.video-controls .speed-btn').forEach((b) => b.classList.remove('active'));
      btn.classList.add('active');
    });
  });
});

// 動画拡大モーダル
const videoModal = document.getElementById('video-modal');
const modalVideo = document.getElementById('modal-video');
const modalTitle = document.getElementById('modal-title');
const modalClose = document.getElementById('modal-close');

document.querySelectorAll('.enlarge-btn').forEach((btn) => {
  btn.addEventListener('click', () => {
    const id = btn.dataset.cardId;
    const card = document.getElementById(id);
    const vid = card.querySelector('video.prompt-video');
    modalVideo.innerHTML = '';
    vid.querySelectorAll('source').forEach((s) => {
      const sc = document.createElement('source');
      sc.src = s.src; sc.type = s.type;
      modalVideo.appendChild(sc);
    });
    modalVideo.load();
    modalVideo.playbackRate = 0.5;
    document.querySelectorAll('.modal-speed').forEach((b) => b.classList.toggle('active', b.dataset.speed === '0.5'));
    modalTitle.textContent = card.querySelector('h2').textContent;
    videoModal.classList.add('open');
    modalVideo.play();
  });
});

document.querySelectorAll('.modal-speed').forEach((btn) => {
  btn.addEventListener('click', () => {
    modalVideo.playbackRate = parseFloat(btn.dataset.speed);
    document.querySelectorAll('.modal-speed').forEach((b) => b.classList.remove('active'));
    btn.classList.add('active');
  });
});

const closeVideoModal = () => { videoModal.classList.remove('open'); modalVideo.pause(); modalVideo.innerHTML = ''; };
modalClose.addEventListener('click', closeVideoModal);
videoModal.addEventListener('click', (e) => { if (e.target === videoModal) closeVideoModal(); });

// 画像モーダル — シナリオ内で前/次に遷移、端で閉じる
const imageModal = document.getElementById('image-modal');
const modalImage = document.getElementById('modal-image');
const modalCaption = document.getElementById('modal-caption');
const imageModalClose = document.getElementById('image-modal-close');
const imageModalPrev = document.getElementById('image-modal-prev');
const imageModalNext = document.getElementById('image-modal-next');
let currentThumb = null;

const showImage = (thumb) => {
  currentThumb = thumb;
  modalImage.src = thumb.dataset.src;
  modalCaption.textContent = thumb.textContent || '';
};
const closeImageModal = () => { imageModal.classList.remove('open'); currentThumb = null; };
const goPrev = () => {
  if (!currentThumb) return;
  const prev = currentThumb.previousElementSibling;
  if (prev && prev.classList.contains('screenshot-thumb')) showImage(prev);
  else closeImageModal();
};
const goNext = () => {
  if (!currentThumb) return;
  const next = currentThumb.nextElementSibling;
  if (next && next.classList.contains('screenshot-thumb')) showImage(next);
  else closeImageModal();
};

document.querySelectorAll('.screenshot-thumb').forEach((thumb) => {
  thumb.addEventListener('click', () => {
    showImage(thumb);
    imageModal.classList.add('open');
  });
});
imageModalClose.addEventListener('click', closeImageModal);
imageModalPrev.addEventListener('click', (e) => { e.stopPropagation(); goPrev(); });
imageModalNext.addEventListener('click', (e) => { e.stopPropagation(); goNext(); });
imageModal.addEventListener('click', (e) => { if (e.target === imageModal) closeImageModal(); });

// キーボードショートカット
const speeds = [0.25, 0.5, 1, 2];
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') { closeVideoModal(); closeImageModal(); return; }
  // 画像モーダル開いている時
  if (imageModal.classList.contains('open')) {
    if (e.key === 'ArrowLeft') { goPrev(); return; }
    if (e.key === 'ArrowRight') { goNext(); return; }
  }
  // 動画モーダル開いている時
  if (!videoModal.classList.contains('open')) return;
  if (e.key === 'ArrowLeft') { modalVideo.currentTime -= 5; }
  else if (e.key === 'ArrowRight') { modalVideo.currentTime += 5; }
  else if (e.key === ' ') { e.preventDefault(); modalVideo.paused ? modalVideo.play() : modalVideo.pause(); }
  else if (e.key === '[' || e.key === ']') {
    const cur = speeds.indexOf(modalVideo.playbackRate);
    const next = e.key === ']' ? Math.min(cur + 1, speeds.length - 1) : Math.max(cur - 1, 0);
    modalVideo.playbackRate = speeds[next];
    document.querySelectorAll('.modal-speed').forEach((b) => b.classList.toggle('active', parseFloat(b.dataset.speed) === speeds[next]));
  }
});
</script>
</body>
</html>`;
}

// ---------- 実行 ----------

const scenarios = collectScenarios();
if (scenarios.length === 0) {
    console.error('test-results/ に動画が見つかりません');
    process.exit(1);
}

const html = generateHtml(scenarios);
fs.writeFileSync(OUTPUT_PATH, html);

const categories = groupByCategory(scenarios);
console.log(`player.html を生成しました: ${OUTPUT_PATH}`);
console.log(`シナリオ数: ${scenarios.length} / カテゴリ数: ${categories.length}`);
for (const c of categories) {
    console.log(`  [${c.name}] PASS ${c.pass} / FAIL ${c.fail} / 計 ${c.scenarios.length}`);
    for (const s of c.scenarios) {
        console.log(`    - ${s.displayName} (status=${s.meta.status}, screenshots=${s.screenshots.length}, annotations=${s.meta.annotations.length})`);
    }
}
