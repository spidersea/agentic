#!/usr/bin/env bash
# session-end.sh — 会话结束时自动执行，生成 auto-checkpoint + 保存未提交变更摘要
# 用法: bash .agent/scripts/session-end.sh
# 设计: 轻量级（<3秒）、幂等、仅追加写入

set -euo pipefail

TIMESTAMP=$(date +%Y%m%d-%H%M)
AUTO_CP_DIR=".agent/auto-checkpoints"

echo "=== 💾 会话结束自动保存 ==="
echo ""

# 确保目录存在
mkdir -p "$AUTO_CP_DIR"

# 1. 生成 auto-checkpoint
AUTO_CP_FILE="$AUTO_CP_DIR/auto-checkpoint-$TIMESTAMP.md"

{
    echo "## Auto-Checkpoint: $TIMESTAMP"
    echo ""
    echo "> 由 session-end.sh 自动生成，非手动 /checkpoint"
    echo ""

    # Git 状态
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "### Git 状态"
        echo "- **最近 5 个 commits**:"
        git log -5 --format='  - `%h` %s (%ar)' 2>/dev/null || echo "  无提交记录"
        echo ""

        # 未提交变更
        CHANGES=$(git status --porcelain 2>/dev/null)
        if [ -n "$CHANGES" ]; then
            echo "- **未提交变更**:"
            echo "$CHANGES" | head -20 | sed 's/^/  /'
            echo ""
        else
            echo "- **未提交变更**: 无"
            echo ""
        fi

        # 今天修改的文件摘要
        echo "### 今日修改文件"
        git diff --name-only HEAD~5 HEAD 2>/dev/null | head -20 | sed 's/^/- /' || echo "- 无法获取"
    else
        echo "### Git 状态"
        echo "不在 git 仓库中"
    fi

    echo ""
    echo "### 本能提取提示"
    echo "如需提取本次会话的编码模式，请在下次会话中运行 \`/learn\`"

} > "$AUTO_CP_FILE"

echo "✅ auto-checkpoint 已保存: $AUTO_CP_FILE"

# 2. Skill 使用日志（为 /evolve 数据驱动清理提供依据）
SKILL_LOG=".agent/logs/skill-usage.tsv"
mkdir -p "$(dirname "$SKILL_LOG")"

# 如果日志文件不存在，写入表头
if [ ! -f "$SKILL_LOG" ]; then
    echo -e "timestamp\tsession_id\tskill_name\tevent\tresult\tnotes" > "$SKILL_LOG"
    echo "📊 skill 使用日志已创建: $SKILL_LOG"
fi

# 从 auto-checkpoint 中提取本次会话修改的 skill 文件（自动检测）
if git rev-parse --is-inside-work-tree &>/dev/null; then
    SKILL_CHANGES=$(git diff --name-only HEAD~5 HEAD 2>/dev/null | grep -E '\.agent/skills/.*SKILL\.md' | sed 's|.agent/skills/||;s|/SKILL.md||' || true)
    if [ -n "$SKILL_CHANGES" ]; then
        SESSION_ID="session-$TIMESTAMP"
        while IFS= read -r skill_name; do
            echo -e "$TIMESTAMP\t$SESSION_ID\t$skill_name\tmodified\t-\tauto-detected from git diff" >> "$SKILL_LOG"
        done <<< "$SKILL_CHANGES"
        echo "📊 检测到 skill 变更并已记录到使用日志"
    fi
fi

echo ""
echo "💡 提示: Agent 应在会话中主动记录 skill 使用情况到 $SKILL_LOG"
echo "   格式: TIMESTAMP | SESSION_ID | SKILL_NAME | EVENT(selected|applied|completed|fallback|failed) | RESULT(ok|fail) | NOTES"

# 3. 保留最近 10 个 auto-checkpoint，清理旧的
TOTAL_CPS=$(ls -1 "$AUTO_CP_DIR"/auto-checkpoint-*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$TOTAL_CPS" -gt 10 ]; then
    ls -1t "$AUTO_CP_DIR"/auto-checkpoint-*.md | tail -n +11 | xargs rm -f
    echo "🧹 已清理旧的 auto-checkpoint（保留最近 10 个）"
fi

echo ""
echo "=== 会话结束保存完成 ==="
