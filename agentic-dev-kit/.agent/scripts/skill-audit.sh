#!/bin/bash
# =============================================================================
# Skill Quality Audit — 自动化 Skill 质量基线检查 (增强版)
# 检查项: 文件存在/frontmatter/description/version/长度/触发条件/
#          输入输出契约/步骤结构/Token效率/反模式定义/路由注册
# 用法: bash .agent/scripts/skill-audit.sh [项目根目录]
# 退出码: 0=全部通过, 1=有警告, 2=有错误
# =============================================================================

set -uo pipefail

PROJECT_ROOT="${1:-.}"
SKILLS_DIR="${PROJECT_ROOT}/.agent/skills"

# --- 颜色 ---
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- 计数器 ---
TOTAL=0
PASS=0
WARN=0
FAIL=0
INFO=0

echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║       Skill Quality Audit — 技能质量审计报告       ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}项目路径:${NC} $(cd "$PROJECT_ROOT" && pwd)"
echo -e "${CYAN}检查时间:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

if [ ! -d "$SKILLS_DIR" ]; then
    echo -e "${RED}错误: 未找到 .agent/skills 目录${NC}"
    exit 2
fi

echo -e "${BOLD}━━━ 逐项审计 ━━━${NC}"
echo ""

for skill_dir in "$SKILLS_DIR"/*/; do
    [ ! -d "$skill_dir" ] && continue
    skill_name=$(basename "$skill_dir")
    
    # 跳过隐藏目录、.DS_Store 和归档目录
    [[ "$skill_name" == .* ]] && continue
    [[ "$skill_name" == _* ]] && continue
    
    TOTAL=$((TOTAL + 1))
    issues=()
    
    # 检查 1: SKILL.md 是否存在
    if [ ! -f "$skill_dir/SKILL.md" ]; then
        issues+=("❌ 缺少 SKILL.md")
    else
        # 检查 2: YAML frontmatter 是否存在
        if ! head -1 "$skill_dir/SKILL.md" | grep -q "^---"; then
            issues+=("⚠ SKILL.md 缺少 YAML frontmatter")
        else
            # 提取 frontmatter 内容（第1个---到第2个---之间）
            fm_block=$(sed -n '2,/^---$/p' "$skill_dir/SKILL.md")

            # 检查 2a: name 字段是否存在
            if ! echo "$fm_block" | grep -q "^name:"; then
                issues+=("❌ frontmatter 中缺少 name 字段")
            fi

            # 检查 3: description 字段是否存在
            if ! echo "$fm_block" | grep -q "description:"; then
                issues+=("⚠ frontmatter 中缺少 description 字段")
            fi

            # 检查 3a: version 格式是否正确（不允许 version 行尾粘连其他内容）
            version_line=$(echo "$fm_block" | grep "^version:" | head -1)
            if [ -n "$version_line" ]; then
                if ! echo "$version_line" | grep -qE '^version:\s+[0-9]+\.[0-9]+\.[0-9]+\s*$'; then
                    issues+=("❌ version 格式异常: ${version_line} (应为 'version: X.Y.Z')")
                fi
            fi
        fi
        
        # 检查 4: 文件长度（过短可能是空壳）
        lines=$(wc -l < "$skill_dir/SKILL.md" | tr -d ' ')
        if [ "$lines" -lt 10 ]; then
            issues+=("⚠ SKILL.md 仅 ${lines} 行（过短，疑似空壳）")
        fi
        
        # 检查 5: 是否包含触发条件或使用示例
        if ! grep -qiE '(触发|trigger|用法|usage|示例|example)' "$skill_dir/SKILL.md" 2>/dev/null; then
            issues+=("⚠ 缺少触发条件/使用示例描述")
        fi

        # 检查 6: frontmatter 中是否有 version 字段
        if ! sed -n '2,/^---$/p' "$skill_dir/SKILL.md" | grep -q "version:"; then
            issues+=("⚠ frontmatter 中缺少 version 字段")
        fi

        # 检查 7: 是否有明确的输入/输出契约
        if ! grep -qiE '(输入|input|输出|output|产出|契约|contract)' "$skill_dir/SKILL.md" 2>/dev/null; then
            issues+=("ℹ 缺少显式输入/输出契约描述")
        fi

        # 检查 8: 是否有步骤/流程编号（可操作性）
        if ! grep -qE '^\s*(#{1,3}\s+)?(步骤|Step|[0-9]+\.|Phase)' "$skill_dir/SKILL.md" 2>/dev/null; then
            issues+=("⚠ 缺少编号步骤/流程结构（可操作性不足）")
        fi

        # 检查 9: 文件过长（Token 效率）
        if [ "$lines" -gt 400 ]; then
            issues+=("⚠ SKILL.md 共 ${lines} 行（过长，建议拆分或精简，目标<400行）")
        fi

        # 检查 10: 是否有反模式/禁令定义
        if ! grep -qiE '(禁止|禁令|❌|🚫|Red Line|不可|不应|anti.?pattern|反模式)' "$skill_dir/SKILL.md" 2>/dev/null; then
            issues+=("ℹ 缺少反模式/禁令定义")
        fi

        # 检查 11: 路由注册验证（检查 router-tables.md 中是否引用）
        ROUTER_FILE="${PROJECT_ROOT}/.agent/references/router-tables.md"
        if [ -f "$ROUTER_FILE" ]; then
            if ! grep -q "$skill_name" "$ROUTER_FILE" 2>/dev/null; then
                issues+=("⚠ 未在 router-tables.md 中注册路由")
            fi
        fi
    fi
    
    # 输出结果
    if [ ${#issues[@]} -eq 0 ]; then
        echo -e "  ${GREEN}✅${NC} ${skill_name}"
        PASS=$((PASS + 1))
    else
        has_error=false
        has_warn=false
        for issue in "${issues[@]}"; do
            if [[ "$issue" == ❌* ]]; then
                has_error=true
                break
            elif [[ "$issue" == ⚠* ]]; then
                has_warn=true
            fi
        done
        
        if $has_error; then
            echo -e "  ${RED}❌${NC} ${skill_name}"
            FAIL=$((FAIL + 1))
        elif $has_warn; then
            echo -e "  ${YELLOW}⚠${NC}  ${skill_name}"
            WARN=$((WARN + 1))
        else
            echo -e "  ${CYAN}ℹ${NC}  ${skill_name}"
            INFO=$((INFO + 1))
        fi
        
        for issue in "${issues[@]}"; do
            echo -e "     ${issue}"
        done
    fi
done

echo ""
echo -e "${BOLD}━━━ 总结 ━━━${NC}"
echo ""
printf "  %-25s %d\n" "总计 Skills:" "$TOTAL"
printf "  %-25s ${GREEN}%d${NC}\n" "✅ 通过:" "$PASS"
printf "  %-25s ${CYAN}%d${NC}\n" "ℹ 建议:" "$INFO"
printf "  %-25s ${YELLOW}%d${NC}\n" "⚠ 警告:" "$WARN"
printf "  %-25s ${RED}%d${NC}\n" "❌ 错误:" "$FAIL"
echo ""

PASS_RATE=0
if [ "$TOTAL" -gt 0 ]; then
    PASS_RATE=$(( (PASS * 100) / TOTAL ))
fi
echo -e "  通过率: ${BOLD}${PASS_RATE}%${NC}"

if [ "$FAIL" -gt 0 ]; then
    echo -e "  ${RED}${BOLD}🚨 存在严重质量问题，建议立即修复${NC}"
    exit 2
elif [ "$WARN" -gt 0 ]; then
    echo -e "  ${YELLOW}${BOLD}⚠ 存在质量警告，建议在下次 /evolve 时优化${NC}"
    exit 1
else
    echo -e "  ${GREEN}${BOLD}✅ 全部通过！所有 Skill 满足质量基线${NC}"
    exit 0
fi
