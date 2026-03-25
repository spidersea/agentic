#!/usr/bin/env bash
# ============================================================================
# escalation-tracker.sh — 压力升级状态机（程序化实现）
# 将 L1-L4 压力升级从"Markdown 指令"变为"可执行状态机"
# 用法:
#   escalation-tracker.sh fail     记录一次失败，输出当前等级和强制动作
#   escalation-tracker.sh reset    重置计数（成功后调用）
#   escalation-tracker.sh status   输出当前状态
#   escalation-tracker.sh serialize 输出 PreCompact 格式序列化
# 退出码: 当前压力等级 (0=正常, 1=L1, 2=L2, 3=L3, 4=L4)
# ============================================================================

set -uo pipefail

# ─── Config ──────────────────────────────────────────────────
STATE_DIR="${AGENTIC_STATE_DIR:-.agent}"
STATE_FILE="$STATE_DIR/.escalation-state"

# ─── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── State Management ───────────────────────────────────────
load_state() {
    if [ -f "$STATE_FILE" ]; then
        FAIL_COUNT=$(grep "^FAIL_COUNT=" "$STATE_FILE" | cut -d= -f2)
        LEVEL=$(grep "^LEVEL=" "$STATE_FILE" | cut -d= -f2)
        METHODOLOGY=$(grep "^METHODOLOGY=" "$STATE_FILE" | cut -d= -f2)
        METHOD_SWITCHES=$(grep "^METHOD_SWITCHES=" "$STATE_FILE" | cut -d= -f2)
        LAST_FAIL_TIME=$(grep "^LAST_FAIL_TIME=" "$STATE_FILE" | cut -d= -f2)
        ATTEMPTS_LOG=$(grep "^ATTEMPTS_LOG=" "$STATE_FILE" | cut -d= -f2-)
    fi
    FAIL_COUNT=${FAIL_COUNT:-0}
    LEVEL=${LEVEL:-0}
    METHODOLOGY=${METHODOLOGY:-"default"}
    METHOD_SWITCHES=${METHOD_SWITCHES:-0}
    LAST_FAIL_TIME=${LAST_FAIL_TIME:-""}
    ATTEMPTS_LOG=${ATTEMPTS_LOG:-""}
}

save_state() {
    mkdir -p "$(dirname "$STATE_FILE")"
    cat > "$STATE_FILE" <<EOF
FAIL_COUNT=$FAIL_COUNT
LEVEL=$LEVEL
METHODOLOGY=$METHODOLOGY
METHOD_SWITCHES=$METHOD_SWITCHES
LAST_FAIL_TIME=$LAST_FAIL_TIME
ATTEMPTS_LOG=$ATTEMPTS_LOG
EOF
}

# ─── Level Calculation ───────────────────────────────────────
calculate_level() {
    if [ "$FAIL_COUNT" -ge 5 ]; then
        LEVEL=4
    elif [ "$FAIL_COUNT" -ge 4 ]; then
        LEVEL=3
    elif [ "$FAIL_COUNT" -ge 3 ]; then
        LEVEL=2
    elif [ "$FAIL_COUNT" -ge 2 ]; then
        LEVEL=1
    else
        LEVEL=0
    fi
}

# ─── Level Display ───────────────────────────────────────────
display_level() {
    case $LEVEL in
        0)
            echo -e "${GREEN}[L0 ✅] 正常${NC} — 连续失败: $FAIL_COUNT"
            ;;
        1)
            echo -e "${YELLOW}[L1 ⚡] 切换方案${NC} — 连续失败: $FAIL_COUNT"
            echo ""
            echo -e "  ${BOLD}强制动作:${NC}"
            echo "  • 必须切换【本质不同】的方案（换参数/换函数名不算！）"
            echo "  • 修完必须验证，不可修完不跑测试"
            ;;
        2)
            echo -e "${YELLOW}[L2 🔍] 深度调查${NC} — 连续失败: $FAIL_COUNT"
            echo ""
            echo -e "  ${BOLD}强制动作:${NC}"
            echo "  • 用工具搜索报错原文 + 官方文档"
            echo "  • 读源码上下文 50 行（不是摘要或记忆）"
            echo "  • 列出 3 个假设并逐一用工具验证"
            echo "  • 建议切换方法论"
            ;;
        3)
            echo -e "${RED}[L3 📋] 强制清单${NC} — 连续失败: $FAIL_COUNT"
            echo ""
            echo -e "  ${BOLD}强制动作 — 七项检查清单（每项必须打勾）:${NC}"
            echo "  □ 逐字读完失败信号（完整错误信息、stack trace、日志）"
            echo "  □ 用工具搜索过核心问题（报错原文/官方文档/多角度关键词）"
            echo "  □ 读过失败位置的原始上下文（源码上下文 50 行）"
            echo "  □ 所有假设都用工具确认（版本号、路径、权限、依赖）"
            echo "  □ 试过完全相反的假设"
            echo "  □ 能在最小范围内复现问题"
            echo "  □ 换过工具/方法/角度/技术栈（本质不同的方案）"
            ;;
        4)
            echo -e "${RED}${BOLD}[L4 🚨] 最后手段${NC} — 连续失败: $FAIL_COUNT"
            echo ""
            echo -e "  ${BOLD}强制动作:${NC}"
            echo "  • 强制切换方法论（参见 methodology-router.md）"
            echo "  • 进入拼命模式 — 穷尽一切后才允许结构化退出"
            echo "  • 七项检查清单仍为前置条件"
            METHOD_SWITCHES=$((METHOD_SWITCHES + 1))
            ;;
    esac
}

# ─── Commands ────────────────────────────────────────────────
cmd_fail() {
    load_state
    FAIL_COUNT=$((FAIL_COUNT + 1))
    LAST_FAIL_TIME=$(date '+%Y-%m-%dT%H:%M:%S')
    calculate_level
    save_state

    echo -e "${BOLD}${CYAN}━━━ Escalation Tracker ━━━${NC}"
    echo ""
    display_level
    echo ""
    exit $LEVEL
}

cmd_reset() {
    load_state
    OLD_LEVEL=$LEVEL
    FAIL_COUNT=0
    LEVEL=0
    LAST_FAIL_TIME=""
    save_state

    echo -e "${GREEN}${BOLD}✅ 压力等级已重置${NC} (L${OLD_LEVEL} → L0)"
    echo "  连续失败计数: 0"
    exit 0
}

cmd_status() {
    load_state
    calculate_level

    echo -e "${BOLD}${CYAN}━━━ Escalation Status ━━━${NC}"
    echo ""
    echo "  连续失败: $FAIL_COUNT"
    echo "  当前等级: L$LEVEL"
    echo "  方法论: $METHODOLOGY"
    echo "  方法论切换次数: $METHOD_SWITCHES"
    if [ -n "$LAST_FAIL_TIME" ]; then
        echo "  最后失败: $LAST_FAIL_TIME"
    fi
    echo ""
    exit $LEVEL
}

cmd_serialize() {
    load_state
    calculate_level

    cat <<EOF
# 压缩前状态快照

## 时间戳
$(date '+%Y-%m-%dT%H:%M:%S%z')

## 运行时状态
- 当前 Escalation 等级: L${LEVEL}
- 连续失败计数: ${FAIL_COUNT}
- 当前方法论: ${METHODOLOGY}
- 方法论切换次数: ${METHOD_SWITCHES}

## 最后失败时间
${LAST_FAIL_TIME:-N/A}
EOF
    exit 0
}

# ─── Router ──────────────────────────────────────────────────
case "${1:-status}" in
    fail)       cmd_fail ;;
    reset)      cmd_reset ;;
    status)     cmd_status ;;
    serialize)  cmd_serialize ;;
    *)
        echo "Usage: escalation-tracker.sh <fail|reset|status|serialize>"
        exit 1
        ;;
esac
