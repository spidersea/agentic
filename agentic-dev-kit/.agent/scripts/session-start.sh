#!/usr/bin/env bash
# session-start.sh — 会话开始时自动执行，发现最新检查点并输出状态摘要
# 用法: bash .agent/scripts/session-start.sh
# 设计: 轻量级（<3秒）、幂等、无副作用

set -euo pipefail

echo "=== 🚀 会话启动检查 ==="
echo ""

# 1. 查找最新的 checkpoint 文件
echo "📋 检查点状态:"
CHECKPOINTS=$(find . -name "checkpoint-*.md" -o -name "*_checkpoint*" 2>/dev/null | sort -r | head -5)
if [ -n "$CHECKPOINTS" ]; then
    LATEST=$(echo "$CHECKPOINTS" | head -1)
    echo "  最新检查点: $LATEST"
    echo "  修改时间: $(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$LATEST" 2>/dev/null || stat -c '%y' "$LATEST" 2>/dev/null | cut -d. -f1)"
    echo "  ---"
    # 输出检查点摘要（前 15 行）
    head -15 "$LATEST" 2>/dev/null | sed 's/^/  /'
    echo ""
else
    echo "  ⚠️ 未找到检查点文件"
fi

# 2. 查找最新的 handoff 文件
echo ""
echo "🤝 交接备忘录:"
HANDOFFS=$(find . -name "handoff-*.md" -o -name "*_handoff*" 2>/dev/null | sort -r | head -3)
if [ -n "$HANDOFFS" ]; then
    LATEST_HO=$(echo "$HANDOFFS" | head -1)
    echo "  最新交接: $LATEST_HO"
    echo "  修改时间: $(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$LATEST_HO" 2>/dev/null || stat -c '%y' "$LATEST_HO" 2>/dev/null | cut -d. -f1)"
else
    echo "  无交接备忘录"
fi

# 3. 检查未提交的 git 变更
echo ""
echo "📊 Git 状态:"
if git rev-parse --is-inside-work-tree &>/dev/null; then
    UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    LAST_COMMIT=$(git log -1 --format='%h %s' 2>/dev/null || echo "无提交记录")
    echo "  最近提交: $LAST_COMMIT"
    echo "  未提交变更: $UNCOMMITTED 个文件"
    if [ "$UNCOMMITTED" -gt 0 ]; then
        echo "  ⚠️ 存在未提交变更，建议确认是否为上次会话遗留"
    fi
else
    echo "  不在 git 仓库中"
fi

# 4. 检查本能系统状态
echo ""
echo "🧠 本能系统:"
if [ -f ".agent/instincts/pending.yml" ]; then
    INSTINCT_COUNT=$(grep -c "^- id:" .agent/instincts/pending.yml 2>/dev/null || echo "0")
    HIGH_CONF=$(grep -A1 "confidence:" .agent/instincts/pending.yml 2>/dev/null | grep -E "confidence: [4-5]" | wc -l | tr -d ' ')
    echo "  活跃本能: $INSTINCT_COUNT 条"
    if [ "$HIGH_CONF" -gt 0 ]; then
        echo "  🔥 高置信度本能: $HIGH_CONF 条（可通过 /evolve 升级）"
    fi
else
    echo "  暂无本能数据（首次使用可运行 /learn 开始提取）"
fi

echo ""
echo "=== 启动检查完成 ==="
echo "💡 建议: 如有未完成任务，使用 /resume 恢复上下文"
