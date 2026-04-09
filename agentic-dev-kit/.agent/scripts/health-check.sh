#!/bin/bash
# =============================================================================
# Context Health Check — 自动化指令文件膨胀检测
# 用法: bash .agent/scripts/health-check.sh [项目根目录]
# 退出码: 0=健康, 1=警告, 2=危险
# =============================================================================

set -uo pipefail

# --- 配置 ---
PROJECT_ROOT="${1:-.}"
AGENT_DIR="${PROJECT_ROOT}/.agent"
AGENT_MD="${PROJECT_ROOT}/AGENT.md"

# 阈值
THRESH_TOTAL_LINES_WARN=800
THRESH_TOTAL_LINES_CRIT=1200
THRESH_FILE_LINES_WARN=300
THRESH_FILE_LINES_CRIT=500
THRESH_RULE_FILES_WARN=6
THRESH_RULE_FILES_CRIT=9
THRESH_SKILLS_WARN=11
THRESH_SKILLS_CRIT=21
THRESH_TOKENS_WARN=8000
THRESH_TOKENS_CRIT=15000

# --- 颜色 ---
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- 状态追踪（使用独立临时文件在子 shell 间共享）---
TMPDIR_HC=$(mktemp -d)
echo "0" > "$TMPDIR_HC/exit_code"
echo "0" > "$TMPDIR_HC/warnings"
echo "0" > "$TMPDIR_HC/criticals"
trap "rm -rf $TMPDIR_HC" EXIT

update_state() {
    local level=$1
    if [ "$level" = "crit" ]; then
        local c=$(cat "$TMPDIR_HC/criticals")
        echo $((c + 1)) > "$TMPDIR_HC/criticals"
        echo "2" > "$TMPDIR_HC/exit_code"
    elif [ "$level" = "warn" ]; then
        local w=$(cat "$TMPDIR_HC/warnings")
        echo $((w + 1)) > "$TMPDIR_HC/warnings"
        local ec=$(cat "$TMPDIR_HC/exit_code")
        [ "$ec" -lt 1 ] && echo "1" > "$TMPDIR_HC/exit_code"
    fi
}

rate() {
    local value=$1 warn=$2 crit=$3
    if [ "$value" -ge "$crit" ]; then
        echo -e "${RED}🔴 危险${NC}"
        update_state "crit"
    elif [ "$value" -ge "$warn" ]; then
        echo -e "${YELLOW}🟡 警告${NC}"
        update_state "warn"
    else
        echo -e "${GREEN}🟢 健康${NC}"
    fi
}

# =============================================================================
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║       Context Health Check — 指令文件健康报告       ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}项目路径:${NC} $(cd "$PROJECT_ROOT" && pwd)"
echo -e "${CYAN}检查时间:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# --- 检查 .agent 目录是否存在 ---
if [ ! -d "$AGENT_DIR" ]; then
    echo -e "${RED}错误: 未找到 .agent 目录。请在项目根目录运行此脚本。${NC}"
    exit 2
fi

# =============================================================================
# 1. 核心指令文件统计（AGENT.md + SKILL.md + rules + workflows）
# =============================================================================
echo -e "${BOLD}━━━ 1. 核心指令文件统计 ━━━${NC}"
echo ""

# 收集所有 .md 指令文件（排除 reference 子目录中的参考文档）
CORE_FILES=()
[ -f "$AGENT_MD" ] && CORE_FILES+=("$AGENT_MD")

while IFS= read -r f; do
    CORE_FILES+=("$f")
done < <(find "$AGENT_DIR/skills" -name "SKILL.md" -not -path "*/reference/*" 2>/dev/null)

while IFS= read -r f; do
    CORE_FILES+=("$f")
done < <(find "$AGENT_DIR/rules" -name "*.md" 2>/dev/null)

while IFS= read -r f; do
    CORE_FILES+=("$f")
done < <(find "$AGENT_DIR/workflows" -name "*.md" 2>/dev/null)

TOTAL_LINES=0
TOTAL_BYTES=0
FILE_DETAILS=()

for f in "${CORE_FILES[@]}"; do
    lines=$(wc -l < "$f" | tr -d ' ')
    bytes=$(wc -c < "$f" | tr -d ' ')
    TOTAL_LINES=$((TOTAL_LINES + lines))
    TOTAL_BYTES=$((TOTAL_BYTES + bytes))
    rel_path="${f#$PROJECT_ROOT/}"
    FILE_DETAILS+=("${lines}|${bytes}|${rel_path}")
done

EST_TOKENS=$((TOTAL_BYTES / 4))

STATUS=$(rate $TOTAL_LINES $THRESH_TOTAL_LINES_WARN $THRESH_TOTAL_LINES_CRIT)
printf "  %-35s %6d 行   %s\n" "指令文件总行数" "$TOTAL_LINES" "$STATUS"
STATUS=$(rate $EST_TOKENS $THRESH_TOKENS_WARN $THRESH_TOKENS_CRIT)
printf "  %-35s %6d      %s\n" "估算总 Token" "$EST_TOKENS" "$STATUS"
echo ""

# =============================================================================
# 2. 组件数量统计
# =============================================================================
echo -e "${BOLD}━━━ 2. 组件数量 ━━━${NC}"
echo ""

SKILL_COUNT=$(find "$AGENT_DIR/skills" -maxdepth 1 -type d 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
WORKFLOW_COUNT=$(find "$AGENT_DIR/workflows" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
RULE_COUNT=$(find "$AGENT_DIR/rules" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

STATUS=$(rate $SKILL_COUNT $THRESH_SKILLS_WARN $THRESH_SKILLS_CRIT)
printf "  %-35s %6d 个   %s\n" "Skills 数量" "$SKILL_COUNT" "$STATUS"
STATUS=$(rate $WORKFLOW_COUNT 15 25)
printf "  %-35s %6d 个   %s\n" "Workflows 数量" "$WORKFLOW_COUNT" "$STATUS"
STATUS=$(rate $RULE_COUNT $THRESH_RULE_FILES_WARN $THRESH_RULE_FILES_CRIT)
printf "  %-35s %6d 个   %s\n" "Rules 文件数量" "$RULE_COUNT" "$STATUS"
echo ""

# =============================================================================
# 3. 单文件行数 TOP 5
# =============================================================================
echo -e "${BOLD}━━━ 3. 单文件行数 TOP 5 ━━━${NC}"
echo ""

IFS=$'\n' SORTED=($(for item in "${FILE_DETAILS[@]}"; do echo "$item"; done | sort -t'|' -k1 -nr | head -5))

for item in "${SORTED[@]}"; do
    IFS='|' read -r lines bytes path <<< "$item"
    STATUS=$(rate "$lines" $THRESH_FILE_LINES_WARN $THRESH_FILE_LINES_CRIT)
    printf "  %6d 行  %-45s %s\n" "$lines" "$path" "$STATUS"
done
echo ""

# =============================================================================
# 4. 规则密度检测
# =============================================================================
echo -e "${BOLD}━━━ 4. 规则密度 ━━━${NC}"
echo ""

if [ -f "$AGENT_MD" ]; then
    HARD_RULES=$(grep -cE '^\s*[0-9]+\.\s' "$AGENT_MD" 2>/dev/null || true)
    HARD_RULES=${HARD_RULES:-0}
    AGENT_LINES=$(wc -l < "$AGENT_MD" | tr -d ' ')
    STATUS=$(rate $HARD_RULES 8 15)
    printf "  %-35s %6d 条   %s\n" "AGENT.md 编号规则数" "$HARD_RULES" "$STATUS"
    STATUS=$(rate $AGENT_LINES 80 120)
    printf "  %-35s %6d 行   %s\n" "AGENT.md 总行数" "$AGENT_LINES" "$STATUS"
fi

TOTAL_RULE_ITEMS=0
while IFS= read -r f; do
    items=$(grep -cE '^\s*-\s*\[' "$f" 2>/dev/null || true)
    items=${items:-0}
    TOTAL_RULE_ITEMS=$((TOTAL_RULE_ITEMS + items))
done < <(find "$AGENT_DIR/rules" -name "*.md" 2>/dev/null)
STATUS=$(rate $TOTAL_RULE_ITEMS 30 50)
printf "  %-35s %6d 条   %s\n" "Rules 文件中检查项总数" "$TOTAL_RULE_ITEMS" "$STATUS"
echo ""

# =============================================================================
# 5. 潜在问题检测
# =============================================================================
echo -e "${BOLD}━━━ 5. 潜在问题 ━━━${NC}"
echo ""

ISSUES=0

REF_FILES=$(find "$AGENT_DIR/skills" -path "*/reference/*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$REF_FILES" -gt 10 ]; then
    echo -e "  ${YELLOW}⚠ 发现 ${REF_FILES} 个 reference 文件，确认不会被自动加载${NC}"
    ISSUES=$((ISSUES + 1))
fi

while IFS= read -r f; do
    lines=$(wc -l < "$f" | tr -d ' ')
    if [ "$lines" -gt 500 ]; then
        rel="${f#$PROJECT_ROOT/}"
        echo -e "  ${RED}🔴 巨型 Skill: ${rel} (${lines} 行) — 建议拆分${NC}"
        ISSUES=$((ISSUES + 1))
    fi
done < <(find "$AGENT_DIR/skills" -name "SKILL.md" 2>/dev/null)

if [ ! -f "$AGENT_MD" ]; then
    echo -e "  ${RED}🔴 缺少 AGENT.md 路由文件${NC}"
    ISSUES=$((ISSUES + 1))
fi

if [ "$ISSUES" -eq 0 ]; then
    echo -e "  ${GREEN}✅ 未发现潜在问题${NC}"
fi
echo ""

# =============================================================================
# 6. 规范链接完整性（MD Linker）
# =============================================================================
echo -e "${BOLD}━━━ 6. 规范链接完整性 ━━━${NC}"
echo ""

LINKER_SCRIPT="$AGENT_DIR/scripts/md-linker.sh"
if [ -x "$LINKER_SCRIPT" ] || [ -f "$LINKER_SCRIPT" ]; then
    # Run md-linker in full mode, capture CRITICAL count from exit code
    LINKER_OUTPUT=$(bash "$LINKER_SCRIPT" "$PROJECT_ROOT" 2>&1) || true
    LINKER_CRITICALS=$?
    
    # Extract key metrics from output
    LINKER_REFS=$(echo "$LINKER_OUTPUT" | grep -o '扫描到 [0-9]* 条' | grep -o '[0-9]*' || echo "0")
    LINKER_VALID=$(echo "$LINKER_OUTPUT" | grep -o '有效引用: [0-9]*' | grep -o '[0-9]*' || echo "0")
    LINKER_ORPHANS=$(echo "$LINKER_OUTPUT" | grep -o '孤儿文件: [0-9]*' | grep -o '[0-9]*' || echo "0")
    
    printf "  %-35s %6s 条   " "跨文件引用总数" "$LINKER_REFS"
    echo -e "${GREEN}🟢 已扫描${NC}"
    
    if [ "$LINKER_CRITICALS" -eq 0 ]; then
        printf "  %-35s %6s 条   " "有效引用" "$LINKER_VALID"
        echo -e "${GREEN}🟢 全部有效${NC}"
    else
        printf "  %-35s %6d 条   " "断链引用 (CRITICAL)" "$LINKER_CRITICALS"
        echo -e "${RED}🔴 危险${NC}"
        update_state "crit"
        echo ""
        echo -e "  ${RED}运行 bash .agent/scripts/md-linker.sh . 查看详情${NC}"
    fi
    
    if [ "$LINKER_ORPHANS" -gt 30 ]; then
        printf "  %-35s %6s 个   " "孤儿文件" "$LINKER_ORPHANS"
        echo -e "${YELLOW}🟡 警告${NC}"
        update_state "warn"
    fi
else
    echo -e "  ${YELLOW}⚠ md-linker.sh 不存在，跳过链接校验${NC}"
fi
echo ""

# =============================================================================
# 总结
# =============================================================================
echo -e "${BOLD}━━━ 总结 ━━━${NC}"
echo ""

read -r EXIT_CODE < "$TMPDIR_HC/exit_code"
read -r WARNINGS < "$TMPDIR_HC/warnings"
read -r CRITICALS < "$TMPDIR_HC/criticals"

if [ "$EXIT_CODE" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}✅ 整体健康${NC} — 指令文件规模在合理范围内"
elif [ "$EXIT_CODE" -eq 1 ]; then
    echo -e "  ${YELLOW}${BOLD}⚠ 需要关注${NC} — ${WARNINGS} 项警告, 建议在下次 /evolve 时优化"
else
    echo -e "  ${RED}${BOLD}🚨 需要立即处理${NC} — ${CRITICALS} 项危险, ${WARNINGS} 项警告"
    echo -e "  ${RED}建议立即执行 /evolve 进行规则清理和技能精简${NC}"
fi
echo ""

exit $EXIT_CODE
