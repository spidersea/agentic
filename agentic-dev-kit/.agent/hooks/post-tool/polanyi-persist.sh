#!/bin/bash
# polanyi-persist.sh — Post-tool hook for Polanyi Excavation incremental persistence
# Automatically archives Polanyi findings to captured-patterns when tacit-tradition-map is updated
#
# Exit codes:
#   0 = OK (pass through, persistence is non-blocking)

set -uo pipefail

TOOL_NAME="${HOOK_TOOL_NAME:-}"
TOOL_INPUT="${HOOK_TOOL_INPUT:-}"

# Only trigger on writes to tacit-tradition-map
if [[ "$TOOL_NAME" != "write_to_file" && "$TOOL_NAME" != "replace_file_content" && "$TOOL_NAME" != "multi_replace_file_content" ]]; then
    exit 0
fi

if ! echo "$TOOL_INPUT" | grep -q "tacit-tradition-map"; then
    exit 0
fi

TARGET_FILE=".agent/state/tacit-tradition-map.md"
ARCHIVE_DIR=".agent/state/captured-patterns"
TIMESTAMP=$(date -u +%FT%TZ 2>/dev/null || echo "unknown")

# Ensure archive directory exists
mkdir -p "$ARCHIVE_DIR" 2>/dev/null || true

# Archive a snapshot of the tacit tradition map (incremental history)
if [[ -f "$TARGET_FILE" ]]; then
    SNAP_NAME="tacit-snapshot-$(date -u +%Y%m%d-%H%M%S 2>/dev/null || echo 'unknown').md"
    # Only archive if file has meaningful content (>5 lines)
    LINE_COUNT=$(wc -l < "$TARGET_FILE" | tr -d ' ')
    if [[ "$LINE_COUNT" -gt 5 ]]; then
        cp "$TARGET_FILE" "$ARCHIVE_DIR/$SNAP_NAME" 2>/dev/null || true
        
        # Prune old snapshots — keep only last 10
        ls -t "$ARCHIVE_DIR"/tacit-snapshot-*.md 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
    fi
fi

exit 0
