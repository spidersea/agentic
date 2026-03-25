#!/usr/bin/env bash
# ============================================================================
# test-validate-structure.sh — 验证 validate-structure.sh 的正确性
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALIDATOR="$PROJECT_ROOT/.agent/scripts/validate-structure.sh"

ERRORS=0

assert_exit() {
    local expected=$1
    local actual=$2
    local name=$3
    if [ "$actual" -eq "$expected" ]; then
        echo "    PASS: $name (exit=$actual)"
    else
        echo "    FAIL: $name (expected exit=$expected, got exit=$actual)"
        ERRORS=$((ERRORS + 1))
    fi
}

echo "  Test 1: validator passes on real project"
bash "$VALIDATOR" "$PROJECT_ROOT" > /dev/null 2>&1
assert_exit 0 $? "validate-structure on real project"

echo "  Test 2: validator fails on empty temp dir"
TMPDIR_TEST=$(mktemp -d)
bash "$VALIDATOR" "$TMPDIR_TEST" > /dev/null 2>&1
EXIT_CODE=$?
if [ "$EXIT_CODE" -ne 0 ]; then
    echo "    PASS: correctly fails on empty dir (exit=$EXIT_CODE)"
else
    echo "    FAIL: should fail on empty dir but got exit=0"
    ERRORS=$((ERRORS + 1))
fi
rm -rf "$TMPDIR_TEST"

echo "  Test 3: validator detects missing .agent dir"
TMPDIR_TEST2=$(mktemp -d)
echo "# AGENT.md" > "$TMPDIR_TEST2/AGENT.md"
bash "$VALIDATOR" "$TMPDIR_TEST2" > /dev/null 2>&1
EXIT_CODE=$?
if [ "$EXIT_CODE" -ne 0 ]; then
    echo "    PASS: correctly detects missing .agent/ (exit=$EXIT_CODE)"
else
    echo "    FAIL: should detect missing .agent/ but got exit=0"
    ERRORS=$((ERRORS + 1))
fi
rm -rf "$TMPDIR_TEST2"

echo "  Results: $((3 - ERRORS))/3 passed"

if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi
exit 0
