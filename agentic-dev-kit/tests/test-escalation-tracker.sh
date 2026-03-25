#!/usr/bin/env bash
# ============================================================================
# test-escalation-tracker.sh — 测试压力升级状态机行为
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TRACKER="$PROJECT_ROOT/.agent/scripts/escalation-tracker.sh"

ERRORS=0

# Use a temp state directory to avoid polluting real state
export AGENTIC_STATE_DIR=$(mktemp -d)
mkdir -p "$AGENTIC_STATE_DIR"
trap "rm -rf $AGENTIC_STATE_DIR" EXIT

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

echo "  Test 1: initial status is L0"
bash "$TRACKER" status > /dev/null 2>&1
assert_exit 0 $? "initial status = L0"

echo "  Test 2: first fail → still L0 (1 failure allowed)"
bash "$TRACKER" fail > /dev/null 2>&1
assert_exit 0 $? "first fail = L0"

echo "  Test 3: second fail → L1"
bash "$TRACKER" fail > /dev/null 2>&1
assert_exit 1 $? "second fail = L1"

echo "  Test 4: third fail → L2"
bash "$TRACKER" fail > /dev/null 2>&1
assert_exit 2 $? "third fail = L2"

echo "  Test 5: fourth fail → L3"
bash "$TRACKER" fail > /dev/null 2>&1
assert_exit 3 $? "fourth fail = L3"

echo "  Test 6: fifth fail → L4"
bash "$TRACKER" fail > /dev/null 2>&1
assert_exit 4 $? "fifth fail = L4"

echo "  Test 7: reset → L0"
bash "$TRACKER" reset > /dev/null 2>&1
assert_exit 0 $? "reset = L0"

echo "  Test 8: status after reset → L0"
bash "$TRACKER" status > /dev/null 2>&1
assert_exit 0 $? "status after reset = L0"

echo "  Test 9: serialize outputs markdown"
OUTPUT=$(bash "$TRACKER" serialize 2>&1)
if echo "$OUTPUT" | grep -q "Escalation 等级"; then
    echo "    PASS: serialize contains expected fields"
else
    echo "    FAIL: serialize missing expected fields"
    ERRORS=$((ERRORS + 1))
fi

echo "  Test 10: state persists via file"
bash "$TRACKER" fail > /dev/null 2>&1  # fail 1
bash "$TRACKER" fail > /dev/null 2>&1  # fail 2 → L1
if [ -f "$AGENTIC_STATE_DIR/.escalation-state" ]; then
    echo "    PASS: state file exists"
    FAIL_COUNT=$(grep "^FAIL_COUNT=" "$AGENTIC_STATE_DIR/.escalation-state" | cut -d= -f2)
    if [ "$FAIL_COUNT" = "2" ]; then
        echo "    PASS: state file has correct fail count ($FAIL_COUNT)"
    else
        echo "    FAIL: expected FAIL_COUNT=2, got $FAIL_COUNT"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "    FAIL: state file not created"
    ERRORS=$((ERRORS + 1))
fi

TOTAL=11
PASS=$((TOTAL - ERRORS))
echo "  Results: $PASS/$TOTAL passed"

if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi
exit 0
