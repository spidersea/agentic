#!/usr/bin/env bash
# hook-self-test.sh -- verifies local post-tool hooks recognize Codex Desktop tool names.

set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
# 在 cd 到 tmp 前解析项目根目录（查找含 AGENT.md 的最近祖先目录）
_find_project_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/AGENT.md" && -d "$dir/.agent" ]]; then
            echo "$dir"
            return
        fi
        dir="$(dirname "$dir")"
    done
    echo "$PWD"
}
PROJECT_ROOT="${PROJECT_ROOT:-$(_find_project_root)}"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/codex-hook-self-test.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

# Hook 路径解析：优先项目本地 .agent/hooks/，回退到全局 $CODEX_HOME/hooks/
resolve_hook() {
    local hook_path="hooks/post-tool/$1"
    if [[ -f "$PROJECT_ROOT/.agent/$hook_path" ]]; then
        echo "$PROJECT_ROOT/.agent/$hook_path"
    elif [[ -f "$CODEX_HOME/$hook_path" ]]; then
        echo "$CODEX_HOME/$hook_path"
    else
        echo ""
    fi
}

GUARD_HOOK=$(resolve_hook "guard-enforcer.sh")
MEMORY_HOOK=$(resolve_hook "memory-update.sh")
OVERCONF_HOOK=$(resolve_hook "overconfidence-detector.sh")

cd "$TMP"
mkdir -p .agent/state

# Test 1: guard-enforcer 识别 functions.apply_patch
if [[ -n "$GUARD_HOOK" ]]; then
    echo "echo guard" > .agent/state/.active-guard
    HOOK_TOOL_NAME=functions.apply_patch HOOK_TOOL_IS_ERROR=false \
        "$GUARD_HOOK" >/tmp/codex-hook-guard.out 2>&1 || true
    if [ ! -f .agent/state/.guard-skip-counter ]; then
        echo "CRIT guard hook did not recognize functions.apply_patch"
        cat /tmp/codex-hook-guard.out 2>/dev/null || true
        exit 2
    fi
else
    echo "SKIP guard-enforcer.sh not found (neither local nor global)"
fi

# Test 2: memory-update 记录失败
if [[ -n "$MEMORY_HOOK" ]]; then
    HOOK_TOOL_NAME=functions.exec_command HOOK_TOOL_IS_ERROR=true HOOK_TOOL_OUTPUT="FAILED hook self test" \
        "$MEMORY_HOOK"
    if ! grep -q "functions.exec_command" .agent/state/memory-palace/failure-patterns.jsonl 2>/dev/null; then
        echo "CRIT memory hook did not record functions.exec_command failure"
        exit 2
    fi
else
    echo "SKIP memory-update.sh not found (neither local nor global)"
fi

# Test 3: overconfidence-detector 基本运行
if [[ -n "$OVERCONF_HOOK" ]]; then
    HOOK_TOOL_NAME=functions.exec_command HOOK_TOOL_IS_ERROR=false \
        "$OVERCONF_HOOK" >/dev/null
else
    echo "SKIP overconfidence-detector.sh not found (neither local nor global)"
fi

echo "PASS hook self-test"
