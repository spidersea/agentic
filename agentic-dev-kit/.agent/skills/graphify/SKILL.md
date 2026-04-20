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
python3 -c "import graphify" 2>/dev/null && echo "OK" || echo "NEED INSTALL"
pip install graphifyy  # Python 3.10+
```

**可用性检查**: 如果不可用，降级为 grep/find 手动方式，**绝不阻塞工作流**。

---

## 2. 图谱模型

| 节点类型 | 提取方式 |
|---------|---------|
| Code Entity (类/函数/类型) | tree-sitter AST（20 语言，无需 LLM） |
| Document/Paper/Image Concept | AI Agent 语义提取 |

| 边可信度 | 含义 |
|---------|------|
| `EXTRACTED` | 源码中直接声明（import、调用、继承） |
| `INFERRED` | 合理推断（含置信度分数） |
| `AMBIGUOUS` | 不确定，待人工审核 |

支持 20 种语言：Python · TypeScript · JavaScript · Go · Rust · Java · C · C++ 等。

---

## 3. 命令接口

| 命令 | 用途 |
|------|------|
| `/graphify [path]` | 构建全量图谱 |
| `/graphify --update` | 增量更新（仅变更文件） |
| `/graphify --watch` | 监控模式 |
| `/graphify query "..."` | BFS/DFS 查询（`--dfs` `--budget N`） |
| `/graphify path "A" "B"` | 两概念间最短路径 |
| `/graphify explain "X"` | 节点完整关联说明 |
| `/graphify add <url>` | URL 摄入（arXiv/Twitter/PDF） |
| `/graphify --wiki/--svg/--graphml/--neo4j/--mcp` | 导出格式 |

**输出目录**: `graphify-out/` → `graph.html` (可视化) + `GRAPH_REPORT.md` (分析) + `graph.json` (持久化)

---

## 4. 执行流程（概要）

执行时按 Step 1-9 顺序运行。**所有 Python 脚本详见 `references/execution-scripts.md`**。

| Step | 操作 | 说明 |
|------|------|------|
| 1 | 安装检查 | 确保 graphify 可用 |
| 2 | 检测文件 | 统计文件类型和规模 |
| 3A | AST 提取 | 代码文件，无需 LLM |
| 3B | 语义提取 | 文档/论文/图片，需 AI Agent |
| 3C | 合并结果 | AST + 语义 |
| 4 | 构建+聚类+分析 | God Nodes、意外连接、建议问题 |
| 5 | 社区标注 | 语义名称 |
| 6 | 可视化 | HTML (≤5000节点) |
| 7-9 | 导出+Benchmark | 可选格式导出 |

---

## 5. 约束

1. **图谱是辅助，不是裁判** — 查询结果只作为决策输入
2. **优雅降级** — graphify 不可用时，工作流必须正常运行
3. **诚实规则** — 永不编造 edge；不确定时用 AMBIGUOUS
4. **大规模预警** — 超 5000 节点禁 HTML 可视化
5. **纯代码免 LLM** — AST 提取零 Token 成本

---

## 6. 工作流集成点

| 工作流 | 使用的图谱操作 |
|--------|--------------|
| `/init` | `graphify .` 全量构建 |
| `/new-feature` | `graphify query` + `graphify path` |
| `/review` | 读取 GRAPH_REPORT.md God Nodes |
| `/debug` | `graphify query` BFS/DFS 追踪 |
| `/resume` | `graphify --update` 增量更新 |

## 7. 技术架构

图引擎 NetworkX · 社区检测 Leiden · 代码解析 tree-sitter · 可视化 vis.js · MCP stdio

详见 `references/architecture.md`。
