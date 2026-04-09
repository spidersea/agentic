#!/bin/bash
# reasoning-relay-check.sh — Post-tool hook for reasoning depth explosion (邪修二式)
# Monitors reasoning relay files for quality degradation
#
# Exit codes:
#   0 = OK (pass through)
#   1 = Warning (non-fatal, feedback appended)
#   2 = Reject (fatal, tool result marked as error)

set -euo pipefail

# Only trigger on write operations to reasoning-relay files
TOOL_NAME="${HOOK_TOOL_NAME:-}"
TOOL_INPUT="${HOOK_TOOL_INPUT:-}"

# Check if this is a write to a reasoning-relay file
if [[ "$TOOL_NAME" != "write_to_file" && "$TOOL_NAME" != "replace_file_content" ]]; then
    exit 0
fi

# Extract file path from tool input (best-effort parse)
if ! echo "$TOOL_INPUT" | grep -q "reasoning-relay"; then
    exit 0
fi

# Read the tool input from stdin for full JSON payload
PAYLOAD=$(cat)
FILE_PATH=$(echo "$PAYLOAD" | grep -oP '"TargetFile"\s*:\s*"([^"]+)"' | head -1 | sed 's/.*: *"//;s/"//' 2>/dev/null || echo "")

if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# Quality checks on the reasoning relay file
WORD_COUNT=$(wc -w < "$FILE_PATH" | tr -d ' ')
LINE_COUNT=$(wc -l < "$FILE_PATH" | tr -d ' ')

# Check 1: File too short (possible reasoning decay)
if [[ "$WORD_COUNT" -lt 50 ]]; then
    echo "⚠️ [推理接力质量警告] 文件 $FILE_PATH 仅 ${WORD_COUNT} 词 — 疑似推理衰减。请展开分析，确保中间结论包含具体证据和推理步骤。"
    exit 1
fi

# Check 2: No structured conclusions
if ! grep -qiE "(结论|conclusion|因此|therefore|发现|finding|假设|hypothesis)" "$FILE_PATH"; then
    echo "⚠️ [推理接力结构警告] 文件 $FILE_PATH 缺少结构化结论标记。推理接力文件应包含明确的「结论/发现/假设」段落。"
    exit 1
fi

# Check 3: File too long (single relay should be ≤8 reasoning steps)
if [[ "$LINE_COUNT" -gt 120 ]]; then
    echo "⚠️ [推理接力长度警告] 文件 $FILE_PATH 达 ${LINE_COUNT} 行 — 超过单轮推理接力建议上限。考虑拆分为下一轮接力以保持推理质量。"
    exit 1
fi

# All checks passed
exit 0
