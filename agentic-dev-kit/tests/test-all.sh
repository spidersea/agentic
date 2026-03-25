#!/usr/bin/env bash
# ============================================================================
# test-all.sh — 测试 Runner
# 运行所有 tests/ 目录下的测试文件，汇总结果
# 用法: bash tests/test-all.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ─── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

TOTAL=0
PASSED=0
FAILED=0
FAILED_TESTS=""

echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║    Agentic Dev Kit — Test Suite v1.0     ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# Find and run all test files
while IFS= read -r test_file; do
    test_name=$(basename "$test_file" .sh)
    TOTAL=$((TOTAL + 1))

    echo -e "${BOLD}▸ Running: ${test_name}${NC}"

    if bash "$test_file" 2>&1 | tail -5 | sed 's/^/  /'; then
        PASSED=$((PASSED + 1))
        echo -e "  ${GREEN}→ PASS${NC}"
    else
        FAILED=$((FAILED + 1))
        FAILED_TESTS="${FAILED_TESTS}\n  - ${test_name}"
        echo -e "  ${RED}→ FAIL${NC}"
    fi
    echo ""
done < <(find "$SCRIPT_DIR" -name "test-*.sh" ! -name "test-all.sh" -type f | sort)

# Summary
echo -e "${BOLD}━━━ Test Results ━━━${NC}"
echo ""
echo -e "  Total:  ${TOTAL}"
echo -e "  Passed: ${GREEN}${PASSED}${NC}"
echo -e "  Failed: ${RED}${FAILED}${NC}"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "  ${RED}${BOLD}❌ ${FAILED} test(s) failed:${FAILED_TESTS}${NC}"
    exit 1
fi
