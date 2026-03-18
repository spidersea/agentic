---
name: code-graph
description: 代码知识图谱管理技能 — 构建、查询和维护项目的代码结构图谱，为文件选择、影响分析和代码审查提供结构化依据
---

# 代码知识图谱技能 (Code Knowledge Graph Skill)

> 本技能基于 [code-review-graph](https://github.com/tirth8205/code-review-graph)，使用 Tree-sitter 将代码库解析为结构化知识图谱，存储函数、类、导入之间的调用/继承/测试关系，供 Agent 在选文件、审代码、做恢复时精准决策。
>
> **核心价值**: 将 "凭直觉猜该读哪些文件" 升级为 "用图谱算该读哪些文件"。

---

## 1. 前置条件

```bash
# 检查是否已安装
which code-review-graph

# 安装（需要 Python 3.10+ 和 uv）
pip install code-review-graph
code-review-graph install
```

**可用性检查**: 所有引用本技能的工作流步骤都必须先检查 `code-review-graph` 是否可用。如果不可用，降级为 grep/find 手动方式，**绝不阻塞工作流**。

---

## 2. 图谱模型

### 节点类型 (Node Kinds)

| 类型 | 说明 |
|---|---|
| `File` | 源文件 |
| `Class` | 类/结构体/接口 |
| `Function` | 函数/方法 |
| `Type` | 类型定义 |
| `Test` | 测试函数/方法 |

### 边类型 (Edge Kinds)

| 类型 | 说明 | 典型用途 |
|---|---|---|
| `CALLS` | A 调用 B | 影响分析、调用链追踪 |
| `IMPORTS_FROM` | A 导入 B | 依赖分析 |
| `INHERITS` | A 继承 B | 里氏替换检查 |
| `IMPLEMENTS` | A 实现 B | 接口兼容性检查 |
| `CONTAINS` | A 包含 B | 模块结构浏览 |
| `TESTED_BY` | A 被 B 测试 | 测试覆盖分析 |
| `DEPENDS_ON` | A 依赖 B | 构建顺序 |

### 支持语言

Python · TypeScript · JavaScript · Go · Rust · Java · C# · Ruby · Kotlin · Swift · PHP · C/C++

---

## 3. 核心操作

### 3.1 构建与更新

| 场景 | 操作 | 说明 |
|---|---|---|
| 项目首次使用 | `code-review-graph build` | 全量解析，约 10s/500文件 |
| 日常开发 | `code-review-graph update` | 增量更新，< 2s/2900文件 |
| 图谱疑似损坏 | `code-review-graph build` | 重建修复 |
| 查看状态 | `code-review-graph status` | 节点/边/语言统计 |

### 3.2 影响分析 — `get_impact_radius`

**使用场景**: `/new-feature` Phase 1/3、`/resume` 步骤 3.5

```
输入: changed_files (变更文件列表) + max_depth (跳数，默认 2)
输出: changed_nodes（直接变更节点）+ impacted_nodes（波及节点）+ impacted_files（受影响文件）
```

**决策规则**:
- 影响半径 ≤ 5 个文件 → 全部加载
- 影响半径 6-15 个文件 → 按 "变更文件 > 直接调用方 > 测试文件" 优先级选 5 个
- 影响半径 > 15 个文件 → 必须告知用户，建议拆分修改

### 3.3 审查上下文 — `get_review_context`

**使用场景**: `/review` 步骤 1

```
输入: changed_files (变更文件)
输出: 结构化审查上下文 —— 包含：
  - 影响范围图谱
  - 精简源码片段（仅变更节点 ± 3 行上下文）
  - 测试覆盖状态
  - 自动生成的审查指导
```

**输出示例**:
```
Review context for 2 changed file(s):
  - 8 directly changed nodes
  - 12 impacted nodes in 4 files

Review guidance:
- 2 changed function(s) lack test coverage: parse_config, validate_input
- Changes impact 4 other files. Consider splitting into smaller PRs.
```

### 3.4 图查询 — `query_graph`

**使用场景**: `/debug` 步骤 3、`/new-feature` Phase 1

| 查询模式 | 说明 | 典型问法 |
|---|---|---|
| `callers_of` | 谁调用了这个函数 | Debug: 追踪上游调用方 |
| `callees_of` | 这个函数调用了谁 | Debug: 追踪下游依赖 |
| `tests_for` | 这个函数有哪些测试 | Review: 检查测试覆盖 |
| `importers_of` | 谁导入了这个文件 | 新功能: 评估修改影响 |
| `imports_of` | 这个文件导入了什么 | 新功能: 了解依赖 |
| `inheritors_of` | 哪些类继承了这个类 | Review: 检查继承链 |
| `children_of` | 文件/类包含什么 | 新功能: 了解模块结构 |
| `file_summary` | 文件的完整结构摘要 | 通用: 快速了解文件 |

### 3.5 语义搜索 — `semantic_search_nodes`

**使用场景**: `/debug` 步骤 7（举一反三同类搜索）

```
输入: query (搜索描述) + kind (可选: Function/Class/Test)
输出: 按相关性排序的匹配节点列表
```

> 需要 `pip install code-review-graph[embeddings]` 启用向量搜索。未安装时降级为关键字匹配。

### 3.6 图谱统计 — `list_graph_stats`

**使用场景**: `/init` 初始化确认

输出各类节点和边的数量、支持语言、最后更新时间，用于确认图谱健康状态。

---

## 4. 使用约束

1. **图谱是辅助，不是裁判** — 图谱查询结果只作为决策输入，Agent 仍需结合业务逻辑和上下文判断
2. **优雅降级** — 图谱不可用时，所有工作流必须能正常运行，不得报错或阻塞
3. **静态分析局限** — 图谱基于 Tree-sitter 静态解析，动态调用（反射、eval、依赖注入）可能遗漏
4. **影响超限预警** — 影响半径超过 20 个节点时，必须向用户预警并建议拆分
5. **图谱保鲜** — 如果图谱最后更新时间超过当前 git HEAD 3 个 commit，应先 `update` 再查询

---

## 5. 与工作流的集成点

| 工作流 | 集成步骤 | 使用的图谱操作 |
|---|---|---|
| `/init` | 步骤 4 | `build` + `status` |
| `/new-feature` | Phase 1 调研 | `query_graph` (file_summary, importers_of, callers_of) |
| `/new-feature` | Phase 3 编码 | `get_impact_radius` |
| `/review` | 步骤 1 范围确认 | `get_review_context` |
| `/review` | 步骤 3 风险扫描 | `query_graph` (tests_for) |
| `/debug` | 步骤 3 调用链 | `query_graph` (callers_of, callees_of, tests_for) |
| `/debug` | 步骤 7 同类搜索 | `semantic_search_nodes` |
| `/resume` | 步骤 3.5 变更感知 | `get_impact_radius` |
