#!/bin/bash
# guard-enforcer.sh — Post-tool hook for Constructive Safety (构造性安全)
#
# Inspired by OpenMythos LTI Injection: ρ(A) < 1 by construction.
# Instead of "suggesting" agents run guard commands, this hook FORCES
# guard execution after every file write — making guard bypass physically
# impossible, not just discouraged.
#
# Behavior:
#   - After file-write tools, checks if a guard command exists
#   - If guard exists and file is in scope, queues a guard reminder
#   - Tracks consecutive guard skips; 3+ skips → escalation L2 warning
#
# Exit codes:
#   0 = OK (no guard configured or guard not applicable)
#   1 = Warning (guard reminder injected)

set -uo pipefail

TOOL_NAME="${HOOK_TOOL_NAME:-}"
TOOL_IS_ERROR="${HOOK_TOOL_IS_ERROR:-false}"

# Only trigger on file-write operations OR guard execution detection
case "$TOOL_NAME" in
    write_to_file|replace_file_content|multi_replace_file_content)
        # File write — track guard skip
        ;;
    run_command)
        # Possible guard execution — check if it matches guard command and reset counter
        GUARD_CONFIG_FILE=".agent/state/.active-guard"
        GUARD_SKIP_FILE=".agent/state/.guard-skip-counter"
        if [[ -f "$GUARD_CONFIG_FILE" && -f "$GUARD_SKIP_FILE" ]]; then
            GUARD_CMD=$(cat "$GUARD_CONFIG_FILE" 2>/dev/null || echo "")
            TOOL_INPUT="${HOOK_TOOL_INPUT:-}"
            # If the executed command contains the guard command string, reset counter
            if [[ -n "$GUARD_CMD" && "$TOOL_INPUT" == *"$GUARD_CMD"* ]]; then
                echo "0" > "$GUARD_SKIP_FILE"
            fi
        fi
        exit 0
        ;;
    *) exit 0 ;;
esac

# Skip if the write itself failed
if [[ "$TOOL_IS_ERROR" == "true" ]]; then
    exit 0
fi

STATE_DIR=".agent/state"
GUARD_SKIP_FILE="$STATE_DIR/.guard-skip-counter"
GUARD_CONFIG_FILE="$STATE_DIR/.active-guard"

mkdir -p "$STATE_DIR" 2>/dev/null || true

# Check if a guard command is currently configured
# (Set by autoresearch setup phase or manually via /dsl)
if [[ ! -f "$GUARD_CONFIG_FILE" ]]; then
    # No guard configured — nothing to enforce
    exit 0
fi

GUARD_CMD=$(cat "$GUARD_CONFIG_FILE" 2>/dev/null || echo "")
if [[ -z "$GUARD_CMD" ]]; then
    exit 0
fi

# Initialize skip counter if missing
if [[ ! -f "$GUARD_SKIP_FILE" ]]; then
    echo "0" > "$GUARD_SKIP_FILE"
fi

SKIP_COUNT=$(cat "$GUARD_SKIP_FILE" 2>/dev/null || echo "0")
NEW_SKIP=$((SKIP_COUNT + 1))
echo "$NEW_SKIP" > "$GUARD_SKIP_FILE"

# Threshold: 3 consecutive writes without guard execution → escalation
if [[ "$NEW_SKIP" -ge 3 ]]; then
    echo "0" > "$GUARD_SKIP_FILE"  # Reset after firing
    echo "🛡️ [构造性安全] 连续 ${NEW_SKIP} 次文件写入未执行 guard 命令。"
    echo "   Guard 命令: ${GUARD_CMD}"
    echo "   ⚠️ 升级至 Escalation L2 — 请立即执行 guard 并验证无回归。"
    echo "   原理: 借鉴 OpenMythos LTI ρ(A)<1 — 稳定性从构造上保证，而非事后检查。"
    exit 1
fi

# Normal reminder (non-blocking)
if [[ "$NEW_SKIP" -ge 1 ]]; then
    echo "🛡️ [Guard 提醒] 已累计 ${NEW_SKIP}/3 次写入未执行 guard。Guard: ${GUARD_CMD}"
fi

exit 0
