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
