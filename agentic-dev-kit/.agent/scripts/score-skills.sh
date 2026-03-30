#!/usr/bin/env bash
# ============================================================================
# score-skills.sh — 自动量化评估技能库(Skills)体系
# 维度：结构系统性、行动落地化、互联自治化
# ============================================================================

set -uo pipefail

PROJECT_ROOT="${1:-.}"
SKILLS_DIR="${PROJECT_ROOT}/.agent/skills"

if [ ! -d "$SKILLS_DIR" ]; then
    echo "目录 $SKILLS_DIR 不存在"
    exit 1
fi

TOTAL_SCORE=0
FILE_COUNT=0

# Core files we are monitoring for the loop:
TARGETS=(
  "world_class_coding/SKILL.md" 
  "autoresearch/SKILL.md" 
  "escalation/SKILL.md"
)

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}=== 技能库量化评分引擎 (Autoresearch Metric) ===${NC}"

for target_file in "${TARGETS[@]}"; do
    file="$SKILLS_DIR/$target_file"
    if [ ! -f "$file" ]; then 
        echo -e "${RED}[Missing]${NC} $target_file 不存在"
        continue
    fi
    FILE_COUNT=$((FILE_COUNT + 1))
    
    # Init metrics
    SCORE_SYS=0   # 结构系统性 (满分 30)
    SCORE_AUT=0   # 互联自治化 (满分 35)
    SCORE_ACT=0   # 行动落地化 (满分 35)

    # 1. 结构系统性 (MAX 30)
    # 必须包含 Frontmatter 配置项
    if head -n 1 "$file" | grep -q "^---"; then SCORE_SYS=$((SCORE_SYS + 15)); fi
    # 包含 Markdown 表格或 Checkbox 用于规范限制
    if grep -q -E "(\|-+-\|)|(- \[ \])" "$file"; then SCORE_SYS=$((SCORE_SYS + 15)); fi

    # 2. 互联自治化 (MAX 35)
    # 必须联动主工作流体系或其他技能转移
    if grep -q -E "/(debug|escalate|test|review|new-feature|init|autoresearch|tdd|evolve)" "$file"; then SCORE_AUT=$((SCORE_AUT + 20)); fi
    # 必须联动 scripts 机器环境
    if grep -q -E "\.agent/scripts/" "$file"; then SCORE_AUT=$((SCORE_AUT + 15)); fi

    # 3. 行动落地执行性 (MAX 35)
    # 含有 bash 代码段进行客观检测
    if grep -q -E "\`\`\`(bash|sh)" "$file"; then SCORE_ACT=$((SCORE_ACT + 35)); fi
    
    # 反空泛处罚
    if grep -q -E "(也许|尽量|似乎|大概)" "$file"; then 
        SCORE_ACT=$((SCORE_ACT - 15))
        if [ $SCORE_ACT -lt 0 ]; then SCORE_ACT=0; fi
    fi

    FILE_TOTAL=$(( SCORE_SYS + SCORE_AUT + SCORE_ACT ))
    TOTAL_SCORE=$((TOTAL_SCORE + FILE_TOTAL))

    color=$GREEN
    if [ "$FILE_TOTAL" -lt 60 ]; then color=$RED; elif [ "$FILE_TOTAL" -lt 85 ]; then color=$YELLOW; fi
    
    # 抽取文件顶级目录名展示
    skill_name=$(echo "$target_file" | cut -d'/' -f1)
    printf "${BOLD}%-25s${NC} : ${color}%3d/100${NC} (系统:%3d, 互联:%3d, 落地:%3d)\n" "$skill_name" "$FILE_TOTAL" "$SCORE_SYS" "$SCORE_AUT" "$SCORE_ACT"
done

if [ "$FILE_COUNT" -eq 0 ]; then
    echo "未找到任何核心 Skills Markdown 文件"
    exit 0
fi

AVG_SCORE=$(( TOTAL_SCORE / FILE_COUNT ))
color=$GREEN
if [ "$AVG_SCORE" -lt 60 ]; then color=$RED; elif [ "$AVG_SCORE" -lt 85 ]; then color=$YELLOW; fi

echo -e "\n${BOLD}>>> 核心大基座技能(Top 3)综合得分: ${color}${AVG_SCORE} / 100${NC}"
exit 0
