---
name: multi-agent
description: |
  多 Agent 编排协议基石 — 定义 Lead/Teammate 架构、并行隔离、任务 DAG 分解与通信。
  是对齐 Claude Code Agent Teams 能力的协议框架。
version: 1.0.0
---

# 多 Agent 编排协议 (Multi-Agent Orchestration Skill)

> 核心升级：从“单体会话内部角色扮演”升级为“跨边界并行实体协同 + 结构化收尾”。
> 详细设计载于: `references/multi-agent-details.md`。

## 1. 架构总纲
- **Lead** (指挥者，即当前主 Agent)：不干脏活。负责切分任务(DAG)、下发、检测阻塞(Poll Messages)、执行 `git merge`。
- **Teammates** (执行者)：受隔离的独立运作节点（包含 Coder / Tester / Explorer / Reviewer / Adversary）。

## 2. 物理与逻辑隔离 (Isolation)
为了不让上下文互相污染和文件操作读写冲突：
1. **写节点隔离** (Coder/Tester)：被分派到专署的子 **git worktree** 操作。
2. **读节点隔离** (审查者)：仅注入相关的代码快照。
3. **通信信标**：子节点通过向 `.agent/state/agent-messages/` 抛出特定格式的 Markdown 完成信鸽式通信，严禁串门。

## 3. DAG 与 约束
Lead 分派任务前，必须产出 **带血缘（depends_on）** 的任务树，并执行交集审查。
- 若交集 Glob 文件 > 2 个，取消并行打断编排。
- 在 Wave 中，所有子节点完成后，必须显式声明（带 status 和是否有**公共接口改变**）。如果有基础接口变动，Lead 须拦截并补发给后续任务的 Teammates。
  
## 4. 防破窗底线
❌ 严禁 Lead 盲信 Teammates 输出。Teammate 回复的 Done 只是口头声明，Lead 必须自己拉起 test 命令验身后再 merge。
❌ 严禁乱用杀鸡牛刀。如果是不到 2 个模块的代码修改，必须老老实实单兵走 `/new-feature`。
