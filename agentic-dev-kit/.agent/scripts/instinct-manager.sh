#!/usr/bin/env bash
# ============================================================================
# instinct-manager.sh — 本能系统程序化管理器
# 将"markdown 文档中描述的本能系统"变为"可执行的管理工具"
# 用法:
#   instinct-manager.sh list             列出所有本能
#   instinct-manager.sh add <pattern>    添加新本能（初始置信度 1）
#   instinct-manager.sh score <id> <+|-> 调整置信度（+1 或 -1）
#   instinct-manager.sh promote <id>     升级为正式规则
#   instinct-manager.sh prune            清理低置信度本能
#   instinct-manager.sh status           输出统计摘要
# ============================================================================

set -uo pipefail

INSTINCT_DIR="${AGENTIC_INSTINCT_DIR:-.agent/instincts}"
PENDING_FILE="$INSTINCT_DIR/pending.yml"

# ─── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Ensure directory exists ─────────────────────────────────
ensure_dir() {
    mkdir -p "$INSTINCT_DIR"
    if [ ! -f "$PENDING_FILE" ]; then
        cat > "$PENDING_FILE" <<'EOF'
# Agentic Dev Kit — Instinct Store
# 格式: - id: N | confidence: N | pattern: "描述" | created: ISO8601
instincts: []
EOF
    fi
}

# ─── Helpers ─────────────────────────────────────────────────
next_id() {
    local max_id=0
    while IFS= read -r line; do
        local id
        id=$(echo "$line" | grep -oE 'id: [0-9]+' | grep -oE '[0-9]+')
        if [ -n "$id" ] && [ "$id" -gt "$max_id" ]; then
            max_id=$id
        fi
    done < <(grep "^  - " "$PENDING_FILE" 2>/dev/null)
    echo $((max_id + 1))
}

count_instincts() {
    grep -c "^  - " "$PENDING_FILE" 2>/dev/null || echo 0
}

# ─── Commands ────────────────────────────────────────────────
cmd_list() {
    ensure_dir
    local count
    count=$(count_instincts)

    echo -e "${BOLD}${CYAN}━━━ Instinct Store ━━━${NC}"
    echo ""

    if [ "$count" -eq 0 ]; then
        echo -e "  ${YELLOW}(空) 还没有记录任何本能${NC}"
        echo ""
        echo "  使用 instinct-manager.sh add \"<pattern>\" 添加"
        return 0
    fi

    printf "  ${BOLD}%-4s %-6s %-50s %s${NC}\n" "ID" "置信度" "模式" "创建时间"
    echo "  ─── ────── ────────────────────────────────────── ──────────"

    while IFS= read -r line; do
        local id conf pattern created
        id=$(echo "$line" | grep -oE 'id: [0-9]+' | grep -oE '[0-9]+')
        conf=$(echo "$line" | grep -oE 'confidence: [0-9]+' | grep -oE '[0-9]+')
        pattern=$(echo "$line" | grep -oE 'pattern: "[^"]*"' | sed 's/pattern: "//;s/"$//')
        created=$(echo "$line" | grep -oE 'created: [^ |]+' | sed 's/created: //')

        local color=$NC
        [ "$conf" -ge 4 ] && color=$GREEN
        [ "$conf" -le 1 ] && color=$RED

        printf "  %-4s ${color}%-6s${NC} %-50s %s\n" "$id" "★$conf" "$pattern" "${created:-N/A}"
    done < <(grep "^  - " "$PENDING_FILE" 2>/dev/null)
    echo ""
    echo "  共 $count 条本能"
}

cmd_add() {
    ensure_dir
    local pattern="$1"
    local id
    id=$(next_id)
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%S')

    # Append to pending file
    if [ "$(count_instincts)" -eq 0 ]; then
        # Replace empty array
        sed -i.bak "s/^instincts: \[\]/instincts:/" "$PENDING_FILE" && rm -f "$PENDING_FILE.bak"
    fi
    echo "  - id: $id | confidence: 1 | pattern: \"$pattern\" | created: $timestamp" >> "$PENDING_FILE"

    echo -e "${GREEN}✅ 已添加本能 #$id${NC}: $pattern (置信度 ★1)"
}

cmd_score() {
    ensure_dir
    local target_id="$1"
    local direction="${2:-+}"

    if ! grep -q "id: $target_id " "$PENDING_FILE" 2>/dev/null; then
        echo -e "${RED}❌ 未找到 ID=$target_id 的本能${NC}"
        exit 1
    fi

    # Read current confidence
    local current_line
    current_line=$(grep "id: $target_id " "$PENDING_FILE")
    local current_conf
    current_conf=$(echo "$current_line" | grep -oE 'confidence: [0-9]+' | grep -oE '[0-9]+')

    local new_conf
    if [ "$direction" = "+" ]; then
        new_conf=$((current_conf + 1))
        [ "$new_conf" -gt 5 ] && new_conf=5
    else
        new_conf=$((current_conf - 1))
        [ "$new_conf" -lt 0 ] && new_conf=0
    fi

    # Replace confidence in file
    local new_line
    new_line=$(echo "$current_line" | sed "s/confidence: $current_conf/confidence: $new_conf/")
    # Use perl for in-place replacement (macOS compatible)
    perl -i -pe "s/\Q$current_line\E/$new_line/" "$PENDING_FILE"

    local pattern
    pattern=$(echo "$current_line" | grep -oE 'pattern: "[^"]*"' | sed 's/pattern: "//;s/"$//')

    echo -e "  #$target_id: ★$current_conf → ★$new_conf  $pattern"

    if [ "$new_conf" -ge 5 ]; then
        echo -e "  ${GREEN}${BOLD}⭐ 已达最高置信度！建议运行 promote $target_id 升级为正式规则${NC}"
    fi
    if [ "$new_conf" -eq 0 ]; then
        echo -e "  ${RED}⚠ 置信度为 0，建议运行 prune 清理${NC}"
    fi
}

cmd_promote() {
    ensure_dir
    local target_id="$1"

    if ! grep -q "id: $target_id " "$PENDING_FILE" 2>/dev/null; then
        echo -e "${RED}❌ 未找到 ID=$target_id 的本能${NC}"
        exit 1
    fi

    local current_line
    current_line=$(grep "id: $target_id " "$PENDING_FILE")
    local pattern
    pattern=$(echo "$current_line" | grep -oE 'pattern: "[^"]*"' | sed 's/pattern: "//;s/"$//')
    local conf
    conf=$(echo "$current_line" | grep -oE 'confidence: [0-9]+' | grep -oE '[0-9]+')

    if [ "$conf" -lt 4 ]; then
        echo -e "${YELLOW}⚠ 本能 #$target_id 置信度仅 ★$conf（建议 ≥4 再升级）${NC}"
        echo "  继续升级请手动添加到规则文件"
        return 1
    fi

    # Remove from pending
    perl -i -ne "print unless /id: $target_id /" "$PENDING_FILE"

    # Append to promoted log
    local promoted_file="$INSTINCT_DIR/promoted.log"
    echo "[$(date '+%Y-%m-%d %H:%M')] #$target_id (★$conf): $pattern" >> "$promoted_file"

    echo -e "${GREEN}${BOLD}✅ 本能 #$target_id 已升级为正式规则${NC}"
    echo "  模式: $pattern"
    echo "  请手动添加到 .agent/rules/ 对应文件中"
    echo "  记录已保存到: $promoted_file"
}

cmd_prune() {
    ensure_dir
    local count_before
    count_before=$(count_instincts)
    local pruned=0

    # Find and remove confidence=0 entries
    while IFS= read -r line; do
        local conf
        conf=$(echo "$line" | grep -oE 'confidence: [0-9]+' | grep -oE '[0-9]+')
        if [ "$conf" -eq 0 ]; then
            local id
            id=$(echo "$line" | grep -oE 'id: [0-9]+' | grep -oE '[0-9]+')
            perl -i -ne "print unless /id: $id /" "$PENDING_FILE"
            pruned=$((pruned + 1))
            local pattern
            pattern=$(echo "$line" | grep -oE 'pattern: "[^"]*"' | sed 's/pattern: "//;s/"$//')
            echo -e "  ${RED}🗑 删除 #$id${NC}: $pattern (★0)"
        fi
    done < <(grep "^  - " "$PENDING_FILE" 2>/dev/null)

    if [ "$pruned" -eq 0 ]; then
        echo -e "${GREEN}✅ 没有需要清理的本能（所有置信度 > 0）${NC}"
    else
        echo ""
        echo -e "  清理了 $pruned 条，剩余 $((count_before - pruned)) 条"
    fi
}

cmd_status() {
    ensure_dir
    local total
    total=$(count_instincts)
    local high=0 mid=0 low=0

    while IFS= read -r line; do
        local conf
        conf=$(echo "$line" | grep -oE 'confidence: [0-9]+' | grep -oE '[0-9]+')
        if [ "$conf" -ge 4 ]; then
            high=$((high + 1))
        elif [ "$conf" -ge 2 ]; then
            mid=$((mid + 1))
        else
            low=$((low + 1))
        fi
    done < <(grep "^  - " "$PENDING_FILE" 2>/dev/null)

    local promoted=0
    [ -f "$INSTINCT_DIR/promoted.log" ] && promoted=$(wc -l < "$INSTINCT_DIR/promoted.log" | tr -d ' ')

    echo -e "${BOLD}${CYAN}━━━ Instinct System Status ━━━${NC}"
    echo ""
    echo "  总计: $total 条待评估本能"
    echo -e "  ${GREEN}★4-5 (可升级):  $high${NC}"
    echo -e "  ${YELLOW}★2-3 (观察中):  $mid${NC}"
    echo -e "  ${RED}★0-1 (淘汰候选): $low${NC}"
    echo "  已升级为规则: $promoted"
}

# ─── Router ──────────────────────────────────────────────────
case "${1:-help}" in
    list)       cmd_list ;;
    add)        shift; cmd_add "$*" ;;
    score)      cmd_score "$2" "${3:-+}" ;;
    promote)    cmd_promote "$2" ;;
    prune)      cmd_prune ;;
    status)     cmd_status ;;
    *)
        echo "Usage: instinct-manager.sh <list|add|score|promote|prune|status>"
        echo ""
        echo "  list              列出所有本能"
        echo "  add <pattern>     添加新本能（初始 ★1）"
        echo "  score <id> <+|->  调整置信度"
        echo "  promote <id>      升级为正式规则"
        echo "  prune             清理 ★0 本能"
        echo "  status            输出统计摘要"
        exit 1
        ;;
esac
