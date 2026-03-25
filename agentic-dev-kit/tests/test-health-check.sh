#!/usr/bin/env bash
# ============================================================================
# test-health-check.sh — 验证 health-check.sh 在当前项目上正常运行
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HEALTH_CHECK="$PROJECT_ROOT/.agent/scripts/health-check.sh"

ERRORS=0

echo "  Test 1: health-check runs without crash"
OUTPUT=$(bash "$HEALTH_CHECK" "$PROJECT_ROOT" 2>&1)
EXIT_CODE=$?
if [ "$EXIT_CODE" -le 2 ]; then
    echo "    PASS: health-check completed (exit=$EXIT_CODE)"
else
    echo "    FAIL: health-check crashed (exit=$EXIT_CODE)"
    ERRORS=$((ERRORS + 1))
fi

echo "  Test 2: output contains expected sections"
SECTIONS_FOUND=0
echo "$OUTPUT" | grep -q "核心指令文件统计" && SECTIONS_FOUND=$((SECTIONS_FOUND + 1))
echo "$OUTPUT" | grep -q "组件数量" && SECTIONS_FOUND=$((SECTIONS_FOUND + 1))
echo "$OUTPUT" | grep -q "单文件行数" && SECTIONS_FOUND=$((SECTIONS_FOUND + 1))
echo "$OUTPUT" | grep -q "规则密度" && SECTIONS_FOUND=$((SECTIONS_FOUND + 1))
echo "$OUTPUT" | grep -q "总结" && SECTIONS_FOUND=$((SECTIONS_FOUND + 1))
if [ "$SECTIONS_FOUND" -ge 4 ]; then
    echo "    PASS: found $SECTIONS_FOUND/5 expected sections"
else
    echo "    FAIL: found $SECTIONS_FOUND/5 expected sections"
    ERRORS=$((ERRORS + 1))
fi

echo "  Test 3: health-check fails on empty dir"
TMPDIR_TEST=$(mktemp -d)
bash "$HEALTH_CHECK" "$TMPDIR_TEST" > /dev/null 2>&1
HC_EXIT=$?
if [ "$HC_EXIT" -eq 2 ]; then
    echo "    PASS: correctly fails on empty dir (exit=2)"
else
    echo "    FAIL: expected exit=2 on empty dir, got exit=$HC_EXIT"
    ERRORS=$((ERRORS + 1))
fi
rm -rf "$TMPDIR_TEST"

echo "  Results: $((3 - ERRORS))/3 passed"

if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi
exit 0
