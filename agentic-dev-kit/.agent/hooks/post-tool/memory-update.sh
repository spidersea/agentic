#!/bin/bash
# memory-update.sh — Post-tool hook for Memory Palace (邪修六式)
# Automatically records decisions, assumptions, and failure patterns
# to persistent storage for cross-turn and cross-session memory.
#
# Exit codes:
#   0 = OK (always pass through, memory recording is non-blocking)

set -uo pipefail

TOOL_NAME="${HOOK_TOOL_NAME:-}"
TOOL_OUTPUT="${HOOK_TOOL_OUTPUT:-}"
TOOL_IS_ERROR="${HOOK_TOOL_IS_ERROR:-false}"

MEMORY_DIR=".agent/state/memory-palace"
TIMESTAMP=$(date -u +%FT%TZ 2>/dev/null || echo "unknown")

# Ensure memory directory exists
mkdir -p "$MEMORY_DIR" 2>/dev/null || true

# ── Record failure patterns on command errors ──
if [[ "$TOOL_NAME" == "run_command" && "$TOOL_IS_ERROR" == "true" ]]; then
    # Extract error summary (first 200 chars of output)
    ERROR_SUMMARY=$(echo "$TOOL_OUTPUT" | head -c 200 | tr '\n' ' ' | tr '\t' ' ' | tr '"' "'")
    echo "{\"ts\":\"$TIMESTAMP\",\"tool\":\"$TOOL_NAME\",\"error\":\"$ERROR_SUMMARY\"}" \
        >> "$MEMORY_DIR/failure-patterns.jsonl" 2>/dev/null || true
fi

# ── Record file modification decisions ──
if [[ "$TOOL_NAME" == "write_to_file" || "$TOOL_NAME" == "replace_file_content" || "$TOOL_NAME" == "multi_replace_file_content" ]]; then
    # Read full payload from stdin for file path extraction
    PAYLOAD=$(cat 2>/dev/null || echo "")
    FILE_PATH=$(echo "$PAYLOAD" | grep -oE '"TargetFile"\s*:\s*"[^"]+"' | head -1 | sed 's/.*"TargetFile"\s*:\s*"//;s/"//' 2>/dev/null || echo "unknown")

    if [[ "$FILE_PATH" != "unknown" && ! "$FILE_PATH" =~ memory-palace && ! "$FILE_PATH" =~ reasoning-relay ]]; then
        echo "{\"ts\":\"$TIMESTAMP\",\"file\":\"$FILE_PATH\",\"action\":\"$TOOL_NAME\"}" \
            >> "$MEMORY_DIR/decisions.jsonl" 2>/dev/null || true
    fi
fi

# ── Prune old entries to prevent unbounded growth ──
for JSONL_FILE in "$MEMORY_DIR"/*.jsonl; do
    if [[ -f "$JSONL_FILE" ]]; then
        LINE_COUNT=$(wc -l < "$JSONL_FILE" | tr -d ' ')
        if [[ "$LINE_COUNT" -gt 200 ]]; then
            # Keep only the last 100 entries
            tail -100 "$JSONL_FILE" > "$JSONL_FILE.tmp" && mv "$JSONL_FILE.tmp" "$JSONL_FILE"
        fi
    fi
done

# Memory recording is non-blocking — always exit 0
exit 0
