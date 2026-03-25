#!/usr/bin/env bash
# ============================================================================
# test-scripts-syntax.sh — 对所有 .sh 脚本执行 bash -n 语法检查
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ERRORS=0
CHECKED=0

echo "  Checking all .sh script syntax..."

# Check .agent/scripts/
while IFS= read -r f; do
    CHECKED=$((CHECKED + 1))
    if ! bash -n "$f" 2>/dev/null; then
        rel="${f#$PROJECT_ROOT/}"
        echo "    FAIL: $rel"
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$PROJECT_ROOT/.agent/scripts" -name "*.sh" 2>/dev/null)

# Check bin/
while IFS= read -r f; do
    CHECKED=$((CHECKED + 1))
    if ! bash -n "$f" 2>/dev/null; then
        rel="${f#$PROJECT_ROOT/}"
        echo "    FAIL: $rel"
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$PROJECT_ROOT/bin" -type f 2>/dev/null)

# Check tests/
while IFS= read -r f; do
    CHECKED=$((CHECKED + 1))
    if ! bash -n "$f" 2>/dev/null; then
        rel="${f#$PROJECT_ROOT/}"
        echo "    FAIL: $rel"
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$PROJECT_ROOT/tests" -name "*.sh" 2>/dev/null)

echo "  Checked $CHECKED scripts, $ERRORS errors"

if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi
exit 0
