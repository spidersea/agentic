#!/usr/bin/env bash
# ============================================================================
# stress-test-engine.sh — 可复现的量化评分引擎
# 5 维度评分，满分 100，输出评级 A-F
# 用法: bash .agent/scripts/stress-test-engine.sh [项目根目录]
# 退出码: 0=A/B, 1=C/D, 2=F
# ============================================================================

set -uo pipefail

PROJECT_ROOT="${1:-.}"
AGENT_DIR="${PROJECT_ROOT}/.agent"
SCRIPTS="$AGENT_DIR/scripts"

# ─── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

TOTAL_SCORE=0

add_score() {
    local points=$1
    local max=$2
    local name=$3
    local detail=$4
    local pct=0
    if [ "$max" -gt 0 ]; then
        pct=$(( (points * 100) / max ))
    fi

    local color=$GREEN
    if [ "$pct" -lt 60 ]; then
        color=$RED
    elif [ "$pct" -lt 80 ]; then
        color=$YELLOW
    fi

    printf "  %-35s ${color}%3d / %3d${NC} (%d%%)\n" "$name" "$points" "$max" "$pct"
    if [ -n "$detail" ]; then
        echo "    └─ $detail"
    fi
    TOTAL_SCORE=$((TOTAL_SCORE + points))
}

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║     Stress Test Engine — 框架量化评分引擎 v1.0      ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}项目路径:${NC} $(cd "$PROJECT_ROOT" && pwd)"
echo -e "${CYAN}评分时间:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# =============================================================================
# Dimension 1: 结构完整性 (30 points)
# =============================================================================
echo -e "${BOLD}━━━ D1: 结构完整性 (30 分) ━━━${NC}"
echo ""

D1_SCORE=0

# Core files exist (10 points)
CORE_EXISTS=0
[ -f "$PROJECT_ROOT/AGENT.md" ] && CORE_EXISTS=$((CORE_EXISTS + 2))
[ -d "$AGENT_DIR/skills" ] && CORE_EXISTS=$((CORE_EXISTS + 2))
[ -d "$AGENT_DIR/workflows" ] && CORE_EXISTS=$((CORE_EXISTS + 2))
[ -d "$AGENT_DIR/rules" ] && CORE_EXISTS=$((CORE_EXISTS + 2))
[ -d "$AGENT_DIR/scripts" ] && CORE_EXISTS=$((CORE_EXISTS + 2))
add_score $CORE_EXISTS 10 "核心文件存在" "${CORE_EXISTS}/10"
D1_SCORE=$((D1_SCORE + CORE_EXISTS))

# AGENT.md required sections (10 points)
SECTIONS_FOUND=0
if [ -f "$PROJECT_ROOT/AGENT.md" ]; then
    grep -q -E "技能路由|Skill Routing" "$PROJECT_ROOT/AGENT.md" 2>/dev/null && SECTIONS_FOUND=$((SECTIONS_FOUND + 2))
    grep -q -E "工作流路由|Workflow Routing" "$PROJECT_ROOT/AGENT.md" 2>/dev/null && SECTIONS_FOUND=$((SECTIONS_FOUND + 2))
    grep -q -E "规则路由|Rules Routing" "$PROJECT_ROOT/AGENT.md" 2>/dev/null && SECTIONS_FOUND=$((SECTIONS_FOUND + 2))
    grep -q -E "强制规则|Hard Rules" "$PROJECT_ROOT/AGENT.md" 2>/dev/null && SECTIONS_FOUND=$((SECTIONS_FOUND + 2))
    grep -q -E "Agent.*委派|Agent Delegation" "$PROJECT_ROOT/AGENT.md" 2>/dev/null && SECTIONS_FOUND=$((SECTIONS_FOUND + 2))
fi
SECTIONS_SCORE=$((SECTIONS_FOUND > 10 ? 10 : SECTIONS_FOUND))
add_score $SECTIONS_SCORE 10 "AGENT.md 必需 Section" "${SECTIONS_FOUND}/10"
D1_SCORE=$((D1_SCORE + SECTIONS_SCORE))

# Route consistency — no dangling references (10 points)
if [ -f "$PROJECT_ROOT/AGENT.md" ]; then
    TOTAL_REFS=$(grep -oE '`\.agent/[^`]+`' "$PROJECT_ROOT/AGENT.md" | sed 's/`//g' | sort -u | wc -l | tr -d ' ')
    VALID_REFS=0
    while IFS= read -r ref; do
        [ -f "$PROJECT_ROOT/$ref" ] || [ -d "$PROJECT_ROOT/$ref" ] && VALID_REFS=$((VALID_REFS + 1))
    done < <(grep -oE '`\.agent/[^`]+`' "$PROJECT_ROOT/AGENT.md" | sed 's/`//g' | sort -u)

    if [ "$TOTAL_REFS" -gt 0 ]; then
        ROUTE_SCORE=$(( (VALID_REFS * 10) / TOTAL_REFS ))
    else
        ROUTE_SCORE=10
    fi
    add_score $ROUTE_SCORE 10 "路由引用一致性" "${VALID_REFS}/${TOTAL_REFS} 引用有效"
    D1_SCORE=$((D1_SCORE + ROUTE_SCORE))
fi
echo ""

# =============================================================================
# Dimension 2: 健康检查 (20 points)
# =============================================================================
echo -e "${BOLD}━━━ D2: 健康检查 (20 分) ━━━${NC}"
echo ""

D2_SCORE=0
if [ -f "$SCRIPTS/health-check.sh" ]; then
    # Run health-check and capture exit code
    HC_OUTPUT=$(bash "$SCRIPTS/health-check.sh" "$PROJECT_ROOT" 2>&1)
    HC_EXIT=$?

    case $HC_EXIT in
        0) D2_SCORE=20; HC_DETAIL="退出码 0 (健康)" ;;
        1) D2_SCORE=12; HC_DETAIL="退出码 1 (有警告)" ;;
        2) D2_SCORE=5;  HC_DETAIL="退出码 2 (危险)" ;;
        *) D2_SCORE=0;  HC_DETAIL="退出码 $HC_EXIT (异常)" ;;
    esac
    add_score $D2_SCORE 20 "health-check.sh 结果" "$HC_DETAIL"
else
    add_score 0 20 "health-check.sh 结果" "脚本不存在"
fi
echo ""

# =============================================================================
# Dimension 3: 脚本可执行性 (15 points)
# =============================================================================
echo -e "${BOLD}━━━ D3: 脚本可执行性 (15 分) ━━━${NC}"
echo ""

D3_SCORE=0
SCRIPT_FILES=()
while IFS= read -r f; do
    SCRIPT_FILES+=("$f")
done < <(find "$AGENT_DIR/scripts" -name "*.sh" 2>/dev/null)

# Also check bin/
if [ -d "$PROJECT_ROOT/bin" ]; then
    while IFS= read -r f; do
        SCRIPT_FILES+=("$f")
    done < <(find "$PROJECT_ROOT/bin" -type f 2>/dev/null)
fi

TOTAL_SCRIPTS=${#SCRIPT_FILES[@]}
SYNTAX_PASS=0
if [ "$TOTAL_SCRIPTS" -gt 0 ]; then
    for f in "${SCRIPT_FILES[@]}"; do
        bash -n "$f" 2>/dev/null && SYNTAX_PASS=$((SYNTAX_PASS + 1))
    done
    D3_SCORE=$(( (SYNTAX_PASS * 15) / TOTAL_SCRIPTS ))
fi
add_score $D3_SCORE 15 "bash -n 语法检查" "${SYNTAX_PASS}/${TOTAL_SCRIPTS} 脚本通过"
echo ""

# =============================================================================
# Dimension 4: 文档覆盖率 (20 points)
# =============================================================================
echo -e "${BOLD}━━━ D4: 文档覆盖率 (20 分) ━━━${NC}"
echo ""

D4_SCORE=0

# Skill frontmatter coverage (10 points)
SKILL_TOTAL=$(find "$AGENT_DIR/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
SKILL_FM=0
while IFS= read -r f; do
    if head -1 "$f" 2>/dev/null | grep -q "^---"; then
        FM_BODY=$(sed -n '2,/^---$/p' "$f" | sed '$d')
        echo "$FM_BODY" | grep -q -E "^(description|name):" && SKILL_FM=$((SKILL_FM + 1))
    fi
done < <(find "$AGENT_DIR/skills" -name "SKILL.md" 2>/dev/null)

if [ "$SKILL_TOTAL" -gt 0 ]; then
    SKILL_FM_SCORE=$(( (SKILL_FM * 10) / SKILL_TOTAL ))
else
    SKILL_FM_SCORE=0
fi
add_score $SKILL_FM_SCORE 10 "Skill frontmatter 覆盖" "${SKILL_FM}/${SKILL_TOTAL}"
D4_SCORE=$((D4_SCORE + SKILL_FM_SCORE))

# Workflow frontmatter coverage (10 points)
WF_TOTAL=$(find "$AGENT_DIR/workflows" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
WF_FM=0
while IFS= read -r f; do
    if head -1 "$f" 2>/dev/null | grep -q "^---"; then
        FM_BODY=$(sed -n '2,/^---$/p' "$f" | sed '$d')
        echo "$FM_BODY" | grep -q -E "^description:" && WF_FM=$((WF_FM + 1))
    fi
done < <(find "$AGENT_DIR/workflows" -name "*.md" 2>/dev/null)

if [ "$WF_TOTAL" -gt 0 ]; then
    WF_FM_SCORE=$(( (WF_FM * 10) / WF_TOTAL ))
else
    WF_FM_SCORE=0
fi
add_score $WF_FM_SCORE 10 "Workflow frontmatter 覆盖" "${WF_FM}/${WF_TOTAL}"
D4_SCORE=$((D4_SCORE + WF_FM_SCORE))
echo ""

# =============================================================================
# Dimension 5: 工具链完整性 (15 points)
# =============================================================================
echo -e "${BOLD}━━━ D5: 工具链完整性 (15 分) ━━━${NC}"
echo ""

D5_SCORE=0

# Has CLI (2 points)
if [ -f "$PROJECT_ROOT/bin/agentic" ]; then
    add_score 2 2 "CLI 入口 (bin/agentic)" "存在"
    D5_SCORE=$((D5_SCORE + 2))
else
    add_score 0 2 "CLI 入口 (bin/agentic)" "缺失"
fi

# Has Makefile (2 points)
if [ -f "$PROJECT_ROOT/Makefile" ]; then
    add_score 2 2 "Makefile" "存在"
    D5_SCORE=$((D5_SCORE + 2))
else
    add_score 0 2 "Makefile" "缺失"
fi

# Has test directory (3 points)
if [ -d "$PROJECT_ROOT/tests" ] && [ "$(find "$PROJECT_ROOT/tests" -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')" -gt 0 ]; then
    TEST_COUNT=$(find "$PROJECT_ROOT/tests" -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
    add_score 3 3 "测试目录" "${TEST_COUNT} 个测试文件"
    D5_SCORE=$((D5_SCORE + 3))
else
    add_score 0 3 "测试目录" "缺失或空"
fi

# Has escalation tracker (2 points)
if [ -f "$SCRIPTS/escalation-tracker.sh" ]; then
    add_score 2 2 "Escalation 状态机" "存在"
    D5_SCORE=$((D5_SCORE + 2))
else
    add_score 0 2 "Escalation 状态机" "缺失"
fi

# Has validate-structure (2 points)
if [ -f "$SCRIPTS/validate-structure.sh" ]; then
    add_score 2 2 "结构验证器" "存在"
    D5_SCORE=$((D5_SCORE + 2))
else
    add_score 0 2 "结构验证器" "缺失"
fi

# Has instinct manager (2 points)
if [ -f "$SCRIPTS/instinct-manager.sh" ]; then
    add_score 2 2 "本能管理器" "存在"
    D5_SCORE=$((D5_SCORE + 2))
else
    add_score 0 2 "本能管理器" "缺失"
fi

# Has stress-test-engine (2 points — self-reference, but valid)
if [ -f "$SCRIPTS/stress-test-engine.sh" ]; then
    add_score 2 2 "评分引擎" "存在"
    D5_SCORE=$((D5_SCORE + 2))
else
    add_score 0 2 "评分引擎" "缺失"
fi
echo ""

# =============================================================================
# Dimension 6: 社区与生态 (10 points)
# =============================================================================
echo -e "${BOLD}━━━ D6: 社区与生态 (10 分) ━━━${NC}"
echo ""

D6_SCORE=0

# CONTRIBUTING.md (3 points)
if [ -f "$PROJECT_ROOT/CONTRIBUTING.md" ]; then
    add_score 3 3 "CONTRIBUTING.md" "存在"
    D6_SCORE=$((D6_SCORE + 3))
else
    add_score 0 3 "CONTRIBUTING.md" "缺失"
fi

# CHANGELOG.md (3 points)
if [ -f "$PROJECT_ROOT/CHANGELOG.md" ]; then
    add_score 3 3 "CHANGELOG.md" "存在"
    D6_SCORE=$((D6_SCORE + 3))
else
    add_score 0 3 "CHANGELOG.md" "缺失"
fi

# GitHub templates (2 points)
TEMPLATE_COUNT=0
[ -f "$PROJECT_ROOT/.github/ISSUE_TEMPLATE/bug_report.md" ] && TEMPLATE_COUNT=$((TEMPLATE_COUNT + 1))
[ -f "$PROJECT_ROOT/.github/ISSUE_TEMPLATE/feature_request.md" ] && TEMPLATE_COUNT=$((TEMPLATE_COUNT + 1))
[ -f "$PROJECT_ROOT/.github/pull_request_template.md" ] && TEMPLATE_COUNT=$((TEMPLATE_COUNT + 1))
if [ "$TEMPLATE_COUNT" -ge 2 ]; then
    add_score 2 2 "GitHub 模板" "${TEMPLATE_COUNT} 个模板"
    D6_SCORE=$((D6_SCORE + 2))
elif [ "$TEMPLATE_COUNT" -ge 1 ]; then
    add_score 1 2 "GitHub 模板" "${TEMPLATE_COUNT} 个模板"
    D6_SCORE=$((D6_SCORE + 1))
else
    add_score 0 2 "GitHub 模板" "缺失"
fi

# Platform adapter docs (2 points)
if [ -f "$PROJECT_ROOT/docs/platform-adapters.md" ]; then
    add_score 2 2 "平台适配文档" "存在"
    D6_SCORE=$((D6_SCORE + 2))
else
    add_score 0 2 "平台适配文档" "缺失"
fi
echo ""

# =============================================================================
# Dimension 7: 参考项目 (5 points)
# =============================================================================
echo -e "${BOLD}━━━ D7: 参考项目 (5 分) ━━━${NC}"
echo ""

D7_SCORE=0

# Has examples directory with content (3 points)
if [ -d "$PROJECT_ROOT/examples" ]; then
    EXAMPLE_FILES=$(find "$PROJECT_ROOT/examples" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$EXAMPLE_FILES" -ge 3 ]; then
        add_score 3 3 "参考项目" "${EXAMPLE_FILES} 个文件"
        D7_SCORE=$((D7_SCORE + 3))
    elif [ "$EXAMPLE_FILES" -ge 1 ]; then
        add_score 1 3 "参考项目" "${EXAMPLE_FILES} 个文件（偏少）"
        D7_SCORE=$((D7_SCORE + 1))
    else
        add_score 0 3 "参考项目" "目录为空"
    fi
else
    add_score 0 3 "参考项目" "缺失"
fi

# Has example README with walkthrough (2 points)
if find "$PROJECT_ROOT/examples" -name "README.md" -exec grep -q "Phase" {} \; 2>/dev/null; then
    add_score 2 2 "端到端演示文档" "存在"
    D7_SCORE=$((D7_SCORE + 2))
else
    add_score 0 2 "端到端演示文档" "缺失"
fi
echo ""

# =============================================================================
# Final Score (normalize to 100)
# =============================================================================
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Raw total out of 115, normalize to 100
RAW_MAX=115
NORMALIZED_SCORE=$(( (TOTAL_SCORE * 100) / RAW_MAX ))

# Calculate grade
if [ "$NORMALIZED_SCORE" -ge 90 ]; then
    GRADE="A"
    GRADE_COLOR=$GREEN
    EXIT_CODE=0
elif [ "$NORMALIZED_SCORE" -ge 80 ]; then
    GRADE="B"
    GRADE_COLOR=$GREEN
    EXIT_CODE=0
elif [ "$NORMALIZED_SCORE" -ge 70 ]; then
    GRADE="C"
    GRADE_COLOR=$YELLOW
    EXIT_CODE=1
elif [ "$NORMALIZED_SCORE" -ge 60 ]; then
    GRADE="D"
    GRADE_COLOR=$YELLOW
    EXIT_CODE=1
else
    GRADE="F"
    GRADE_COLOR=$RED
    EXIT_CODE=2
fi

echo -e "  ${BOLD}总分: ${GRADE_COLOR}${NORMALIZED_SCORE} / 100${NC} (原始 ${TOTAL_SCORE}/${RAW_MAX})  评级: ${GRADE_COLOR}${BOLD}${GRADE}${NC}"
echo ""

# Breakdown
echo -e "  ${BOLD}分维成绩:${NC}"
printf "    %-25s %d / 30\n" "D1 结构完整性" "$D1_SCORE"
printf "    %-25s %d / 20\n" "D2 健康检查" "$D2_SCORE"
printf "    %-25s %d / 15\n" "D3 脚本可执行性" "$D3_SCORE"
printf "    %-25s %d / 20\n" "D4 文档覆盖率" "$D4_SCORE"
printf "    %-25s %d / 15\n" "D5 工具链完整性" "$D5_SCORE"
printf "    %-25s %d / 10\n" "D6 社区与生态" "$D6_SCORE"
printf "    %-25s %d / 5\n" "D7 参考项目" "$D7_SCORE"
echo ""

# Recommendations
if [ "$NORMALIZED_SCORE" -lt 90 ]; then
    echo -e "  ${BOLD}改进建议:${NC}"
    [ "$D1_SCORE" -lt 25 ] && echo "    • D1: 修复路由引用或补全缺失文件"
    [ "$D2_SCORE" -lt 15 ] && echo "    • D2: 运行 /evolve 清理指令膨胀"
    [ "$D3_SCORE" -lt 12 ] && echo "    • D3: 修复脚本语法错误"
    [ "$D4_SCORE" -lt 15 ] && echo "    • D4: 给 Skill/Workflow 添加 YAML frontmatter"
    [ "$D5_SCORE" -lt 12 ] && echo "    • D5: 添加缺失的工具链组件"
    [ "$D6_SCORE" -lt 8 ] && echo "    • D6: 添加 CONTRIBUTING.md, CHANGELOG.md, GitHub 模板"
    [ "$D7_SCORE" -lt 4 ] && echo "    • D7: 创建参考项目和端到端演示"
    echo ""
fi

exit $EXIT_CODE

