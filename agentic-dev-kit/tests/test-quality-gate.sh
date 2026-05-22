#!/usr/bin/env bash
# ============================================================================
# test-quality-gate.sh — verifies the AI quality gate behavior
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
QUALITY_GATE="$PROJECT_ROOT/.agent/scripts/quality-gate.sh"

ERRORS=0

echo "  Test 1: quality gate passes on real project"
OUTPUT=$(bash "$QUALITY_GATE" "$PROJECT_ROOT" 2>&1)
EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 0 ] && echo "$OUTPUT" | grep -q "VERDICT: PASS"; then
    echo "    PASS: quality gate passed"
else
    echo "    FAIL: quality gate should pass on real project (exit=$EXIT_CODE)"
    echo "$OUTPUT" | tail -10 | sed 's/^/      /'
    ERRORS=$((ERRORS + 1))
fi

echo "  Test 2: quality gate fails when .agent/quality is missing"
TMPDIR_TEST=$(mktemp -d)
mkdir -p "$TMPDIR_TEST/.agent"
bash "$QUALITY_GATE" "$TMPDIR_TEST" > /dev/null 2>&1
EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 2 ]; then
    echo "    PASS: missing quality directory detected"
else
    echo "    FAIL: expected exit=2 for missing quality directory, got exit=$EXIT_CODE"
    ERRORS=$((ERRORS + 1))
fi
rm -rf "$TMPDIR_TEST"

echo "  Test 3: quality gate fails on incomplete evidence"
TMPDIR_TEST2=$(mktemp -d)
mkdir -p "$TMPDIR_TEST2/.agent/quality"
cp "$PROJECT_ROOT/.agent/quality/"*.md "$TMPDIR_TEST2/.agent/quality/"
cp "$PROJECT_ROOT/.agent/quality/requirement-test-matrix.tsv" "$TMPDIR_TEST2/.agent/quality/"
cp "$PROJECT_ROOT/.agent/quality/risk-register.tsv" "$TMPDIR_TEST2/.agent/quality/"
: > "$TMPDIR_TEST2/.agent/quality/evidence-ledger.jsonl"
bash "$QUALITY_GATE" "$TMPDIR_TEST2" > /dev/null 2>&1
EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 1 ]; then
    echo "    PASS: incomplete evidence detected"
else
    echo "    FAIL: expected exit=1 for incomplete evidence, got exit=$EXIT_CODE"
    ERRORS=$((ERRORS + 1))
fi
rm -rf "$TMPDIR_TEST2"

echo "  Results: $((3 - ERRORS))/3 passed"

if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi
exit 0
