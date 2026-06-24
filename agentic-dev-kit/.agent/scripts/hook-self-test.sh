#!/usr/bin/env bash
# hook-self-test.sh -- verifies local post-tool hooks recognize Codex Desktop tool names.

set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/codex-hook-self-test.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

cd "$TMP"
mkdir -p .agent/state
echo "echo guard" > .agent/state/.active-guard

HOOK_TOOL_NAME=functions.apply_patch HOOK_TOOL_IS_ERROR=false \
    "$CODEX_HOME/hooks/post-tool/guard-enforcer.sh" >/tmp/codex-hook-guard.out 2>&1 || true

if [ ! -f .agent/state/.guard-skip-counter ]; then
    echo "CRIT guard hook did not recognize functions.apply_patch"
    cat /tmp/codex-hook-guard.out 2>/dev/null || true
    exit 2
fi

HOOK_TOOL_NAME=functions.exec_command HOOK_TOOL_IS_ERROR=true HOOK_TOOL_OUTPUT="FAILED hook self test" \
    "$CODEX_HOME/hooks/post-tool/memory-update.sh"

if ! grep -q "functions.exec_command" .agent/state/memory-palace/failure-patterns.jsonl 2>/dev/null; then
    echo "CRIT memory hook did not record functions.exec_command failure"
    exit 2
fi

HOOK_TOOL_NAME=functions.exec_command HOOK_TOOL_IS_ERROR=false \
    "$CODEX_HOME/hooks/post-tool/overconfidence-detector.sh" >/dev/null

echo "PASS hook self-test"
