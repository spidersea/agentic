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

---

## 主动上下文压缩协议 (Proactive Compaction)

> 对齐 Claude Code 2026 最佳实践：不要等到窗口满了才压缩，在 60% 利用率时主动压缩。

### 触发条件（满足任一即触发）

| 条件 | 阈值 | 说明 |
|------|------|------|
| **上下文利用率** | > 60% | 防止窗口饱和导致性能衰减 |
| **autoresearch 迭代** | 每 10 次迭代 | 长循环中定期清理 |
| **任务阶段完成** | SOP Phase 切换时 | 前阶段上下文对后阶段可能无用 |

### 指导性压缩

执行压缩时**必须**提供保留指令，禁止盲压缩：

```
/compact 保留：当前任务目标、escalation 等级和已排除假设、关键文件路径、
活跃测试命令、Guard 回归命令、已修改但未验证的文件列表
```

在 `CLAUDE.md` 或等效配置中加入：
```markdown
# 压缩保留规则
When compacting, always preserve:
- The full list of modified files and test commands
- Current escalation level and eliminated hypotheses
- Active task constraints and acceptance criteria
```

### 临时查询不污染主上下文

对于不需要成为长期记忆的临时问题，使用侧信道查询（等价于 Claude Code `/btw`）：
- 在主 autoresearch 循环中，临时调研用 **Explorer subagent** 处理
- subagent 输出写入文件，主 Agent 按需读取
- 临时查询的推理过程不进入主上下文窗口

---

## PostCompact — Context Essentials 自动注入

> 每次压缩后自动读取 `.agent/state/context-essentials.md`，恢复关键行为约束。

### 注入协议

```
① 压缩完成
② 自动读取 `.agent/state/context-essentials.md`
③ 从 `.escalation-state.json` 恢复压力状态
④ 更新 context-essentials.md 中的"当前任务边界"段落
⑤ 继续执行
```

### essentials 文件维护

- **创建时机**：项目首次启用 agentic-dev-kit 时创建
- **更新时机**：每次 Pre-Compact 前 Lead Agent 更新"当前任务边界"段落
- **文件位置**：`.agent/state/context-essentials.md`
- **大小约束**：不超过 50 行 — 只放"丢失会导致灾难"的规则

---

## 工具链原生对齐 (Tool Chain Integration)

> 本章将 hooks-lifecycle 从"模拟约定"升级为对 Claude Code / Gemini Antigravity 工具链的"原生对齐"。

### Claude Code hooks.json 映射

| 本规范钩子点 | Claude Code hooks.json 等价 | 对齐方式 |
|------------|-------------------------|---------|
| `session-start` | `SessionStart` event | 通过 `.claude/settings.json` 的 hooks 配置挂载 `session-start.sh` |
| `session-end` | `SessionEnd` event | 通过 hooks 配置挂载 `session-end.sh` |
| `pre-compact` | `PreCompact` event | Agent 内联执行 + hooks 配置双重保障 |
| `post-tool-use` | `PostToolUse` event | 通过 hooks 配置注入失败检测脚本 |
| `post-milestone` | 无原生等价 | Agent 内联约定（SOP Phase 完成时触发） |

**hooks.json 参考配置**（适用于 Claude Code 环境）：

```json
{
  "hooks": {
    "SessionStart": [
      {"command": "bash .agent/scripts/session-start.sh"}
    ],
    "SessionEnd": [
      {"command": "bash .agent/scripts/session-end.sh"}
    ],
    "PostToolUse": [
      {
        "matcher": {"tool_name": "bash"},
        "command": "bash .agent/scripts/post-tool-check.sh"
      }
    ]
  }
}
```

### PostToolUse 错误模式匹配表

| 错误模式 | 正则/关键词 | 严重级别 | 触发动作 |
|---------|-----------|---------|---------|
| 命令失败 | exit code ≠ 0 | ERROR | 连续失败 +1 |
| 编译错误 | `error:`, `Error:`, `FAILED` | ERROR | 连续失败 +1 |
| 异常堆栈 | `Exception`, `Traceback`, `panic:` | ERROR | 连续失败 +1 |
| 权限拒绝 | `Permission denied`, `EACCES` | ERROR | 连续失败 +1 + 检查文件权限 |
| 致命错误 | `fatal:`, `FATAL`, `Segmentation fault` | CRITICAL | 连续失败 +2（跳级） |
| 告警 | `Warning:`, `WARN`, `deprecated` | WARN | 不计入连续失败，但需记录 |
| 超时 | `timeout`, `ETIMEDOUT` | ERROR | 连续失败 +1 + 检查网络/资源 |

### MCP 通用集成指引

> 对齐 MCP v2.1（Linux Foundation 管理的行业标准协议）。

**已集成的 MCP Server**：
- `graphify --mcp`：知识图谱查询（stdio 模式）

**推荐的外部 MCP Server**（按需接入）：

| MCP Server | 用途 | 接入方式 |
|-----------|------|---------|
| GitHub MCP | PR/Issue/Actions 交互 | `claude mcp add github` |
| Filesystem MCP | 批量文件操作 | `claude mcp add filesystem` |
| Search MCP | web search 集成 | `claude mcp add search` |
| DB MCP (Postgres/SQLite) | 数据库查询 | `claude mcp add postgres` |

**安全约束**：
- 所有 MCP 连接必须是 stdio（不开网络端口）
- 最小权限原则：每个 MCP server 只授权必要的 scope
- 敏感数据（credentials）通过环境变量注入，禁止硬编码

### Plugin 扩展点

对齐 Claude Code `/plugin` 机制，本规范支持通过 skills 目录扩展能力：

```
.agent/skills/          ← 等价于 .claude/skills/（技能扩展）
.agent/agents/          ← 等价于 .claude/agents/（子Agent扩展）
.agent/hooks/           ← 等价于 .claude/settings.json hooks（钩子扩展）
.agent/rules/           ← 等价于 CLAUDE.md 规则（行为规则扩展）
```

扩展原则：
1. 新技能放入 `skills/` 并创建 `SKILL.md`（含 YAML frontmatter）
2. 新角色放入 `agents/` 并创建 `{name}.md`（含角色矩阵定义）
3. 新钩子脚本放入 `scripts/` 并在 hooks-lifecycle 中注册
4. 所有扩展必须声明与 autoresearch/escalation/agent-dsl 的集成点

---

## 与现有流程的集成

| 现有流程 | Hooks 的增强 |
|---|---|
| `/checkpoint` | session-end 自动生成 auto-checkpoint，手动 checkpoint 仍为主要机制 |
| `/resume` | session-start 提供更快的状态发现 |
| `/handoff` | session-end 在 handoff 前自动保存 |
| AGENT.md 上下文恢复协议 | session-start 作为恢复协议的自动化执行 |
| **autoresearch** | 主动压缩协议在长循环中保护上下文质量 |
| **escalation** | Post-Compact 自动从 `.escalation-state.json` 恢复压力状态 |
| **agent-dsl 路线 C** | 自执行模式中 Post-Compact 自动注入 context-essentials |
| **multi-agent** | worktree 创建/销毁事件记录到 session-end 的自动检查 |

> ⚠️ Hooks **不替代**手动流程。它们是安全网——当用户忘记 `/checkpoint` 时提供最低限度的状态保存。
