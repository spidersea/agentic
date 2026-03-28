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
| **pre-compact** | 上下文压缩前 | Agent 内联执行 | 保存运行时状态到检查点文件（格式见下） |
| **post-tool-use** | 命令执行完成后 | Agent 内联检测 | 检测命令失败，更新压力等级 |
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

---

## PostToolUse — 命令失败检测

> 灵感来源：[tanweai/pua](https://github.com/tanweai/pua) 的 `failure-detector.sh` hook。

**触发条件**：每次 Bash/Shell 命令执行完成后。

**检测逻辑**：

1. 检查命令 exit code 是否为非零
2. 检查输出中是否包含错误模式（`Error:`, `FAILED`, `Exception`, `fatal:`, `Permission denied` 等）
3. 如果检测到失败：
   - 更新连续失败计数（成功执行重置为 0）
   - 根据计数对照 `escalation/SKILL.md` 的压力等级表
   - 按对应等级执行强制动作
   - **写入持久化状态文件**（见下方）

**行为要求**：

- Agent 每次执行命令后应自检结果
- 连续 2 次失败 → 在内部标记 `[L1 ⚡]` 并切换方案
- 连续 3 次失败 → 标记 `[L2 🔍]` 并深度调查
- 不需要向用户显式汇报等级（内部行为约束）
- **每次等级变化必须更新持久化文件**

### 压力状态持久化（Escalation State Persistence）

> ⚠️ 压力等级（L0-L4）和连续失败计数是关键运行时状态。必须持久化到文件，否则上下文压缩后丢失。

**状态文件路径**：项目根目录 `.escalation-state.json`

```json
{
  "level": "L2",
  "consecutive_failures": 3,
  "methodology": "搜索优先",
  "methodologies_exhausted": ["RCA根因分析"],
  "hypotheses_eliminated": ["JWT alg check", "rate limit missing"],
  "last_updated": "2026-03-28T11:00:00+08:00",
  "session_id": "abc-123"
}
```

**写入时机**：
- 每次连续失败计数变化时
- 每次压力等级变化时
- 每次方法论切换时
- 每次 keep（重置 L0）时

**读取时机**：
- session-start 时读取（恢复状态）
- PreCompact 时读取（确保状态保存）
- `/resume` 时读取

**清理时机**：
- 任务完全完成（`/finish`）时**归档**到 `.agent/instincts/escalation-history/`（不直接删除，保留排障经验）
- 手动 `/context-reset` 时保留（以防丢失）

---

## PreCompact — 状态序列化格式

> 灵感来源：[tanweai/pua](https://github.com/tanweai/pua) 的 PreCompact hook + builder-journal 格式。

上下文压缩前，Agent **必须执行两步**：

### 步骤 1：更新持久化文件

将当前运行时状态写入 `.escalation-state.json`（格式见 PostToolUse 章节）。

### 步骤 2：在检查点中记录状态快照

使用以下格式将状态写入检查点文件：

```markdown
# 压缩前状态快照

## 时间戳
{ISO 时间}

## 运行时状态
- 当前 Escalation 等级: L{0-4}
- 连续失败计数: {N}
- 当前方法论: {方法论名称}
- 方法论切换次数: {N}
- 已排除假设: [{列表}]
- 持久化文件路径: .escalation-state.json ← 恢复时必读

## 活跃任务
{当前正在做什么 — 1-2 句话}

## 已尝试方案
{列表：方案描述 + 结果}

## 已排除可能
{已验证排除的假设}

## 下一假设
{计划下一步尝试什么}

## 关键上下文
{会因压缩丢失的关键信息 — 文件路径、错误消息、架构决策}
```

> ⚠️ 压缩不重置状态。失败计数和压力等级必须在压缩后通过 `.escalation-state.json` 恢复。

