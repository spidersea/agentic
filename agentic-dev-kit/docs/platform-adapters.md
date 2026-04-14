# 多平台适配指南

Agentic Dev Kit 的核心文件（`AGENT.md` + `.agent/`）是**纯文本配置**，可以适配任何支持指令文件的 AI 编程工具。

## 已验证平台

| 平台 | 状态 | 指令文件位置 |
|------|------|-------------|
| **Antigravity IDE** | ✅ 原生支持 | `AGENT.md` + `.agent/` |
| **Gemini CLI** | ✅ 原生支持 | `AGENT.md` + `.agent/` |

## 适配其他平台

### Cursor

Cursor 使用 `.cursorrules` 文件。适配方式：

```bash
# 方法 1：符号链接（推荐）
ln -s AGENT.md .cursorrules

# 方法 2：在 .cursorrules 中引用
echo "请阅读 AGENT.md 作为你的主要指令文件。" > .cursorrules
```

**注意事项：**
- Cursor 不自动加载 `.agent/skills/` 下的文件，需要在指令中写明路径
- `/命令` 无法直接使用，改为在对话中输入完整名称（如 "执行 new-feature 工作流"）
- 建议将关键 Skill 内容直接合并到 `.cursorrules` 中（注意 Token 限制）

### VS Code + GitHub Copilot

Copilot Chat 支持 `.github/copilot-instructions.md`：

```bash
# 复制核心指令
cp AGENT.md .github/copilot-instructions.md
```

**注意事项：**
- Copilot 不支持多文件指令加载
- 建议精简 AGENT.md 内容，只保留最关键的路由规则
- Skill 文件需要手动 @mention 给 Copilot

### Aider

Aider 支持 `.aider.conventions.md`：

```bash
# 方法 1：符号链接
ln -s AGENT.md .aider.conventions.md

# 方法 2：复制
cp AGENT.md .aider.conventions.md
```

**注意事项：**
- Aider 会自动加载该文件到每次对话中
- 由于 Aider 是命令行工具，`/命令` 体系不适用
- 建议精简为核心编码规则 + TDD 规范

### Claude Code (CLAUDE.md)

Claude Code 使用 `CLAUDE.md`：

```bash
# 直接使用
cp AGENT.md CLAUDE.md
```

**注意事项：**
- Claude Code 原生支持 `.agent/` 目录结构
- 适配性最好，几乎无需修改
- 支持 `/` 命令（需在 CLAUDE.md 中定义 slash commands）

## 最小配置导出

如果目标平台对文件大小有限制，使用最小配置：

```bash
# 导出核心文件（~500 行）
bin/agentic export --minimal ./output/
```

最小配置包含：
- `AGENT.md`（精简版，~80 行）
- `.agent/skills/world_class_coding/SKILL.md`（核心 SOP）
- `.agent/rules/red-lines.md`（三条红线）

## 通用适配原则

1. **核心文件不变**: `AGENT.md` 是路由表，适用于任何平台
2. **Skill 按需加载**: 大多数平台不支持自动加载，需要手动引用
3. **脚本独立运行**: `make test/validate/stress-test` 不依赖任何 IDE
4. **命令映射**: `/命令` 在不支持的平台改为自然语言描述

---

## 多 Agent 适配

> `/multi-agent` 工作流的核心协议（任务拆解、消息传递、冲突预检）是**平台无关的纯文本约定**。
> 唯一的平台差异在于：Lead 如何 spawn Teammate Agent。本节定义 3 级降级策略。

### 降级矩阵

| 级别 | 执行模式 | 适用平台 | 并行度 |
|------|---------|---------|--------|
| **Level 0: 原生并行** | Lead spawn 独立 Teammate subagent | Claude Code Agent Teams | 真并行 |
| **Level 1: 手动并行** | Lead 生成指令，用户在多窗口中执行 | 多终端 + 任意 AI 工具 | 人工并行 |
| **Level 2: 串行角色切换** | Lead 在单会话内按角色切换 | Antigravity, Cursor, Aider, Copilot | 串行模拟 |

### Level 0: 原生并行

适用于原生支持 subagent spawn 的平台（如 Claude Code Agent Teams）。

- Lead 直接调用 subagent API，传入 Agent prompt + 子任务描述
- 每个 Teammate 在独立上下文中运行，互不干扰
- 写入型 Teammate 在独立 git worktree 中工作
- 完成报告通过文件系统共享（`.agent/state/agent-messages/`）

### Level 1: 手动并行

适用于无原生 subagent 但可开多窗口/多终端的环境。

**操作方式**：Lead 为每个 Teammate 生成完整的启动指令，用户自行在独立终端中执行：

```bash
# 终端 A — Coder Agent
cd .worktrees/task-001-coder
# 在 AI 工具中输入以下 prompt:
"请阅读 .agent/agents/coder.md 理解你的角色。
 任务: [子任务描述]
 作用域: [scope glob]
 验收命令: [命令]
 完成后将报告写入 .agent/state/agent-messages/task-001-coder.md"
```

**平台特化**：
- **Antigravity**: 每个终端开独立 Antigravity 会话，各自加载不同 Agent prompt
- **Claude Code**: 每个终端启动 `claude --prompt "..."` 独立实例
- **Cursor**: 每个终端打开项目的不同 worktree 目录

### Level 2: 串行角色切换

适用于只能单会话工作的环境。虽然失去并行性，但保留了 **多Agent架构的核心价值**：角色隔离、作用域约束、结构化消息传递。

**操作方式**：Lead 按 DAG 拓扑排序，在单会话内逐个执行子任务：

1. 按 Wave 分组（依赖 DAG 的拓扑层级）
2. 同一 Wave 内的子任务串行执行（按优先级排序）
3. 每次角色切换时：
   - 心理重置：清空前一角色的上下文偏见
   - 读取目标角色的 `.agent/agents/{role}.md`
   - 切换到对应 worktree（写入型角色）
   - 执行子任务，产出报告
   - 切换回 Lead 角色

**关键约束**：
- 角色切换时禁止携带前一角色的未验证假设
- 每个角色仍然遵守 `.agent/agents/{role}.md` 中的权限白名单
- 完成报告仍然写入 `.agent/state/agent-messages/`（保持审计轨迹一致）

### 多 Agent 适配检测

`/multi-agent` 工作流 Step 1 会自动检测当前平台能力并选择降级级别：

| 检测信号 | 推断 |
|---------|------|
| 可调用 subagent spawn API | Level 0 |
| 用户确认可开多终端 | Level 1 |
| 以上均不满足 | Level 2 |

