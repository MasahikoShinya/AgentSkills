#!/bin/bash
#
# AgentSkills Claude Code 用スキル/エージェントのデプロイスクリプト
# claude/skills と claude/agents を ~/.claude/skills/ と
# ~/.claude/agents/ にシンボリックリンクで配置する。
#
# 対応OS: WSL2, Linux, macOS
# 冪等: 既存リンクはスキップ、別ソースを指している場合のみ更新
#

set -e

# スクリプトの場所からリポジトリルートを特定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SKILLS_DIR="${HOME}/.claude/skills"
AGENTS_DIR="${HOME}/.claude/agents"

# デプロイ対象（README と一致させること）
SKILLS=(test-orchestrator code-review cowork-chrome-launcher)
AGENTS=(test-planner unit-runner e2e-runner e2e-visual-verify code-reviewer code-critic)

echo "=== AgentSkills Claude デプロイ ==="
echo "Repo:    ${REPO_ROOT}"
echo "Skills:  ${SKILLS_DIR}"
echo "Agents:  ${AGENTS_DIR}"
echo ""

mkdir -p "${SKILLS_DIR}" "${AGENTS_DIR}"

# 共通リンク処理: link_one <src> <dst> <kind_counter_prefix>
# 戻り値で結果コード(0=created, 1=skipped, 2=updated, 3=warn)を echo する
link_one() {
    local src="$1"
    local dst="$2"
    local label="$3"

    if [ ! -e "${src}" ]; then
        echo "  [WARN] ${label}: source not found at ${src}" >&2
        return 3
    fi

    if [ -L "${dst}" ]; then
        local current
        current="$(readlink "${dst}")"
        if [ "${current}" = "${src}" ]; then
            echo "  [SKIP] ${label} (already linked)"
            return 1
        else
            ln -sfn "${src}" "${dst}"
            echo "  [UPDATE] ${label} (was: ${current})"
            return 2
        fi
    elif [ -e "${dst}" ]; then
        echo "  [WARN] ${label}: ${dst} exists but is not a symlink. Skipping."
        return 3
    else
        ln -s "${src}" "${dst}"
        echo "  [OK]   ${label}"
        return 0
    fi
}

# --- Skills ---
echo "--- Skills ---"
sk_c=0; sk_s=0; sk_u=0; sk_w=0
for skill in "${SKILLS[@]}"; do
    set +e
    link_one "${REPO_ROOT}/claude/skills/${skill}" "${SKILLS_DIR}/${skill}" "${skill}"
    rc=$?
    set -e
    case $rc in
        0) sk_c=$((sk_c+1));;
        1) sk_s=$((sk_s+1));;
        2) sk_u=$((sk_u+1));;
        3) sk_w=$((sk_w+1));;
    esac
done

# --- Sub-Agents ---
echo ""
echo "--- Sub-Agents ---"
ag_c=0; ag_s=0; ag_u=0; ag_w=0
for agent in "${AGENTS[@]}"; do
    set +e
    link_one "${REPO_ROOT}/claude/agents/${agent}.md" "${AGENTS_DIR}/${agent}.md" "${agent}"
    rc=$?
    set -e
    case $rc in
        0) ag_c=$((ag_c+1));;
        1) ag_s=$((ag_s+1));;
        2) ag_u=$((ag_u+1));;
        3) ag_w=$((ag_w+1));;
    esac
done

echo ""
echo "=== 完了 ==="
echo "Skills:  created=${sk_c}, updated=${sk_u}, skipped=${sk_s}, warn=${sk_w}"
echo "Agents:  created=${ag_c}, updated=${ag_u}, skipped=${ag_s}, warn=${ag_w}"
