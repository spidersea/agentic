# Graphify Architecture

> 来源: [ARCHITECTURE.md](https://github.com/safishamsi/graphify/blob/v3/ARCHITECTURE.md)

graphify 是一个 AI 编码助手 Skill，由 Python 库支撑。Skill 编排 Python 库；Python 库也可独立使用。

## Pipeline

```
detect()  →  extract()  →  build_graph()  →  cluster()  →  analyze()  →  report()  →  export()
```

各阶段是独立模块中的单一函数。通过 Python dict 和 NetworkX graph 通信 — 无共享状态，副作用仅限 `graphify-out/`。

## Module Responsibilities

| 模块 | 函数 | 输入 → 输出 |
|---|---|---|
| `detect.py` | `collect_files(root)` | 目录 → `[Path]` 过滤列表 |
| `extract.py` | `extract(path)` | 文件路径 → `{nodes, edges}` dict |
| `build.py` | `build_graph(extractions)` | 提取结果列表 → `nx.Graph` |
| `cluster.py` | `cluster(G)` | 图 → 图（节点附 `community` 属性） |
| `analyze.py` | `analyze(G)` | 图 → 分析 dict（God nodes, surprises, questions） |
| `report.py` | `render_report(G, analysis)` | 图 + 分析 → GRAPH_REPORT.md 字符串 |
| `export.py` | `export(G, out_dir, ...)` | 图 → Obsidian vault, graph.json, graph.html, graph.svg |
| `ingest.py` | `ingest(url, ...)` | URL → 文件保存到语料目录 |
| `cache.py` | `check_semantic_cache / save_semantic_cache` | 文件 → (cached, uncached) 划分 |
| `security.py` | 验证助手 | URL / 路径 / 标签 → 验证通过或抛异常 |
| `validate.py` | `validate_extraction(data)` | 提取 dict → schema 错误时抛异常 |
| `serve.py` | `start_server(graph_path)` | 图文件路径 → MCP stdio server |
| `watch.py` | `watch(root, flag_path)` | 目录 → 文件变更时写 flag |
| `benchmark.py` | `run_benchmark(graph_path)` | 图文件 → 语料 vs 子图 Token 对比 |

## Extraction Output Schema

每个提取器返回：

```json
{
  "nodes": [
    {"id": "unique_string", "label": "human name", "source_file": "path", "source_location": "L42"}
  ],
  "edges": [
    {"source": "id_a", "target": "id_b", "relation": "calls|imports|uses|...", "confidence": "EXTRACTED|INFERRED|AMBIGUOUS"}
  ]
}
```

`validate.py` 在 `build_graph()` 消费前强制执行此 schema。

## Confidence Labels

| 标签 | 含义 |
|---|---|
| `EXTRACTED` | 关系在源码中显式声明（如 import 语句、直接调用） |
| `INFERRED` | 合理推断（如调用图二次遍历、上下文共现） |
| `AMBIGUOUS` | 不确定关系；在 GRAPH_REPORT.md 中标记待审核 |

## Security Model

所有外部输入经过 `graphify/security.py` 验证：

- URL → `validate_url()`（仅 http/https）+ 重定向重验证
- 下载 → `safe_fetch()` / `safe_fetch_text()`（50MB/10MB 上限）
- 图文件路径 → `validate_graph_path()`（必须在 `graphify-out/` 内）
- 节点标签 → `sanitize_label()`（控制字符清理、256 字符上限、HTML 转义）

**安全审计确认：零 subprocess / eval / exec / pickle / shell=True 使用。**
