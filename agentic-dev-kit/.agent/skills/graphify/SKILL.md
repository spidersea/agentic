---
name: graphify
description: 多模态知识图谱技能 — 将任意文件夹（代码、文档、论文、图片）构建为可查询的知识图谱，支持社区检测、God Node 分析、交互式可视化、Token 压缩（71.5x）。模型无关，纯代码项目无需 LLM。
version: 0.3.17
---

# 知识图谱技能 (Graphify)

> 基于 [graphify](https://github.com/safishamsi/graphify)（13.9k ⭐，MIT 协议），将代码、文档、论文、图片转化为结构化知识图谱。
>
> **核心价值**: 将 "凭直觉 grep 文件" 升级为 "用图谱结构导航"。
> 比读取原始文件减少 **71.5x Token**（大型语料库实测）。

---

## 1. 前置条件

```bash
# 检查是否已安装
python3 -c "import graphify" 2>/dev/null && echo "OK" || echo "NEED INSTALL"

# 安装（需要 Python 3.10+）
pip install graphifyy
```

**可用性检查**: 所有引用本技能的工作流步骤都必须先检查 `graphify` 是否可用。如果不可用，降级为 grep/find 手动方式，**绝不阻塞工作流**。

---

## 2. 图谱模型

### 节点类型

| 类型 | 说明 | 提取方式 |
|---|---|---|
| Code Entity | 类/函数/类型/测试 | tree-sitter AST（20 语言，无需 LLM） |
| Document Concept | 文档中的命名概念 | AI Agent 语义提取 |
| Paper Concept | 论文中的概念/引用 | AI Agent 语义提取 |
| Image Concept | 图片中的概念/布局 | AI Agent Vision 提取 |

### 边类型与可信度

| 可信度 | 含义 | 示例 |
|---|---|---|
| `EXTRACTED` | 源码中直接声明的关系 | import、函数调用、继承 |
| `INFERRED` | 合理推断的关系（含置信度分数） | 共享数据结构、语义相似 |
| `AMBIGUOUS` | 不确定关系，标记待人工审核 | 弱关联、跨语言推测 |

### 支持语言（20 种，via tree-sitter）

Python · TypeScript · JavaScript · Go · Rust · Java · C · C++ · Ruby · C# · Kotlin · Scala · PHP · Swift · Lua · Zig · PowerShell · Elixir · Objective-C · Julia

### 支持文件类型

| 类型 | 扩展名 | 提取方式 |
|---|---|---|
| 代码 | `.py .ts .js .go .rs .java .c .cpp .rb .cs .kt .scala .php` 等 | tree-sitter AST + 调用图（**无需 LLM**） |
| 文档 | `.md .txt .rst` | AI Agent 概念/关系提取 |
| 论文 | `.pdf` | 引用挖掘 + 概念提取 |
| 图片 | `.png .jpg .webp .gif` | AI Agent Vision |

---

## 3. 核心操作

### 3.1 构建图谱 — `/graphify`

```
/graphify                          # 当前目录全量构建
/graphify ./src                    # 指定文件夹
/graphify ./src --mode deep        # 深度模式，更多 INFERRED 边
/graphify ./src --update           # 增量更新（只处理变更文件）
/graphify ./src --watch            # 监控模式，代码变更时自动重建（无需 LLM）
/graphify ./src --wiki             # 构建 Agent 可导航的 Wiki
/graphify ./src --svg              # 导出 SVG
/graphify ./src --graphml          # 导出 GraphML (Gephi, yEd)
/graphify ./src --neo4j            # 生成 Cypher 导入脚本
/graphify ./src --mcp              # 启动 MCP stdio server
```

**输出目录：**
```
graphify-out/
├── graph.html          # 交互式可视化图，浏览器直接打开
├── GRAPH_REPORT.md     # God Nodes、意外连接、建议问题
├── graph.json          # 持久化图谱（JSON），跨会话可查询
├── wiki/               # Wikipedia 风格文章（--wiki）
└── cache/              # SHA256 缓存，增量更新只处理变更文件
```

### 3.2 查询图谱 — `/graphify query`

```
/graphify query "what connects X to Y?"             # BFS 广度搜索（默认）
/graphify query "how does X reach Y?" --dfs          # DFS 深度追踪
/graphify query "..." --budget 1500                  # 限制输出 Token 预算
```

| 模式 | 适用场景 |
|---|---|
| BFS（默认） | "X 连接了什么？" — 获取广泛上下文 |
| DFS | "X 如何到达 Y？" — 追踪具体路径 |

**执行流程：**
1. 检查 `graphify-out/graph.json` 存在，否则提示先运行 `/graphify`
2. 加载图谱，从问题中提取关键词，找 1-3 个最佳匹配起始节点
3. 按模式（BFS depth=3 / DFS depth=6）遍历子图
4. 按 Token 预算（默认 2000）截断输出
5. **仅使用图谱内容回答**，引用 `source_location`；图谱信息不足时明确说明

```bash
$(cat graphify-out/.graphify_python) -c "
import sys, json
from networkx.readwrite import json_graph
import networkx as nx
from pathlib import Path

data = json.loads(Path('graphify-out/graph.json').read_text())
G = json_graph.node_link_graph(data, edges='links')

question = 'QUESTION'
mode = 'MODE'  # 'bfs' or 'dfs'
terms = [t.lower() for t in question.split() if len(t) > 3]

scored = []
for nid, ndata in G.nodes(data=True):
    label = ndata.get('label', '').lower()
    score = sum(1 for t in terms if t in label)
    if score > 0:
        scored.append((score, nid))
scored.sort(reverse=True)
start_nodes = [nid for _, nid in scored[:3]]

if not start_nodes:
    print('No matching nodes found for query terms:', terms)
    sys.exit(0)

subgraph_nodes = set()
subgraph_edges = []

if mode == 'dfs':
    visited = set()
    stack = [(n, 0) for n in reversed(start_nodes)]
    while stack:
        node, depth = stack.pop()
        if node in visited or depth > 6:
            continue
        visited.add(node)
        subgraph_nodes.add(node)
        for neighbor in G.neighbors(node):
            if neighbor not in visited:
                stack.append((neighbor, depth + 1))
                subgraph_edges.append((node, neighbor))
else:
    frontier = set(start_nodes)
    subgraph_nodes = set(start_nodes)
    for _ in range(3):
        next_frontier = set()
        for n in frontier:
            for neighbor in G.neighbors(n):
                if neighbor not in subgraph_nodes:
                    next_frontier.add(neighbor)
                    subgraph_edges.append((n, neighbor))
        subgraph_nodes.update(next_frontier)
        frontier = next_frontier

token_budget = BUDGET  # default 2000
char_budget = token_budget * 4

def relevance(nid):
    label = G.nodes[nid].get('label', '').lower()
    return sum(1 for t in terms if t in label)

ranked_nodes = sorted(subgraph_nodes, key=relevance, reverse=True)
lines = [f'Traversal: {mode.upper()} | Start: {[G.nodes[n].get(\"label\",n) for n in start_nodes]} | {len(subgraph_nodes)} nodes']
for nid in ranked_nodes:
    d = G.nodes[nid]
    lines.append(f'  NODE {d.get(\"label\", nid)} [src={d.get(\"source_file\",\"\")} loc={d.get(\"source_location\",\"\")}]')
for u, v in subgraph_edges:
    if u in subgraph_nodes and v in subgraph_nodes:
        d = G.edges[u, v]
        lines.append(f'  EDGE {G.nodes[u].get(\"label\",u)} --{d.get(\"relation\",\"\")} [{d.get(\"confidence\",\"\")}]--> {G.nodes[v].get(\"label\",v)}')

output = '\n'.join(lines)
if len(output) > char_budget:
    output = output[:char_budget] + f'\n... (truncated at ~{token_budget} token budget)'
print(output)
"
```

替换 `QUESTION`、`MODE`（`bfs`/`dfs`）、`BUDGET`（默认 `2000`）。

### 3.3 路径追踪 — `/graphify path`

```
/graphify path "AuthModule" "Database"    # 两个概念间的最短路径
```

**执行流程：**

```bash
$(cat graphify-out/.graphify_python) -c "
import json, sys
import networkx as nx
from networkx.readwrite import json_graph
from pathlib import Path

data = json.loads(Path('graphify-out/graph.json').read_text())
G = json_graph.node_link_graph(data, edges='links')

a_term = 'NODE_A'
b_term = 'NODE_B'

def find_node(term):
    term = term.lower()
    scored = sorted(
        [(sum(1 for w in term.split() if w in G.nodes[n].get('label','').lower()), n)
         for n in G.nodes()],
        reverse=True
    )
    return scored[0][1] if scored and scored[0][0] > 0 else None

src = find_node(a_term)
tgt = find_node(b_term)

if not src or not tgt:
    print(f'Could not find nodes matching: {a_term!r} or {b_term!r}')
    sys.exit(0)

try:
    path = nx.shortest_path(G, src, tgt)
    print(f'Shortest path ({len(path)-1} hops):')
    for i, nid in enumerate(path):
        label = G.nodes[nid].get('label', nid)
        if i < len(path) - 1:
            edge = G.edges[nid, path[i+1]]
            rel = edge.get('relation', '')
            conf = edge.get('confidence', '')
            print(f'  {label} --{rel}--> [{conf}]')
        else:
            print(f'  {label}')
except nx.NetworkXNoPath:
    print(f'No path found between {a_term!r} and {b_term!r}')
except nx.NodeNotFound as e:
    print(f'Node not found: {e}')
"
```

替换 `NODE_A`、`NODE_B` 为实际概念名。

### 3.4 节点解释 — `/graphify explain`

```
/graphify explain "SwinTransformer"       # 某个概念的完整关联说明
```

**执行流程：**

```bash
$(cat graphify-out/.graphify_python) -c "
import json, sys
import networkx as nx
from networkx.readwrite import json_graph
from pathlib import Path

data = json.loads(Path('graphify-out/graph.json').read_text())
G = json_graph.node_link_graph(data, edges='links')

term = 'NODE_NAME'
term_lower = term.lower()

scored = sorted(
    [(sum(1 for w in term_lower.split() if w in G.nodes[n].get('label','').lower()), n)
     for n in G.nodes()],
    reverse=True
)
if not scored or scored[0][0] == 0:
    print(f'No node matching {term!r}')
    sys.exit(0)

nid = scored[0][1]
data_n = G.nodes[nid]
print(f'NODE: {data_n.get(\"label\", nid)}')
print(f'  source: {data_n.get(\"source_file\",\"unknown\")}')
print(f'  type: {data_n.get(\"file_type\",\"unknown\")}')
print(f'  degree: {G.degree(nid)}')
print()
print('CONNECTIONS:')
for neighbor in G.neighbors(nid):
    edge = G.edges[nid, neighbor]
    nlabel = G.nodes[neighbor].get('label', neighbor)
    rel = edge.get('relation', '')
    conf = edge.get('confidence', '')
    src_file = G.nodes[neighbor].get('source_file', '')
    print(f'  --{rel}--> {nlabel} [{conf}] ({src_file})')
"
```

替换 `NODE_NAME`。输出后写 3-5 句纯语言解释。

### 3.5 URL 摄入 — `/graphify add`

```
/graphify add https://arxiv.org/abs/1706.03762       # 论文
/graphify add https://x.com/karpathy/status/...      # 推文
/graphify add https://example.com/article            # 网页
```

**执行流程：**

```bash
$(cat graphify-out/.graphify_python) -c "
import sys
from graphify.ingest import ingest
from pathlib import Path

try:
    out = ingest('URL', Path('./raw'), author='AUTHOR', contributor='CONTRIBUTOR')
    print(f'Saved to {out}')
except (ValueError, RuntimeError) as e:
    print(f'error: {e}', file=sys.stderr)
    sys.exit(1)
"
```

替换 `URL`、`AUTHOR`、`CONTRIBUTOR`。成功后自动运行 `--update` 将新文件合入图谱。

支持 URL 类型（自动检测）：Twitter/X → oEmbed · arXiv → 摘要 · PDF → 下载 · 图片 → Vision · 网页 → html2text

### 3.6 增量更新 — `/graphify --update`

仅重新提取变更文件（节省 Token 和时间）：

```bash
$(cat graphify-out/.graphify_python) -c "
import sys, json
from graphify.detect import detect_incremental
from pathlib import Path

result = detect_incremental(Path('INPUT_PATH'))
new_total = result.get('new_total', 0)
Path('graphify-out/.graphify_incremental.json').write_text(json.dumps(result))
if new_total == 0:
    print('No files changed since last run. Nothing to update.')
    raise SystemExit(0)
print(f'{new_total} new/changed file(s) to re-extract.')
"
```

**纯代码变更**（所有变更文件扩展名在 CODE_EXTS 中）：跳过 Part B 语义提取（无需 LLM），只运行 Part A AST + merge + Step 4-9。

**含文档/图片变更**：运行完整 Step 3A-3C + merge + Step 4-9。

Merge 逻辑：加载 `graphify-out/graph.json` 现有图 → 清除已删除文件的 ghost nodes → 合入新提取结果 → 重新聚类。

### 3.7 图谱分析输出

**God Nodes** — 最高连接度节点（核心抽象概念）

**Surprising Connections** — 按复合评分排名的意外连接，跨社区边排名更高

**Suggested Questions** — 图谱独特能解答的 4-5 个问题

**Token Benchmark** — 每次运行自动打印 Token 压缩比

---

## 4. 执行流程

当用户调用 `/graphify` 时，按以下步骤执行（不可跳步）：

### Step 1 — 确保 graphify 已安装

```bash
python3 -c "import graphify" 2>/dev/null || { echo "ERROR: graphify not installed. Run: pip install graphifyy"; exit 1; }
mkdir -p graphify-out
python3 -c "import sys; open('graphify-out/.graphify_python', 'w').write(sys.executable)"
```

**后续所有 bash 中，使用 `$(cat graphify-out/.graphify_python)` 替代 `python3`。**

### Step 2 — 检测文件

```bash
$(cat graphify-out/.graphify_python) -c "
import json
from graphify.detect import detect
from pathlib import Path
result = detect(Path('INPUT_PATH'))
print(json.dumps(result))
" > graphify-out/.graphify_detect.json
```

静默读取 JSON，向用户展示简洁摘要：
```
Corpus: X files · ~Y words
  code:     N files (.py .ts .go ...)
  docs:     N files (.md .txt ...)
  papers:   N files (.pdf ...)
  images:   N files
```

判断逻辑：
- `total_files` = 0 → 停止
- `total_words` > 2,000,000 OR `total_files` > 200 → 警告，询问子文件夹
- 否则 → 直接进入 Step 3

### Step 3 — 提取实体和关系

**Part A — AST 确定性提取（代码文件，无需 LLM）：**

```bash
$(cat graphify-out/.graphify_python) -c "
import sys, json
from graphify.extract import collect_files, extract
from pathlib import Path

detect = json.loads(Path('graphify-out/.graphify_detect.json').read_text())
code_files = []
for f in detect.get('files', {}).get('code', []):
    code_files.extend(collect_files(Path(f)) if Path(f).is_dir() else [Path(f)])

if code_files:
    result = extract(code_files)
    Path('graphify-out/.graphify_ast.json').write_text(json.dumps(result, indent=2))
    print(f'AST: {len(result[\"nodes\"])} nodes, {len(result[\"edges\"])} edges')
else:
    Path('graphify-out/.graphify_ast.json').write_text(json.dumps({'nodes':[],'edges':[],'input_tokens':0,'output_tokens':0}))
    print('No code files - skipping AST extraction')
"
```

**Part B — 语义提取（文档/论文/图片，需要 AI Agent）：**

如果检测到零文档/论文/图片（纯代码项目），跳过 Part B。

否则：
1. 检查提取缓存（`check_semantic_cache`）
2. 将未缓存文件按 20-25 个一组分块
3. **使用 Agent tool 并行派发子代理**（所有 Agent 调用在同一消息中发出）
4. 收集结果，缓存新提取，合并

每个子代理提取 JSON schema：
```json
{
  "nodes": [{"id": "...", "label": "...", "source_file": "..."}],
  "edges": [{"source": "...", "target": "...", "relation": "...", "confidence": "EXTRACTED|INFERRED|AMBIGUOUS", "confidence_score": 0.8}],
  "hyperedges": []
}
```

**Part C — 合并 AST + 语义结果**

### Step 4 — 构建图谱、聚类、分析

```bash
$(cat graphify-out/.graphify_python) -c "
import sys, json
from graphify.build import build_from_json
from graphify.cluster import cluster, score_all
from graphify.analyze import god_nodes, surprising_connections, suggest_questions
from graphify.report import generate
from graphify.export import to_json
from pathlib import Path

extraction = json.loads(Path('graphify-out/.graphify_extract.json').read_text())
detection  = json.loads(Path('graphify-out/.graphify_detect.json').read_text())

G = build_from_json(extraction)
communities = cluster(G)
cohesion = score_all(G, communities)
tokens = {'input': extraction.get('input_tokens', 0), 'output': extraction.get('output_tokens', 0)}
gods = god_nodes(G)
surprises = surprising_connections(G, communities)
labels = {cid: 'Community ' + str(cid) for cid in communities}
questions = suggest_questions(G, communities, labels)

report = generate(G, communities, cohesion, labels, gods, surprises, detection, tokens, 'INPUT_PATH', suggested_questions=questions)
Path('graphify-out/GRAPH_REPORT.md').write_text(report)
to_json(G, communities, 'graphify-out/graph.json')
print(f'Graph: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges, {len(communities)} communities')
"
```

### Step 5 — 标注社区名称

读取分析结果，为每个社区写 2-5 字的语义名称（如 "Attention Mechanism"），然后重新生成报告。

### Step 6 — 生成可视化

```bash
$(cat graphify-out/.graphify_python) -c "
import sys, json
from graphify.build import build_from_json
from graphify.export import to_html
from pathlib import Path

extraction = json.loads(Path('graphify-out/.graphify_extract.json').read_text())
analysis   = json.loads(Path('graphify-out/.graphify_analysis.json').read_text())
labels_raw = json.loads(Path('graphify-out/.graphify_labels.json').read_text()) if Path('graphify-out/.graphify_labels.json').exists() else {}

G = build_from_json(extraction)
communities = {int(k): v for k, v in analysis['communities'].items()}
labels = {int(k): v for k, v in labels_raw.items()}

if G.number_of_nodes() > 5000:
    print(f'Graph has {G.number_of_nodes()} nodes - too large for HTML viz.')
else:
    to_html(G, communities, 'graphify-out/graph.html', community_labels=labels or None)
    print('graph.html written')
"
```

### Step 7-9 — 可选导出 + Benchmark + 清理

- `--svg` → `to_svg()`
- `--graphml` → `to_graphml()`
- `--neo4j` → `to_cypher()`
- `--mcp` → `python3 -m graphify.serve graphify-out/graph.json`
- Token benchmark（`total_words > 5000` 时自动运行）
- 清理临时文件

---

## 5. 使用约束

1. **图谱是辅助，不是裁判** — 图谱查询结果只作为决策输入，Agent 仍需结合业务逻辑判断
2. **优雅降级** — graphify 不可用时，所有工作流必须能正常运行
3. **静态分析局限** — tree-sitter 无法捕获动态调用（反射、eval、依赖注入）
4. **诚实规则** — 永不编造 edge；不确定时用 AMBIGUOUS；始终展示 Token 成本
5. **大规模预警** — 超过 5000 节点时禁止 HTML 可视化
6. **纯代码免 LLM** — 纯代码项目的 AST 提取完全不需要 LLM，零 Token 成本

---

## 6. 与工作流的集成点

| 工作流 | 集成步骤 | 使用的图谱操作 |
|---|---|---|
| `/init` | 步骤 4 | `graphify .` 构建全量图谱 |
| `/new-feature` | Phase 1 调研 | `graphify query "..."` 替代 grep |
| `/new-feature` | Phase 3 编码 | `graphify path "A" "B"` 追踪影响 |
| `/review` | 步骤 1 范围确认 | 读取 `GRAPH_REPORT.md` God Nodes |
| `/review` | 步骤 3 风险扫描 | `graphify query` 查关联测试 |
| `/debug` | 步骤 3 调用链 | `graphify query` BFS 追踪调用方 |
| `/debug` | 步骤 7 同类搜索 | `graphify query` DFS 深度追踪 |
| `/tdd` | 步骤 2 诊断 | `graphify query` 查调用关系 |
| `/resume` | 步骤 3.5 变更感知 | `graphify --update` 增量更新 |

---

## 7. 技术架构

| 组件 | 技术 | 说明 |
|---|---|---|
| 图引擎 | NetworkX | 纯 Python，无需外部服务 |
| 社区检测 | Leiden (graspologic) | 基于图拓扑，非 embedding |
| 代码解析 | tree-sitter | 20 种语言，确定性 AST |
| 可视化 | vis.js | 交互式 HTML，浏览器直接打开 |
| MCP Server | stdio | 不开网络端口 |
| LLM | 模型无关 | 通过宿主 AI 助手的 Agent 机制 |

详见 `references/architecture.md`。
