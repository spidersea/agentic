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

# 2. 保留最近 10 个 auto-checkpoint，清理旧的
TOTAL_CPS=$(ls -1 "$AUTO_CP_DIR"/auto-checkpoint-*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$TOTAL_CPS" -gt 10 ]; then
    ls -1t "$AUTO_CP_DIR"/auto-checkpoint-*.md | tail -n +11 | xargs rm -f
    echo "🧹 已清理旧的 auto-checkpoint（保留最近 10 个）"
fi

echo ""
echo "=== 会话结束保存完成 ==="
