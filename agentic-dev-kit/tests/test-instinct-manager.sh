#!/usr/bin/env bash
# ============================================================================
# test-instinct-manager.sh — 测试本能管理器行为
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANAGER="$PROJECT_ROOT/.agent/scripts/instinct-manager.sh"

ERRORS=0

# Use temp dir to avoid polluting real state
export AGENTIC_INSTINCT_DIR=$(mktemp -d)
trap "rm -rf $AGENTIC_INSTINCT_DIR" EXIT

echo "  Test 1: initial status shows empty"
OUTPUT=$(bash "$MANAGER" status 2>&1)
if echo "$OUTPUT" | grep -q "总计: 0"; then
    echo "    PASS: initial status shows 0 instincts"
else
    echo "    FAIL: expected 0 instincts"
    ERRORS=$((ERRORS + 1))
fi

echo "  Test 2: add an instinct"
OUTPUT=$(bash "$MANAGER" add "always use type hints in Python" 2>&1)
if echo "$OUTPUT" | grep -q "已添加本能 #1"; then
    echo "    PASS: instinct #1 added"
else
    echo "    FAIL: add failed"
    ERRORS=$((ERRORS + 1))
fi

echo "  Test 3: add second instinct"
bash "$MANAGER" add "prefer composition over inheritance" > /dev/null 2>&1
OUTPUT=$(bash "$MANAGER" status 2>&1)
if echo "$OUTPUT" | grep -q "总计: 2"; then
    echo "    PASS: 2 instincts total"
else
    echo "    FAIL: expected 2 instincts"
    ERRORS=$((ERRORS + 1))
fi

echo "  Test 4: list shows instincts"
OUTPUT=$(bash "$MANAGER" list 2>&1)
if echo "$OUTPUT" | grep -q "type hints"; then
    echo "    PASS: list shows pattern text"
else
    echo "    FAIL: list missing pattern"
    ERRORS=$((ERRORS + 1))
fi

echo "  Test 5: score up"
OUTPUT=$(bash "$MANAGER" score 1 "+" 2>&1)
if echo "$OUTPUT" | grep -q "★1 → ★2"; then
    echo "    PASS: confidence increased to 2"
else
    echo "    FAIL: score up failed"
    ERRORS=$((ERRORS + 1))
fi

echo "  Test 6: score up to max"
bash "$MANAGER" score 1 "+" > /dev/null 2>&1  # → 3
bash "$MANAGER" score 1 "+" > /dev/null 2>&1  # → 4
bash "$MANAGER" score 1 "+" > /dev/null 2>&1  # → 5
OUTPUT=$(bash "$MANAGER" score 1 "+" 2>&1)  # → still 5
if echo "$OUTPUT" | grep -q "★5 → ★5"; then
    echo "    PASS: max confidence capped at 5"
else
    echo "    FAIL: max cap failed"
    ERRORS=$((ERRORS + 1))
fi

echo "  Test 7: score down"
OUTPUT=$(bash "$MANAGER" score 2 "-" 2>&1)
if echo "$OUTPUT" | grep -q "★1 → ★0"; then
    echo "    PASS: confidence decreased to 0"
else
    echo "    FAIL: score down failed"
    ERRORS=$((ERRORS + 1))
fi

echo "  Test 8: prune removes ★0"
OUTPUT=$(bash "$MANAGER" prune 2>&1)
if echo "$OUTPUT" | grep -q "删除 #2"; then
    echo "    PASS: pruned ★0 instinct"
else
    echo "    FAIL: prune failed"
    ERRORS=$((ERRORS + 1))
fi

echo "  Test 9: promote ★5"
OUTPUT=$(bash "$MANAGER" promote 1 2>&1)
if echo "$OUTPUT" | grep -q "已升级为正式规则"; then
    echo "    PASS: promoted to rule"
else
    echo "    FAIL: promote failed"
    ERRORS=$((ERRORS + 1))
fi

echo "  Test 10: promoted log exists"
if [ -f "$AGENTIC_INSTINCT_DIR/promoted.log" ]; then
    echo "    PASS: promoted.log created"
else
    echo "    FAIL: promoted.log missing"
    ERRORS=$((ERRORS + 1))
fi

TOTAL=10
PASS=$((TOTAL - ERRORS))
echo "  Results: $PASS/$TOTAL passed"

if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi
exit 0
