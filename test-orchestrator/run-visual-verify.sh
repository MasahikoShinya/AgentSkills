#!/usr/bin/env bash
#
# e2e-visual-verify サブエージェントの正規実行ラッパー
#
# Playwright を spec dir に出力させ、終了後に generate-player.ts を実行して
# player.html を生成する。動画 / screenshots / results.json / player.html が
# すべて <spec-dir>/test-results/ 配下に揃う。
#
# Usage:
#   run-visual-verify.sh <spec-dir> [playwright args...]
#
# Example:
#   run-visual-verify.sh app/claudedocs/e2e-videos/csv-column-ai-classification \
#     --project=supabase \
#     __tests__/e2e/supabase/komawari/csv-bulk-import-flow.test.ts \
#     __tests__/e2e/supabase/komawari/tag-master-redesign-flow.test.ts
#
# --- 前提 ---
# - 呼び出し元の cwd が Playwright project root (= playwright.config.ts が存在するディレクトリ)
# - <spec-dir> は cwd からの相対 or 絶対パス
# - playwright.config.ts の reporter outputFile が
#     `process.env.PLAYWRIGHT_JSON_OUTPUT_NAME || 'test-results/results.json'`
#   のように env 可変になっていること
# - テストファイルの test.use({ video }) が `E2E_VIDEO === 'on'` で切替可能になっていること
#
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <spec-dir> [playwright args...]" >&2
    exit 2
fi

SPEC_DIR="$1"
shift

# spec dir を絶対パスに正規化
if [[ "$SPEC_DIR" = /* ]]; then
    SPEC_DIR_ABS="$SPEC_DIR"
else
    SPEC_DIR_ABS="$(pwd)/$SPEC_DIR"
fi

TEST_RESULTS_DIR="$SPEC_DIR_ABS/test-results"
mkdir -p "$TEST_RESULTS_DIR"

echo "[run-visual-verify] spec dir       : $SPEC_DIR_ABS"
echo "[run-visual-verify] test-results   : $TEST_RESULTS_DIR"

# Playwright 実行
#  --output      : 各 test の outputDir を spec dir に向ける (= 動画 + testInfo.outputPath が spec dir に集まる)
#  PLAYWRIGHT_JSON_OUTPUT_NAME : reporter outputFile を spec dir に向ける (config 側が env 参照する前提)
#  E2E_VIDEO=on  : テストの test.use({ video }) を録画 ON に切替 (test ファイル側が env 参照する前提)
PLAYWRIGHT_JSON_OUTPUT_NAME="$TEST_RESULTS_DIR/results.json" \
E2E_VIDEO=on \
    npx playwright test \
        --output "$TEST_RESULTS_DIR" \
        "$@"

# generate-player.ts を毎回 canonical から上書きコピーして実行
SKILL_GENERATOR="$(dirname "$0")/generate-player.ts"
cp -f "$SKILL_GENERATOR" "$SPEC_DIR_ABS/generate-player.ts"

(cd "$SPEC_DIR_ABS" && npx tsx generate-player.ts)

echo "[run-visual-verify] player.html    : $TEST_RESULTS_DIR/player.html"
