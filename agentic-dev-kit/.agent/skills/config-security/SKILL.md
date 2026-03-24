---
name: config-security
description: Agent 配置安全扫描 — 检测 AGENT.md、rules、skills 中的安全风险
version: 1.0.0
---

# Agent 配置安全扫描

> 灵感来源：[AgentShield](https://github.com/affaan-m/agentshield) — 专门扫描 AI Agent 配置的安全性。
> 核心理念：不仅扫描代码安全，还要扫描 Agent 配置本身是否安全。

## 扫描维度

### 1. 密钥泄露检测

扫描以下文件中是否硬编码了敏感信息：
- `AGENT.md`
- `.agent/rules/*.md`
- `.agent/skills/*/SKILL.md`
- `.agent/workflows/*.md`

**检测模式**（14 种）：
- API Key 模式: `sk-`, `api_key=`, `apiKey:`, `OPENAI_API_KEY`
- Token 模式: `Bearer `, `token=`, `access_token`
- 密码模式: `password=`, `passwd=`, `secret=`
- AWS 模式: `AKIA`, `aws_secret_access_key`
- 连接字符串: `postgres://`, `mysql://`, `mongodb://`
- Base64 编码的敏感数据

### 2. 权限过松检测

检查 Agent 和工具的权限配置：
- Agent 定义文件中 `tools` 列表是否包含不必要的高危工具（如 `Execute` 给只需 `Read` 的 Agent）
- 工作流中是否有无限制的 `rm -rf`、`curl | bash` 等危险操作
- 是否有 `sudo` 或系统级权限操作

### 3. 提示注入风险

检查 workflow/skill/rule 文件是否可被恶意输入利用：
- 是否有用户输入直接拼接到命令中的模式
- 是否有未转义的模板变量
- 是否有 `eval` 或 `exec` 处理用户输入
- 工作流是否缺少输入校验步骤

### 4. 规则冲突检测

检查 rules 之间是否存在安全相关的冲突：
- 一条规则允许但另一条规则禁止同一操作
- 安全规则被其他规则的例外条件绕过
- 规则优先级不明确可能导致安全降级

### 5. 配置完整性

- 所有路由目标文件是否存在
- 安全规则是否为全局生效（无 `paths` 限定）
- 强制规则是否完整（对比基线清单）

## 评分标准

| 等级 | 分数范围 | 含义 |
|---|---|---|
| **A** | 90-100 | 优秀，无安全隐患 |
| **B** | 75-89 | 良好，有少量低风险发现 |
| **C** | 60-74 | 一般，有中风险发现需处理 |
| **D** | 40-59 | 较差，有高风险发现 |
| **F** | 0-39 | 危险，有密钥泄露或严重配置问题 |

**评分公式**：
```
score = 100
       - (critical_findings * 25)
       - (high_findings * 15)
       - (medium_findings * 5)
       - (low_findings * 2)
```

## 输出格式

```markdown
## Agent 配置安全扫描报告
- **扫描时间**: [时间戳]
- **安全评级**: [A-F]
- **扫描范围**: [文件数]
- **发现总数**: [N 项]

### 发现详情
| # | 严重度 | 维度 | 文件 | 描述 | 建议修复 |
|---|---|---|---|---|---|
| 1 | Critical | 密钥泄露 | AGENT.md:L12 | 发现硬编码 API Key | 移到环境变量 |
| 2 | Medium | 权限过松 | agents/tester.md | Execute 权限不必要 | 改为 Read+Write |
```

## 使用

通过 `/config-scan` 工作流触发，或在 `/autoresearch:security` 中作为附加扫描维度。
