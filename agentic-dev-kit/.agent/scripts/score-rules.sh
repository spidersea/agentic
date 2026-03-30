#!/usr/bin/env bash
# ============================================================================
# score-rules.sh — 自动量化评估规范围度 (逻辑性、落地性、自动化)
# 针对 .agent/rules/*.md 文件进行评估，提供机械化的 autoresearch Metric
# ============================================================================

set -uo pipefail

PROJECT_ROOT="${1:-.}"
RULES_DIR="${PROJECT_ROOT}/.agent/rules"

if [ ! -d "$RULES_DIR" ]; then
    echo "目录 $RULES_DIR 不存在"
    exit 1
fi

TOTAL_SCORE=0
FILE_COUNT=0

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}=== 规范量化评分引擎 (Autoresearch Metric) ===${NC}"

for file in "$RULES_DIR"/*.md; do
    if [ ! -f "$file" ]; then continue; fi
    base=$(basename "$file")
    FILE_COUNT=$((FILE_COUNT + 1))
    
    # Init metrics
    SCORE_SYS=0   # 系统逻辑性
    SCORE_ACT=0   # 落地可操作性
    SCORE_AUT=0   # 自动化/自反馈
    
    # 1. 系统逻辑性 (MAX 100)
    # 包含 Frontmatter
    if head -n 1 "$file" | grep -q "^---"; then SCORE_SYS=$((SCORE_SYS + 20)); fi
    # 包含 Markdown 层级划分
    if grep -q "^## " "$file"; then SCORE_SYS=$((SCORE_SYS + 20)); fi
    # 包含检查清单
    if grep -Fq -- "- [ ]" "$file"; then SCORE_SYS=$((SCORE_SYS + 60)); fi

    # 2. 落地可操作性 (MAX 100)
    SCORE_ACT=40 # 基础分
    # 包含可执行的 bash/sh 命令块
    if grep -q -E "\`\`\`(bash|sh)" "$file"; then SCORE_ACT=$((SCORE_ACT + 60)); fi
    # 反纯理论：存在模糊词汇扣分
    if grep -q -E "(尽量|好像|大概|建议)" "$file"; then SCORE_ACT=$((SCORE_ACT - 20)); fi
    if [ $SCORE_ACT -lt 0 ]; then SCORE_ACT=0; fi

    # 3. 自动化/自反馈 (MAX 100)
    # 引用了工作流 `/指令`，或者包含 `.sh` 脚本执行，或者提及 `hooks`/自动化
    if grep -q -E "(/\w+|\.sh|hook|自动化校验|自动执行)" "$file"; then 
        SCORE_AUT=100
    else
        # 至少提及具体工具如 grep, find, npm 等给 40 分
        if grep -q -E "(grep|find|npm|python|npx|make|cargo|test)" "$file"; then SCORE_AUT=40; fi
    fi

    FILE_TOTAL=$(( (SCORE_SYS + SCORE_ACT + SCORE_AUT) / 3 ))
    TOTAL_SCORE=$((TOTAL_SCORE + FILE_TOTAL))

    color=$GREEN
    if [ "$FILE_TOTAL" -lt 60 ]; then color=$RED; elif [ "$FILE_TOTAL" -lt 85 ]; then color=$YELLOW; fi
    
    printf "${BOLD}%-25s${NC} : ${color}%3d/100${NC} (系统:%3d, 落地:%3d, 自动:%3d)\n" "$base" "$FILE_TOTAL" "$SCORE_SYS" "$SCORE_ACT" "$SCORE_AUT"
done

if [ "$FILE_COUNT" -eq 0 ]; then
    echo "未找到 markdown 文件"
    exit 0
fi

AVG_SCORE=$(( TOTAL_SCORE / FILE_COUNT ))
color=$GREEN
if [ "$AVG_SCORE" -lt 60 ]; then color=$RED; elif [ "$AVG_SCORE" -lt 85 ]; then color=$YELLOW; fi

echo -e "\n${BOLD}>>> 规范综合得分: ${color}${AVG_SCORE} / 100${NC}"
exit 0
