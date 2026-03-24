---
name: hooks-lifecycle
description: 会话生命周期钩子 — 自动化状态保存/恢复，减少手动 checkpoint 遗漏
version: 1.0.0
---

# 会话生命周期钩子（Hooks Lifecycle）

> 灵感来源：[everything-claude-code](https://github.com/affaan-m/everything-claude-code) 的 hooks 系统（session-start / session-end / pre-compact）。
> 核心理念：在会话关键节点自动执行状态保存/恢复，确保上下文不丢失。

## 设计原则

1. **平台无关**：不依赖特定 CLI 的 hooks.json，而是通过 shell 脚本 + 工作流约定实现
2. **渐进式**：钩子是辅助手段，不替代手动 `/checkpoint` 和 `/handoff`
3. **轻量级**：每个钩子执行时间 < 3 秒，不阻塞主工作流
4. **幂等性**：多次执行同一钩子产生相同结果

## 钩子点定义

| 钩子点 | 触发时机 | 执行脚本 | 目的 |
|---|---|---|---|
| **session-start** | 新会话开始 / `/resume` | `.agent/scripts/session-start.sh` | 自动发现最新检查点，输出状态摘要 |
| **session-end** | 会话结束 / `/handoff` | `.agent/scripts/session-end.sh` | 自动生成 auto-checkpoint + 模式提取 |
| **pre-compact** | 上下文压缩前 | Agent 内联执行 | 保存关键变量和文件路径到临时文件 |
| **post-milestone** | 阶段完成后 | Agent 内联执行 | 自动触发 `/checkpoint` |

## 使用方式

### Agent 集成约定

Agent 在以下场景中应主动调用钩子脚本：

**会话开始时**（在加载 AGENT.md 后、开始任务前）：
```bash
bash .agent/scripts/session-start.sh
```
- 读取输出，了解上次会话的状态
- 如果发现未完成的任务，提示用户是否 `/resume`

**会话结束前**（在 `/handoff` 或用户要求停止后）：
```bash
bash .agent/scripts/session-end.sh
```
- 自动保存当前状态
- 提取会话模式（配合持续学习系统）

**Phase 完成后**（每个 SOP Phase 完成时）：
- 自动执行 `/checkpoint` 记录状态
- 这是一个 **软约定**，由 Agent 根据 SKILL.md 第四章规则自行判断

### 手动管理

通过 `/hooks` 工作流管理钩子行为。

## 与现有流程的关系

| 现有流程 | Hooks 的增强 |
|---|---|
| `/checkpoint` | session-end 自动生成 auto-checkpoint，手动 checkpoint 仍为主要机制 |
| `/resume` | session-start 提供更快的状态发现 |
| `/handoff` | session-end 在 handoff 前自动保存 |
| AGENT.md 上下文恢复协议 | session-start 作为恢复协议的自动化执行 |

> ⚠️ Hooks **不替代**手动流程。它们是安全网——当用户忘记 `/checkpoint` 时提供最低限度的状态保存。
