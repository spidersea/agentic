#!/bin/bash
# overconfidence-detector.sh — Post-tool hook (框架补完)
# 检测连续"过度确认"模式，强制注入 Adversary 质疑
#
# 原理: AI 模型经 RLHF 训练后倾向输出"看起来没问题"。
# 当连续 3+ 次工具调用结果都被判定为"成功"且无质疑时，
# 本 Hook 注入警告，提醒执行对抗自检（Rule 14）。
#
# Exit codes:
#   0 = OK (pass through)
#   1 = Warning (注入质疑提醒，非阻塞)

set -uo pipefail

TOOL_NAME="${HOOK_TOOL_NAME:-}"
TOOL_IS_ERROR="${HOOK_TOOL_IS_ERROR:-false}"

COUNTER_FILE=".agent/state/memory-palace/.overconfidence-counter"

# Ensure directory exists
mkdir -p "$(dirname "$COUNTER_FILE")" 2>/dev/null || true

# Initialize counter file if missing
if [[ ! -f "$COUNTER_FILE" ]]; then
    echo "0" > "$COUNTER_FILE"
fi

# Only track execution-type tools (not reads)
if [[ "$TOOL_NAME" != "run_command" && "$TOOL_NAME" != "write_to_file" && "$TOOL_NAME" != "replace_file_content" && "$TOOL_NAME" != "multi_replace_file_content" ]]; then
    exit 0
fi

CURRENT_COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")

if [[ "$TOOL_IS_ERROR" == "true" ]]; then
    # Error breaks the streak — reset counter
    echo "0" > "$COUNTER_FILE"
    exit 0
fi

# Success — increment counter
NEW_COUNT=$((CURRENT_COUNT + 1))
echo "$NEW_COUNT" > "$COUNTER_FILE"

# Threshold: 5 consecutive successes without any error
if [[ "$NEW_COUNT" -ge 5 ]]; then
    echo "0" > "$COUNTER_FILE"  # Reset after firing
    echo "⚠️ [过度确认检测] 连续 ${NEW_COUNT} 次操作均成功 — 触发对抗自检（Rule 14）。请在继续前生成至少 1 个可能使当前方案失败的反例场景。如在安全相关变更中，升级为 3 个反例。参见 .agent/rules/adversarial-persona.md"
    exit 1
fi

exit 0
