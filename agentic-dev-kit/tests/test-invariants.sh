#!/bin/bash
# =============================================================================
# test-invariants.sh — System Invariant Tests (不变量测试)
#
# Inspired by OpenMythos test_spectral_radius_lt_1 and similar mathematical
# property tests. These verify SYSTEM PROPERTIES rather than specific outputs.
#
# Usage: bash tests/test-invariants.sh [project_root]
# Exit code: 0 = all invariants hold, 1 = violation detected
# =============================================================================

set -uo pipefail

PROJECT_ROOT="${1:-.}"
AGENT_DIR="$PROJECT_ROOT/.agent"
PASS=0
FAIL=0
TOTAL=0

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

assert_invariant() {
    local name="$1"
    local result="$2"  # 0=pass, 1=fail
    TOTAL=$((TOTAL + 1))
    if [ "$result" -eq 0 ]; then
        PASS=$((PASS + 1))
        echo -e "  ${GREEN}✅ PASS${NC}  $name"
    else
        FAIL=$((FAIL + 1))
        echo -e "  ${RED}❌ FAIL${NC}  $name"
    fi
}

echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║     Invariant Tests — 系统不变量验证               ║${NC}"
echo -e "${BOLD}${CYAN}║     Inspired by OpenMythos ρ(A)<1 property tests ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# INV-1: Shared engines present in every DSL template
# Analogy: OpenMythos test_shared_experts_always_fire
# Invariant: escalation + Polanyi must appear in DSL SKILL output templates
# =============================================================================
DSL_FILE="$AGENT_DIR/skills/agent-dsl/SKILL.md"
if [ -f "$DSL_FILE" ]; then
    HAS_ESCALATION=$(grep -c "escalation" "$DSL_FILE" 2>/dev/null || echo "0")
    HAS_POLANYI=$(grep -c "Polanyi\|POLANYI\|polanyi" "$DSL_FILE" 2>/dev/null || echo "0")
    if [ "$HAS_ESCALATION" -ge 3 ] && [ "$HAS_POLANYI" -ge 3 ]; then
        assert_invariant "INV-1: 共享引擎（escalation + Polanyi）在 DSL 中始终存在" 0
    else
        assert_invariant "INV-1: 共享引擎（escalation + Polanyi）在 DSL 中始终存在" 1
    fi
else
    assert_invariant "INV-1: 共享引擎（escalation + Polanyi）在 DSL 中始终存在 [文件缺失]" 1
fi

# =============================================================================
# INV-2: Guard enforcer hook exists and is executable
# Analogy: OpenMythos LTI ρ(A)<1 — stability by construction
# Invariant: Constructive safety hook must exist
# =============================================================================
GUARD_HOOK="$AGENT_DIR/hooks/post-tool/guard-enforcer.sh"
if [ -f "$GUARD_HOOK" ] && [ -x "$GUARD_HOOK" ]; then
    assert_invariant "INV-2: 构造性安全钩子存在且可执行 (guard-enforcer.sh)" 0
else
    assert_invariant "INV-2: 构造性安全钩子存在且可执行 (guard-enforcer.sh)" 1
fi

# =============================================================================
# INV-3: Memory palace directory structure is intact
# Analogy: OpenMythos LoRA adapter — persistent state across loops
# Invariant: memory-palace dir must exist with expected files
# =============================================================================
MEMORY_DIR="$AGENT_DIR/state/memory-palace"
if [ -d "$MEMORY_DIR" ]; then
    assert_invariant "INV-3: memory-palace 目录存在" 0
else
    assert_invariant "INV-3: memory-palace 目录存在" 1
fi

# =============================================================================
# INV-4: Escalation levels are monotonically defined (L1 < L2 < L3 < L4 < L5)
# Analogy: OpenMythos test_spectral_radius_lt_1
# Invariant: Escalation thresholds must be strictly increasing
# =============================================================================
ESC_FILE="$AGENT_DIR/skills/escalation/SKILL.md"
if [ -f "$ESC_FILE" ]; then
    # Extract threshold numbers from the escalation table
    L1=$(grep -E "^\|.*2.*\|.*L1" "$ESC_FILE" | grep -oE "^[^|]*\|[^|]*" | grep -oE "[0-9]+" | head -1 || echo "0")
    L2=$(grep -E "^\|.*3.*\|.*L2" "$ESC_FILE" | grep -oE "^[^|]*\|[^|]*" | grep -oE "[0-9]+" | head -1 || echo "0")
    L3=$(grep -E "^\|.*4.*\|.*L3" "$ESC_FILE" | grep -oE "^[^|]*\|[^|]*" | grep -oE "[0-9]+" | head -1 || echo "0")
    L4=$(grep -E "^\|.*5.*\|.*L4" "$ESC_FILE" | grep -oE "^[^|]*\|[^|]*" | grep -oE "[0-9]+" | head -1 || echo "0")
    
    # Verify monotonic: L1_thresh < L2_thresh < L3_thresh < L4_thresh
    if [ "${L1:-0}" -lt "${L2:-0}" ] && [ "${L2:-0}" -lt "${L3:-0}" ] && [ "${L3:-0}" -lt "${L4:-0}" ]; then
        assert_invariant "INV-4: Escalation 阈值严格单调递增 (L1=$L1 < L2=$L2 < L3=$L3 < L4=$L4)" 0
    else
        assert_invariant "INV-4: Escalation 阈值严格单调递增 (L1=$L1, L2=$L2, L3=$L3, L4=$L4)" 1
    fi
else
    assert_invariant "INV-4: Escalation 阈值严格单调递增 [文件缺失]" 1
fi

# =============================================================================
# INV-5: All post-tool hooks exit cleanly (no syntax errors)
# Analogy: OpenMythos test_forward_no_nan — basic sanity
# Invariant: Every hook script must pass bash -n syntax check
# =============================================================================
HOOK_DIR="$AGENT_DIR/hooks/post-tool"
HOOK_SYNTAX_OK=0
HOOK_SYNTAX_FAIL=0
if [ -d "$HOOK_DIR" ]; then
    for hook in "$HOOK_DIR"/*.sh; do
        if [ -f "$hook" ]; then
            if bash -n "$hook" 2>/dev/null; then
                HOOK_SYNTAX_OK=$((HOOK_SYNTAX_OK + 1))
            else
                HOOK_SYNTAX_FAIL=$((HOOK_SYNTAX_FAIL + 1))
                echo -e "    ${RED}语法错误: $(basename "$hook")${NC}"
            fi
        fi
    done
    if [ "$HOOK_SYNTAX_FAIL" -eq 0 ]; then
        assert_invariant "INV-5: 所有 post-tool 钩子语法正确 (${HOOK_SYNTAX_OK} 个)" 0
    else
        assert_invariant "INV-5: 所有 post-tool 钩子语法正确 (${HOOK_SYNTAX_FAIL} 个失败)" 1
    fi
else
    assert_invariant "INV-5: 所有 post-tool 钩子语法正确 [目录缺失]" 1
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo -e "${BOLD}━━━ 总结 ━━━${NC}"
echo -e "  通过: ${GREEN}${PASS}${NC}  失败: ${RED}${FAIL}${NC}  总计: ${TOTAL}"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "  ${RED}${BOLD}❌ 存在不变量违反${NC}"
    exit 1
else
    echo -e "  ${GREEN}${BOLD}✅ 所有不变量成立${NC}"
    exit 0
fi
