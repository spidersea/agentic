---
description: 多 Agent 编排细节 (框架层与架构) (从 SKILL.md 下沉)
---

# 多 Agent 架构规范 (Multi-Agent Details)

## 1. 角色矩阵与隔离级

| 角色 | 权限 | 隔离载体 | 来源参考 |
|------|------|---------|---------|
| **Lead** | 全部 | 主分支 | 本次会话主机 |
| **Coder** | R/W/E | Git Worktree | `agents/coder.md` |
| **Tester** | R/W/E | Git Worktree | `agents/tester.md` |
| **Explorer**| R-Only| 独立上下文 | `agents/explorer.md` |
| **Reviewer**| R-Only| 独立上下文 | `agents/reviewer.md` |
| **Adversary**| R-Only| 独立上下文 | `agents/adversary.md` |

- **Worktree 隔离**：写入型 Teammate 启动时，Lead 需调用 `git worktree add .worktrees/xxx -b agent/xxx`，避免串台。
- **文件白名单**:
  ```gitignore
  .worktrees/
  .agent/state/agent-messages/
  ```

## 2. 任务分解约束字典

必须包含 `depends_on` 和 `blocks` 用于搭建 DAG。
必须包含可机械测试的 `验收条件`（exit_code）。
必须包含 `禁止修改名单` 防止越权。

## 3. Dependency Coordination (DAG 通信协议)

- **调度机制**: 将无依赖的任务投入 `Wave 0` (并行分发)。有依赖的任务等上游发出 `status: completed` 后投入后续 Wave。如遇循环依赖立即打断报错。
- **消息交换格式**:
  ```markdown
  ---
  from: coder
  task_id: task-001
  status: completed | failed | blocked
  esc_level: L0
  ---
  ## 完成报告
  [修改的文件，接口变更，验收结果]
  ```
- **接口防腐层**: 如果子任务改了共用接口（参数、签名），必须在报告里标明。Lead 必须转发给下游。

## 4. 与现有矩阵整合点
- `autoresearch`: Loop 中卡壳可将调研+测试并行下发。
- `escalation`: 子网卡壳计入全局失效，Lead 承接最大 Esc_Level。
- `hooks-lifecycle`: hooks 会强制清理残留的 worktree 并归档 messages。
