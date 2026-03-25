#!/usr/bin/env bash
# ============================================================================
# validate-structure.sh — 框架结构完整性验证器
# 检查 AGENT.md 格式、Skill 完整性、路由一致性、文件结构
# 用法: bash .agent/scripts/validate-structure.sh [项目根目录]
# 退出码: 0=通过, 1=有错误
# ============================================================================

set -uo pipefail

PROJECT_ROOT="${1:-.}"
AGENT_DIR="${PROJECT_ROOT}/.agent"
AGENT_MD="${PROJECT_ROOT}/AGENT.md"

# ─── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ERRORS=0
WARNINGS=0
CHECKS_PASSED=0
CHECKS_TOTAL=0

pass() {
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    echo -e "  ${GREEN}✅${NC} $1"
}

fail() {
    ERRORS=$((ERRORS + 1))
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    echo -e "  ${RED}❌${NC} $1"
}

warn() {
    WARNINGS=$((WARNINGS + 1))
    echo -e "  ${YELLOW}⚠️${NC}  $1"
}

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║    Framework Structure Validator — 框架结构验证器    ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}项目路径:${NC} $(cd "$PROJECT_ROOT" && pwd)"
echo ""

# =============================================================================
# Check 1: Core files exist
# =============================================================================
echo -e "${BOLD}━━━ 1. 核心文件存在性 ━━━${NC}"

if [ -f "$AGENT_MD" ]; then
    pass "AGENT.md 存在"
else
    fail "AGENT.md 缺失 — 框架无法工作"
fi

if [ -d "$AGENT_DIR" ]; then
    pass ".agent/ 目录存在"
else
    fail ".agent/ 目录缺失"
fi

for subdir in skills workflows rules scripts; do
    if [ -d "$AGENT_DIR/$subdir" ]; then
        pass ".agent/$subdir/ 存在"
    else
        fail ".agent/$subdir/ 缺失"
    fi
done
echo ""

# =============================================================================
# Check 2: AGENT.md required sections
# =============================================================================
echo -e "${BOLD}━━━ 2. AGENT.md 必需 Section ━━━${NC}"

if [ -f "$AGENT_MD" ]; then
    REQUIRED_SECTIONS=(
        "技能路由|Skill Routing"
        "工作流路由|Workflow Routing"
        "规则路由|Rules Routing"
        "强制规则|Hard Rules"
    )
    SECTION_NAMES=(
        "技能路由 (Skill Routing)"
        "工作流路由 (Workflow Routing)"
        "规则路由 (Rules Routing)"
        "强制规则 (Hard Rules)"
    )

    for i in "${!REQUIRED_SECTIONS[@]}"; do
        if grep -q -E "${REQUIRED_SECTIONS[$i]}" "$AGENT_MD"; then
            pass "${SECTION_NAMES[$i]} section 存在"
        else
            fail "${SECTION_NAMES[$i]} section 缺失"
        fi
    done
fi
echo ""

# =============================================================================
# Check 3: Skill YAML frontmatter
# =============================================================================
echo -e "${BOLD}━━━ 3. Skill 文件规范 ━━━${NC}"

SKILL_FILES=()
while IFS= read -r f; do
    SKILL_FILES+=("$f")
done < <(find "$AGENT_DIR/skills" -name "SKILL.md" 2>/dev/null)

SKILL_COUNT=${#SKILL_FILES[@]}
if [ "$SKILL_COUNT" -eq 0 ]; then
    fail "未找到任何 SKILL.md 文件"
else
    pass "找到 $SKILL_COUNT 个 SKILL.md 文件"

    FM_PASS=0
    FM_FAIL=0
    FM_FAIL_FILES=""
    for f in "${SKILL_FILES[@]}"; do
        # Check for YAML frontmatter (starts with ---)
        if head -1 "$f" | grep -q "^---"; then
            # Check for description field in frontmatter
            # Read until second ---
            FM_CONTENT=$(sed -n '2,/^---$/p' "$f" | sed '$d')
            if echo "$FM_CONTENT" | grep -q -E "^(description|name):"; then
                FM_PASS=$((FM_PASS + 1))
            else
                FM_FAIL=$((FM_FAIL + 1))
                rel="${f#$PROJECT_ROOT/}"
                FM_FAIL_FILES="${FM_FAIL_FILES}\n      - ${rel}"
            fi
        else
            FM_FAIL=$((FM_FAIL + 1))
            rel="${f#$PROJECT_ROOT/}"
            FM_FAIL_FILES="${FM_FAIL_FILES}\n      - ${rel}"
        fi
    done

    if [ "$FM_FAIL" -eq 0 ]; then
        pass "所有 SKILL.md 有合法 YAML frontmatter ($FM_PASS/$SKILL_COUNT)"
    else
        fail "$FM_FAIL 个 SKILL.md 缺少 YAML frontmatter:${FM_FAIL_FILES}"
    fi
fi
echo ""

# =============================================================================
# Check 4: Workflow frontmatter
# =============================================================================
echo -e "${BOLD}━━━ 4. Workflow 文件规范 ━━━${NC}"

WF_FILES=()
while IFS= read -r f; do
    WF_FILES+=("$f")
done < <(find "$AGENT_DIR/workflows" -name "*.md" 2>/dev/null)

WF_COUNT=${#WF_FILES[@]}
if [ "$WF_COUNT" -eq 0 ]; then
    fail "未找到任何 workflow 文件"
else
    pass "找到 $WF_COUNT 个 workflow 文件"

    WF_PASS=0
    WF_FAIL=0
    WF_FAIL_FILES=""
    for f in "${WF_FILES[@]}"; do
        if head -1 "$f" | grep -q "^---"; then
            FM_CONTENT=$(sed -n '2,/^---$/p' "$f" | sed '$d')
            if echo "$FM_CONTENT" | grep -q -E "^description:"; then
                WF_PASS=$((WF_PASS + 1))
            else
                WF_FAIL=$((WF_FAIL + 1))
                rel="${f#$PROJECT_ROOT/}"
                WF_FAIL_FILES="${WF_FAIL_FILES}\n      - ${rel}"
            fi
        else
            WF_FAIL=$((WF_FAIL + 1))
            rel="${f#$PROJECT_ROOT/}"
            WF_FAIL_FILES="${WF_FAIL_FILES}\n      - ${rel}"
        fi
    done

    if [ "$WF_FAIL" -eq 0 ]; then
        pass "所有 workflow 有 description frontmatter ($WF_PASS/$WF_COUNT)"
    else
        fail "$WF_FAIL 个 workflow 缺少 description frontmatter:${WF_FAIL_FILES}"
    fi
fi
echo ""

# =============================================================================
# Check 5: Route consistency — referenced files exist
# =============================================================================
echo -e "${BOLD}━━━ 5. 路由引用一致性 ━━━${NC}"

if [ -f "$AGENT_MD" ]; then
    # Extract file paths referenced in AGENT.md (`.agent/...` patterns)
    # First, strip multi-line HTML comments from the content
    # Then exclude template/glob patterns: {}, *
    AGENT_CONTENT_NO_COMMENTS=$(sed '/<!--/,/-->/d' "$AGENT_MD")
    REFERENCED_FILES=()
    while IFS= read -r ref; do
        # Skip glob/template patterns
        case "$ref" in
            *"{"*|*"*"*|*"$"*) continue ;;
        esac
        REFERENCED_FILES+=("$ref")
    done < <(echo "$AGENT_CONTENT_NO_COMMENTS" | grep -oE '`\.agent/[^`]+`' | sed 's/`//g' | sort -u)

    REF_PASS=0
    REF_FAIL=0
    REF_FAIL_FILES=""
    for ref in "${REFERENCED_FILES[@]}"; do
        target_path="$PROJECT_ROOT/$ref"
        if [ -f "$target_path" ] || [ -d "$target_path" ]; then
            REF_PASS=$((REF_PASS + 1))
        else
            REF_FAIL=$((REF_FAIL + 1))
            REF_FAIL_FILES="${REF_FAIL_FILES}\n      - ${ref}"
        fi
    done

    TOTAL_REFS=${#REFERENCED_FILES[@]}
    if [ "$REF_FAIL" -eq 0 ]; then
        pass "所有路由引用指向真实文件 ($REF_PASS/$TOTAL_REFS)"
    else
        fail "$REF_FAIL 个路由引用指向不存在的文件:${REF_FAIL_FILES}"
    fi
fi
echo ""

# =============================================================================
# Check 6: Agent definitions
# =============================================================================
echo -e "${BOLD}━━━ 6. Agent 定义文件 ━━━${NC}"

if [ -d "$AGENT_DIR/agents" ]; then
    AGENT_FILES=()
    while IFS= read -r f; do
        AGENT_FILES+=("$f")
    done < <(find "$AGENT_DIR/agents" -name "*.md" 2>/dev/null)

    AGENT_COUNT=${#AGENT_FILES[@]}
    if [ "$AGENT_COUNT" -gt 0 ]; then
        pass "找到 $AGENT_COUNT 个 Agent 定义文件"
    else
        warn "agents/ 目录为空"
    fi
else
    warn "agents/ 目录不存在"
fi
echo ""

# =============================================================================
# Check 7: Scripts executable
# =============================================================================
echo -e "${BOLD}━━━ 7. 脚本可执行性 ━━━${NC}"

SCRIPT_FILES=()
while IFS= read -r f; do
    SCRIPT_FILES+=("$f")
done < <(find "$AGENT_DIR/scripts" -name "*.sh" 2>/dev/null)

SCRIPT_COUNT=${#SCRIPT_FILES[@]}
if [ "$SCRIPT_COUNT" -gt 0 ]; then
    SYNTAX_PASS=0
    SYNTAX_FAIL=0
    for f in "${SCRIPT_FILES[@]}"; do
        if bash -n "$f" 2>/dev/null; then
            SYNTAX_PASS=$((SYNTAX_PASS + 1))
        else
            SYNTAX_FAIL=$((SYNTAX_FAIL + 1))
            rel="${f#$PROJECT_ROOT/}"
            fail "语法错误: $rel"
        fi
    done
    if [ "$SYNTAX_FAIL" -eq 0 ]; then
        pass "所有脚本通过 bash -n 语法检查 ($SYNTAX_PASS/$SCRIPT_COUNT)"
    fi
else
    warn "未找到 .sh 脚本文件"
fi
echo ""

# =============================================================================
# Summary
# =============================================================================
echo -e "${BOLD}━━━ 总结 ━━━${NC}"
echo ""

if [ "$ERRORS" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}✅ 验证通过${NC} — $CHECKS_PASSED/$CHECKS_TOTAL 项检查全部通过"
    if [ "$WARNINGS" -gt 0 ]; then
        echo -e "  ${YELLOW}⚠️  $WARNINGS 条警告（非阻塞）${NC}"
    fi
    echo ""
    exit 0
else
    echo -e "  ${RED}${BOLD}❌ 验证失败${NC} — $ERRORS 项错误, $CHECKS_PASSED/$CHECKS_TOTAL 项通过"
    if [ "$WARNINGS" -gt 0 ]; then
        echo -e "  ${YELLOW}⚠️  $WARNINGS 条警告${NC}"
    fi
    echo ""
    exit 1
fi
