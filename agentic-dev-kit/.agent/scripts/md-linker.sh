#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
# MD Linker — Markdown 规范链接器
# 用途: 校验 .agent/ 规范体系的引用完整性、变更影响、契约一致性
# 用法:
#   md-linker.sh <project_root>              # 全量校验
#   md-linker.sh --impact <changed_file>     # 变更影响分析
#   md-linker.sh --deps <file>               # 查看文件的依赖关系
# ══════════════════════════════════════════════════════════════════
set -uo pipefail

# ─── 颜色定义 ─────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

CRITICAL_COUNT=0
WARNING_COUNT=0
INFO_COUNT=0

log_critical() { echo -e "  ${RED}✗ CRITICAL${RESET}: $1"; CRITICAL_COUNT=$((CRITICAL_COUNT+1)); }
log_warning()  { echo -e "  ${YELLOW}⚠ WARNING${RESET}:  $1"; WARNING_COUNT=$((WARNING_COUNT+1)); }
log_info()     { echo -e "  ${GREEN}✓${RESET} $1"; INFO_COUNT=$((INFO_COUNT+1)); }
log_section()  { echo -e "\n${BOLD}━━━ $1 ━━━${RESET}"; }

# ─── 参数解析 ─────────────────────────────────────────────
MODE="full"        # full | impact | deps
TARGET_FILE=""
PROJECT_ROOT=""

if [[ "${1:-}" == "--impact" ]]; then
    MODE="impact"
    TARGET_FILE="${2:-}"
    if [[ -z "$TARGET_FILE" ]]; then
        echo "Usage: md-linker.sh --impact <changed_file>"
        exit 1
    fi
    # Determine project root by walking up from the file
    PROJECT_ROOT="$(cd "$(dirname "$TARGET_FILE")" && while [[ ! -f "AGENT.md" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)"
elif [[ "${1:-}" == "--deps" ]]; then
    MODE="deps"
    TARGET_FILE="${2:-}"
    if [[ -z "$TARGET_FILE" ]]; then
        echo "Usage: md-linker.sh --deps <file>"
        exit 1
    fi
    PROJECT_ROOT="$(cd "$(dirname "$TARGET_FILE")" && while [[ ! -f "AGENT.md" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)"
else
    PROJECT_ROOT="${1:-.}"
fi

# Validate project root
if [[ ! -f "$PROJECT_ROOT/AGENT.md" ]]; then
    echo "Error: AGENT.md not found in $PROJECT_ROOT"
    exit 1
fi

AGENT_DIR="$PROJECT_ROOT/.agent"

# ══════════════════════════════════════════════════════════════════
# ENGINE CORE: Python-based graph analysis
# ══════════════════════════════════════════════════════════════════

run_engine() {
    export MD_LINKER_ROOT="$PROJECT_ROOT"
    export MD_LINKER_MODE="$MODE"
    export MD_LINKER_TARGET="$TARGET_FILE"
    python3 << 'PYTHON_ENGINE'
import sys, re, os, json
from pathlib import Path
from collections import defaultdict

PROJECT_ROOT = Path(os.environ["MD_LINKER_ROOT"])
MODE = os.environ["MD_LINKER_MODE"]
TARGET_FILE = os.environ.get("MD_LINKER_TARGET", "")
AGENT_DIR = PROJECT_ROOT / '.agent'

# ────────────────────────────────────────────────────────
# Phase A: Collect all managed files
# ────────────────────────────────────────────────────────
managed_files = {}  # relative_path -> absolute_path
for ext in ('*.md', '*.sh'):
    for f in AGENT_DIR.rglob(ext):
        rel = str(f.relative_to(PROJECT_ROOT))
        managed_files[rel] = f

# Add AGENT.md
agent_md = PROJECT_ROOT / 'AGENT.md'
if agent_md.exists():
    managed_files['AGENT.md'] = agent_md

# ────────────────────────────────────────────────────────
# Phase B: Extract references from each file
# ────────────────────────────────────────────────────────
# Reference patterns (ordered by specificity)
ref_patterns = [
    # @.agent/path/to/file.md style
    re.compile(r'@(\.agent/[\w\-/]+\.(?:md|sh))'),
    # `.agent/path/to/file.md` or .agent/path/to/file.md
    re.compile(r'`?(\.agent/[\w\-/]+\.(?:md|sh))`?'),
    # skills/name/SKILL.md
    re.compile(r'(skills/[\w\-]+/SKILL\.md)'),
    # skills/name (directory reference)
    re.compile(r'(?:skills/)([\w\-]+)(?:/|`|\s|$|\))'),
    # workflows/name.md
    re.compile(r'(workflows/[\w\-]+\.md)'),
    # agents/name.md
    re.compile(r'(agents/[\w\-]+\.md)'),
    # rules/name.md
    re.compile(r'(rules/[\w\-]+\.md)'),
    # scripts/name.sh
    re.compile(r'(scripts/[\w\-]+\.sh)'),
]

# Slash-command pattern
cmd_pattern = re.compile(r'`/([\w][\w\-]*(?::[\w\-]+)?)`')

# Build graph: edges[source] = [(target_ref, line_no, raw_text)]
edges = defaultdict(list)        # source_file -> [(target_file, line_no, raw_ref)]
reverse_edges = defaultdict(set) # target_file -> set of source_files
all_refs = []                    # (source, line_no, raw_ref, resolved_target, status)

# Command routing table from AGENT.md
cmd_routes = {}
if agent_md.exists():
    content = agent_md.read_text()
    # Match | `/command` | desc | `path` |
    for m in re.finditer(r'\|\s*`?/([\w\-:]+)`?\s*\|[^|]+\|\s*`?(\.agent/[\w\-/]+\.(?:md|sh))`?\s*\|', content):
        cmd_routes[m.group(1)] = m.group(2)

def resolve_ref(raw_ref, source_file):
    """Try to resolve a reference to an actual file path."""
    # Clean the reference
    clean = raw_ref.strip('`').lstrip('@')
    if clean.startswith('./'):
        clean = clean[2:]
    
    # Direct match
    if clean in managed_files:
        return clean
    
    # Try with .agent/ prefix
    with_agent = '.agent/' + clean
    if with_agent in managed_files:
        return with_agent
    
    # Check if the file physically exists on disk (covers paths in managed_files
    # that might differ by underscore vs hyphen or other minor variations)
    for candidate_path in [clean, with_agent]:
        full_path = PROJECT_ROOT / candidate_path
        if full_path.exists():
            # Add to managed_files for future lookups
            managed_files[candidate_path] = full_path
            return candidate_path
    
    # Directory to SKILL.md
    skill_dir = '.agent/skills/' + clean + '/SKILL.md'
    if skill_dir in managed_files:
        return skill_dir
    skill_disk = PROJECT_ROOT / skill_dir
    if skill_disk.exists():
        managed_files[skill_dir] = skill_disk
        return skill_dir
    
    # Just the name → try multiple locations
    name = clean.split('/')[-1].replace('.md', '').replace('.sh', '')
    for prefix, ext in [('skills', '/SKILL.md'), ('workflows', '.md'), 
                        ('agents', '.md'), ('rules', '.md'), ('scripts', '.sh')]:
        candidate = f'.agent/{prefix}/{name}{ext}'
        if candidate in managed_files:
            return candidate
        cand_disk = PROJECT_ROOT / candidate
        if cand_disk.exists():
            managed_files[candidate] = cand_disk
            return candidate
    
    return None

for rel_path, abs_path in managed_files.items():
    # Skip self-referencing (md-linker contains regex pattern examples)
    if 'md-linker' in rel_path:
        continue
    
    try:
        content = abs_path.read_text()
    except Exception:
        continue
    
    lines = content.split('\n')
    in_code_block = False
    in_html_comment = False
    
    for line_no, line in enumerate(lines, 1):
        # Track fenced code blocks in .md files
        stripped = line.strip()
        if stripped.startswith('```'):
            in_code_block = not in_code_block
            continue
        if in_code_block and rel_path.endswith('.md'):
            continue
        
        # Track HTML comments
        if '<!--' in line:
            in_html_comment = True
        if '-->' in line:
            in_html_comment = False
            continue
        if in_html_comment:
            continue
        
        for pattern in ref_patterns:
            for match in pattern.finditer(line):
                raw_ref = match.group(1) if match.lastindex else match.group(0)
                
                # Filter noise
                if raw_ref in ('md', 'sh', 'SKILL', 'agent'):
                    continue
                if len(raw_ref) < 3:
                    continue
                # Skip placeholder/example patterns
                if any(p in raw_ref for p in ['path/to', '/name', 'example', '{', '<', '目标', '/xxx', 'deploy.sh']):
                    continue
                # Skip self-referencing AGENT.md → .agent/AGENT.md
                if raw_ref == '.agent/AGENT.md':
                    continue
                    
                resolved = resolve_ref(raw_ref, rel_path)
                
                if resolved and resolved != rel_path:
                    edges[rel_path].append((resolved, line_no, raw_ref))
                    reverse_edges[resolved].add(rel_path)
                    all_refs.append((rel_path, line_no, raw_ref, resolved, 'OK'))
                elif not resolved and '/' in raw_ref:
                    # Only flag as broken if it looks like a real path
                    all_refs.append((rel_path, line_no, raw_ref, None, 'BROKEN'))

# ────────────────────────────────────────────────────────
# Phase C: Extract agent contracts from AGENT.md
# ────────────────────────────────────────────────────────
agent_contracts = {}  # agent_name -> {permission, tools[], skills[]}
if agent_md.exists():
    content = agent_md.read_text()
    # Parse delegation table
    for m in re.finditer(
        r'\|\s*([\w\-]+)\s*\|[^|]+\|\s*(ReadOnly|WorkspaceWrite|DangerFullAccess)\s*\|'
        r'\s*([^|]+)\|\s*`?(\.agent/agents/[\w\-]+\.md)`?\s*\|',
        content
    ):
        name = m.group(1).strip()
        perm = m.group(2).strip()
        tools = [t.strip() for t in m.group(3).split(',')]
        agent_contracts[name] = {
            'permission': perm,
            'tools': tools,
            'file': m.group(4).strip(),
        }

# ────────────────────────────────────────────────────────
# MODE: Full validation
# ────────────────────────────────────────────────────────
if MODE == 'full':
    results = {
        'engine1_link_errors': [],
        'engine2_orphans': [],
        'engine3_contract_violations': [],
    }
    
    # ── Engine 1: Reference Integrity ──
    print('ENGINE_1_START')
    
    # 1a. Broken references
    broken = [r for r in all_refs if r[4] == 'BROKEN']
    valid = [r for r in all_refs if r[4] == 'OK']
    print(f'REFS_TOTAL:{len(all_refs)}')
    print(f'REFS_VALID:{len(valid)}')
    print(f'REFS_BROKEN:{len(broken)}')
    
    for src, line, raw, _, _ in broken:
        print(f'BROKEN_REF:{src}:{line}:{raw}')
    
    # 1b. Route table validation
    print(f'ROUTES_TOTAL:{len(cmd_routes)}')
    route_errors = 0
    for cmd, target in cmd_routes.items():
        if target not in managed_files:
            print(f'ROUTE_BROKEN:/{cmd}:{target}')
            route_errors += 1
    print(f'ROUTES_BROKEN:{route_errors}')
    
    # 1c. Orphan detection (files not referenced by anything)
    all_targets = set()
    for src, tgts in edges.items():
        for tgt, _, _ in tgts:
            all_targets.add(tgt)
    
    # Add route targets
    for target in cmd_routes.values():
        all_targets.add(target)
    
    orphans = []
    for rel_path in managed_files:
        if rel_path == 'AGENT.md':
            continue
        if rel_path not in all_targets and rel_path not in reverse_edges:
            orphans.append(rel_path)
    
    print(f'ORPHANS:{len(orphans)}')
    for o in sorted(orphans):
        print(f'ORPHAN:{o}')
    
    print('ENGINE_1_END')
    
    # ── Engine 2: Dependency statistics ──
    print('ENGINE_2_START')
    
    # Degree distribution
    out_degrees = {f: len(tgts) for f, tgts in edges.items()}
    in_degrees = {f: len(srcs) for f, srcs in reverse_edges.items()}
    
    # Hub nodes (high in-degree = many things depend on them → risky to change)
    hubs = sorted(in_degrees.items(), key=lambda x: -x[1])[:10]
    for hub, deg in hubs:
        print(f'HUB:{hub}:{deg}')
    
    print(f'GRAPH_NODES:{len(managed_files)}')
    print(f'GRAPH_EDGES:{sum(len(v) for v in edges.values())}')
    print('ENGINE_2_END')
    
    # ── Engine 3: Contract validation ──
    print('ENGINE_3_START')
    
    violations = []
    
    # 3a. Check each agent contract
    for agent_name, contract in agent_contracts.items():
        agent_file = contract['file']
        
        # Check agent file exists
        if agent_file not in managed_files:
            print(f'CONTRACT_VIOLATION:MISSING_AGENT:{agent_name}:{agent_file}')
            violations.append(('MISSING_AGENT', agent_name, agent_file))
            continue
        
        # Check: ReadOnly agents should not be delegated in write-context workflows
        if contract['permission'] == 'ReadOnly':
            # Check if any workflow delegates to this agent with write tools
            write_tools = {'Write', 'Execute', 'Delete', 'Create'}
            agent_tools = set(contract['tools'])
            if agent_tools & write_tools:
                print(f'CONTRACT_VIOLATION:PERM_MISMATCH:{agent_name}:ReadOnly but has {agent_tools & write_tools}')
                violations.append(('PERM_MISMATCH', agent_name, str(agent_tools & write_tools)))
    
    # 3b. Check workflows reference valid agents
    for src_file, tgt_list in edges.items():
        if 'workflows/' not in src_file:
            continue
        for tgt, line_no, raw in tgt_list:
            if 'agents/' in tgt and tgt not in managed_files:
                print(f'CONTRACT_VIOLATION:MISSING_DELEGATE:{src_file}:{line_no}:{tgt}')
                violations.append(('MISSING_DELEGATE', src_file, tgt))
    
    # 3c. Check skill references in agent definitions
    for agent_name, contract in agent_contracts.items():
        agent_file = contract['file']
        if agent_file in managed_files:
            try:
                agent_content = managed_files[agent_file].read_text()
                # Check if agent references skills that exist
                for m in re.finditer(r'skills:\s*\[([^\]]+)\]', agent_content):
                    skills = [s.strip() for s in m.group(1).split(',')]
                    for skill in skills:
                        skill_path = f'.agent/skills/{skill}/SKILL.md'
                        if skill_path not in managed_files:
                            print(f'CONTRACT_VIOLATION:MISSING_SKILL:{agent_name}:{skill}')
                            violations.append(('MISSING_SKILL', agent_name, skill))
            except Exception:
                pass
    
    print(f'VIOLATIONS_TOTAL:{len(violations)}')
    print('ENGINE_3_END')

# ────────────────────────────────────────────────────────
# MODE: Impact analysis
# ────────────────────────────────────────────────────────
elif MODE == 'impact':
    target = TARGET_FILE
    # Normalize path
    try:
        target_rel = str(Path(target).relative_to(PROJECT_ROOT))
    except ValueError:
        target_rel = target
    
    if target_rel not in managed_files:
        # Try to find it
        for k in managed_files:
            if target_rel in k or k.endswith(target_rel):
                target_rel = k
                break
    
    print(f'IMPACT_TARGET:{target_rel}')
    
    # BFS to find transitive dependents
    direct = reverse_edges.get(target_rel, set())
    print(f'DIRECT_DEPENDENTS:{len(direct)}')
    for d in sorted(direct):
        print(f'DIRECT:{d}')
    
    # Transitive closure
    visited = set()
    queue = list(direct)
    while queue:
        node = queue.pop(0)
        if node in visited:
            continue
        visited.add(node)
        for parent in reverse_edges.get(node, set()):
            if parent not in visited:
                queue.append(parent)
    
    transitive = visited - direct
    print(f'TRANSITIVE_DEPENDENTS:{len(transitive)}')
    for t in sorted(transitive):
        print(f'TRANSITIVE:{t}')
    
    print(f'IMPACT_RADIUS:{len(direct) + len(transitive)}')
    
    # What does this file depend on?
    deps = edges.get(target_rel, [])
    print(f'OUTGOING_DEPS:{len(deps)}')
    for tgt, line, raw in deps:
        print(f'DEP:{tgt}:{line}')

# ────────────────────────────────────────────────────────
# MODE: deps (show file's dependency tree)
# ────────────────────────────────────────────────────────
elif MODE == 'deps':
    target = TARGET_FILE
    try:
        target_rel = str(Path(target).relative_to(PROJECT_ROOT))
    except ValueError:
        target_rel = target
    
    if target_rel not in managed_files:
        for k in managed_files:
            if target_rel in k or k.endswith(target_rel):
                target_rel = k
                break
    
    print(f'DEPS_TARGET:{target_rel}')
    
    # Outgoing
    deps = edges.get(target_rel, [])
    print(f'DEPENDS_ON:{len(deps)}')
    for tgt, line, raw in sorted(deps, key=lambda x: x[1]):
        print(f'  -> {tgt} (line {line})')
    
    # Incoming
    rdeps = reverse_edges.get(target_rel, set())
    print(f'DEPENDED_BY:{len(rdeps)}')
    for src in sorted(rdeps):
        print(f'  <- {src}')

PYTHON_ENGINE
}

# ══════════════════════════════════════════════════════════════════
# OUTPUT FORMATTER
# ══════════════════════════════════════════════════════════════════

format_full_output() {
    local engine=""
    
    while IFS= read -r line; do
        case "$line" in
            ENGINE_1_START)
                log_section "Engine 1: 引用完整性校验 (Linker)"
                ;;
            REFS_TOTAL:*)
                local total="${line#REFS_TOTAL:}"
                log_info "扫描到 $total 条跨文件引用"
                ;;
            REFS_VALID:*)
                local valid="${line#REFS_VALID:}"
                log_info "有效引用: $valid"
                ;;
            REFS_BROKEN:*)
                local broken="${line#REFS_BROKEN:}"
                if [[ "$broken" -eq 0 ]]; then
                    log_info "断链引用: 0"
                else
                    log_warning "断链引用: $broken"
                fi
                ;;
            BROKEN_REF:*)
                local detail="${line#BROKEN_REF:}"
                IFS=':' read -r src lineno ref <<< "$detail"
                log_critical "死链 $src:$lineno → $ref (目标文件不存在)"
                ;;
            ROUTES_TOTAL:*)
                local rtotal="${line#ROUTES_TOTAL:}"
                log_info "AGENT.md 路由表: $rtotal 条命令"
                ;;
            ROUTES_BROKEN:*)
                local rbroken="${line#ROUTES_BROKEN:}"
                if [[ "$rbroken" -eq 0 ]]; then
                    log_info "路由完整性: 全部指向有效文件"
                else
                    log_critical "路由断链: $rbroken 条"
                fi
                ;;
            ROUTE_BROKEN:*)
                local rdetail="${line#ROUTE_BROKEN:}"
                IFS=':' read -r cmd target <<< "$rdetail"
                log_critical "路由 $cmd → $target (目标不存在)"
                ;;
            ORPHANS:*)
                local ocount="${line#ORPHANS:}"
                if [[ "$ocount" -eq 0 ]]; then
                    log_info "孤儿文件: 0 (所有文件都被引用)"
                else
                    log_warning "孤儿文件: $ocount (未被任何文件引用)"
                fi
                ;;
            ORPHAN:*)
                local ofile="${line#ORPHAN:}"
                echo -e "    ${YELLOW}○${RESET} $ofile"
                ;;
            ENGINE_1_END)
                echo ""
                ;;
            ENGINE_2_START)
                log_section "Engine 2: 依赖图谱统计"
                ;;
            GRAPH_NODES:*)
                log_info "总节点: ${line#GRAPH_NODES:}"
                ;;
            GRAPH_EDGES:*)
                log_info "总引用边: ${line#GRAPH_EDGES:}"
                ;;
            HUB:*)
                local hdetail="${line#HUB:}"
                IFS=':' read -r hfile hdeg <<< "$hdetail"
                echo -e "    ${CYAN}◉${RESET} $hfile — 被 $hdeg 个文件依赖 (修改需谨慎)"
                ;;
            ENGINE_2_END)
                echo ""
                ;;
            ENGINE_3_START)
                log_section "Engine 3: 契约一致性校验 (Contract Checker)"
                ;;
            CONTRACT_VIOLATION:MISSING_AGENT:*)
                local cv="${line#CONTRACT_VIOLATION:MISSING_AGENT:}"
                IFS=':' read -r agent afile <<< "$cv"
                log_critical "Agent '$agent' 声明文件 $afile 不存在"
                ;;
            CONTRACT_VIOLATION:PERM_MISMATCH:*)
                local cv="${line#CONTRACT_VIOLATION:PERM_MISMATCH:}"
                log_critical "权限矛盾: $cv"
                ;;
            CONTRACT_VIOLATION:MISSING_DELEGATE:*)
                local cv="${line#CONTRACT_VIOLATION:MISSING_DELEGATE:}"
                log_critical "委派断链: $cv"
                ;;
            CONTRACT_VIOLATION:MISSING_SKILL:*)
                local cv="${line#CONTRACT_VIOLATION:MISSING_SKILL:}"
                log_warning "Agent 引用不存在的技能: $cv"
                ;;
            VIOLATIONS_TOTAL:*)
                local vtotal="${line#VIOLATIONS_TOTAL:}"
                if [[ "$vtotal" -eq 0 ]]; then
                    log_info "契约校验: 全部通过"
                else
                    log_warning "契约违规: $vtotal 项"
                fi
                ;;
            ENGINE_3_END)
                echo ""
                ;;
        esac
    done
}

format_impact_output() {
    while IFS= read -r line; do
        case "$line" in
            IMPACT_TARGET:*)
                log_section "变更影响分析"
                echo -e "  变更文件: ${BOLD}${line#IMPACT_TARGET:}${RESET}"
                ;;
            DIRECT_DEPENDENTS:*)
                echo ""
                echo -e "  ${BOLD}一级影响 (直接依赖方):${RESET} ${line#DIRECT_DEPENDENTS:} 个文件"
                ;;
            DIRECT:*)
                echo -e "    ${RED}→${RESET} ${line#DIRECT:}"
                ;;
            TRANSITIVE_DEPENDENTS:*)
                echo ""
                echo -e "  ${BOLD}二级影响 (传递依赖方):${RESET} ${line#TRANSITIVE_DEPENDENTS:} 个文件"
                ;;
            TRANSITIVE:*)
                echo -e "    ${YELLOW}↣${RESET} ${line#TRANSITIVE:}"
                ;;
            IMPACT_RADIUS:*)
                local radius="${line#IMPACT_RADIUS:}"
                echo ""
                if [[ "$radius" -gt 10 ]]; then
                    echo -e "  ${RED}⚠ 影响半径: $radius — 高风险变更，建议分阶段修改${RESET}"
                elif [[ "$radius" -gt 5 ]]; then
                    echo -e "  ${YELLOW}◎ 影响半径: $radius — 中等风险，需逐一审查${RESET}"
                else
                    echo -e "  ${GREEN}◎ 影响半径: $radius — 低风险${RESET}"
                fi
                ;;
            OUTGOING_DEPS:*)
                echo ""
                echo -e "  ${BOLD}本文件依赖:${RESET} ${line#OUTGOING_DEPS:} 个文件"
                ;;
            DEP:*)
                local ddetail="${line#DEP:}"
                IFS=':' read -r dtgt dline <<< "$ddetail"
                echo -e "    ${CYAN}←${RESET} $dtgt (line $dline)"
                ;;
        esac
    done
}

format_deps_output() {
    while IFS= read -r line; do
        case "$line" in
            DEPS_TARGET:*)
                log_section "依赖关系"
                echo -e "  文件: ${BOLD}${line#DEPS_TARGET:}${RESET}"
                ;;
            DEPENDS_ON:*)
                echo ""
                echo -e "  ${BOLD}本文件引用 (出边):${RESET} ${line#DEPENDS_ON:}"
                ;;
            DEPENDED_BY:*)
                echo ""
                echo -e "  ${BOLD}被谁引用 (入边):${RESET} ${line#DEPENDED_BY:}"
                ;;
            *)
                echo -e "  $line"
                ;;
        esac
    done
}

# ══════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════

echo -e "${BOLD}╔════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║       MD Linker — Markdown 规范链接器             ║${RESET}"
echo -e "${BOLD}╚════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "项目路径: $PROJECT_ROOT"
echo -e "模式: $MODE"

case "$MODE" in
    full)
        _tmpout=$(mktemp)
        run_engine > "$_tmpout" 2>&1
        format_full_output < "$_tmpout"
        rm -f "$_tmpout"
        
        log_section "总结"
        echo ""
        if [[ "$CRITICAL_COUNT" -eq 0 ]]; then
            echo -e "  ${GREEN}✅ 链接校验通过${RESET} — $INFO_COUNT 项通过, $WARNING_COUNT 警告, 0 CRITICAL"
        else
            echo -e "  ${RED}❌ 链接校验失败${RESET} — $CRITICAL_COUNT CRITICAL, $WARNING_COUNT 警告"
        fi
        echo ""
        
        exit "$CRITICAL_COUNT"
        ;;
    impact)
        _tmpout=$(mktemp)
        run_engine > "$_tmpout" 2>&1
        format_impact_output < "$_tmpout"
        rm -f "$_tmpout"
        echo ""
        ;;
    deps)
        _tmpout=$(mktemp)
        run_engine > "$_tmpout" 2>&1
        format_deps_output < "$_tmpout"
        rm -f "$_tmpout"
        echo ""
        ;;
esac
