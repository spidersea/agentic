#!/usr/bin/env bash
# ============================================================================
# score-workflows.sh — 自动量化评估工作流(Workflows)体系
# 维度：系统流程性、自旋自动化、可落地实操执行
# ============================================================================

set -uo pipefail

PROJECT_ROOT="${1:-.}"
WORKFLOWS_DIR="${PROJECT_ROOT}/.agent/workflows"

if [ ! -d "$WORKFLOWS_DIR" ]; then
    echo "目录 $WORKFLOWS_DIR 不存在"
    exit 1
fi

TOTAL_SCORE=0
FILE_COUNT=0

# Core files we are monitoring for the loop:
TARGETS=("init.md" "new-feature.md" "debug.md" "review.md" "test.md")

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}=== 工作流量化评分引擎 (Autoresearch Metric) ===${NC}"

for target_file in "${TARGETS[@]}"; do
    file="$WORKFLOWS_DIR/$target_file"
    if [ ! -f "$file" ]; then 
        echo -e "${RED}[Missing]${NC} $target_file 不存在"
        continue
    fi
    FILE_COUNT=$((FILE_COUNT + 1))
    
    # Init metrics
    SCORE_SYS=0   # 系统流程严谨性 (满分 30)
    SCORE_AUT=0   # 自旋自动化与互联 (满分 35)
    SCORE_ACT=0   # 落地执行 (满分 35)

    # 1. 流程严谨系统性 (MAX 30)
    # 必须包含 Frontmatter 配置项
    if head -n 1 "$file" | grep -q "^---"; then SCORE_SYS=$((SCORE_SYS + 15)); fi
    # 包含明确的操作化步骤（如 1. 2. 3. 编排）
    if grep -q -E "^[0-9]+\. " "$file"; then SCORE_SYS=$((SCORE_SYS + 15)); fi

    # 2. 自旋自动化与呼叫链跨级调用 (MAX 35)
    # 应提及关联其他工作流（避免死胡同）
    if grep -q -E "/(debug|escalate|test|review|new-feature|init)" "$file"; then SCORE_AUT=$((SCORE_AUT + 20)); fi
    # 调用了 scripts/ 目录下的机械脚本做卡点验证
    if grep -q -E "\.agent/scripts/" "$file"; then SCORE_AUT=$((SCORE_AUT + 15)); fi

    # 3. 落地执行性：拒绝纯文字指导原则，包含代码调用与权限免签 (MAX 35)
    # 含有 bash 代码段
    if grep -q -E "\`\`\`(bash|sh)" "$file"; then SCORE_ACT=$((SCORE_ACT + 15)); fi
    # 包含 // turbo 涡轮加速权限分配以突破繁冗
    if grep -q -F "// turbo" "$file"; then SCORE_ACT=$((SCORE_ACT + 20)); fi
    
    # 反空泛处罚
    if grep -q -E "(也许|可能|尽量|似乎|大概)" "$file"; then 
        SCORE_ACT=$((SCORE_ACT - 15))
        if [ $SCORE_ACT -lt 0 ]; then SCORE_ACT=0; fi
    fi

    FILE_TOTAL=$(( SCORE_SYS + SCORE_AUT + SCORE_ACT ))
    TOTAL_SCORE=$((TOTAL_SCORE + FILE_TOTAL))

    color=$GREEN
    if [ "$FILE_TOTAL" -lt 60 ]; then color=$RED; elif [ "$FILE_TOTAL" -lt 85 ]; then color=$YELLOW; fi
    
    printf "${BOLD}%-25s${NC} : ${color}%3d/100${NC} (系统:%3d, 互联:%3d, 落地:%3d)\n" "$target_file" "$FILE_TOTAL" "$SCORE_SYS" "$SCORE_AUT" "$SCORE_ACT"
done

if [ "$FILE_COUNT" -eq 0 ]; then
    echo "未找到任何核心 Markdown 文件"
    exit 0
fi

AVG_SCORE=$(( TOTAL_SCORE / FILE_COUNT ))
color=$GREEN
if [ "$AVG_SCORE" -lt 60 ]; then color=$RED; elif [ "$AVG_SCORE" -lt 85 ]; then color=$YELLOW; fi

echo -e "\n${BOLD}>>> 核心工作流(Top 5)综合得分: ${color}${AVG_SCORE} / 100${NC}"
exit 0
