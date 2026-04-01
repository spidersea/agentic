---
description: 安全基线规则 — 密钥管理、输入验证、最小权限
---

# 安全基线规则

> 本规则适用于所有文件（无 `paths` 限定 = 全局生效）。

## 密钥与敏感信息
- [ ] 绝不硬编码密钥、token、密码 → 使用环境变量或配置管理
- [ ] 禁止在日志中输出密码、token、个人信息
- [ ] 禁止在 AGENT.md 或任何 markdown 文件中放置密钥

## 输入验证
- [ ] 所有外部输入（API 参数、用户输入、文件内容）必须验证后再使用
- [ ] 在函数入口验证参数，发现问题立即抛出（快速失败）
- [ ] SQL 查询必须使用参数化查询，禁止字符串拼接

## 权限控制
- [ ] 代码只请求完成任务所需的最小权限
- [ ] API 端点必须有认证和授权检查
- [ ] 文件操作限制在项目目录内，禁止访问系统关键路径

## 工具权限矩阵 (Tool Permission Policy)

> 借鉴 Claude Code 的 `PermissionMode` 分层设计。Agent 在执行操作前，必须对照权限级别判断是否需要用户确认。

| 操作类型 | 所需权限级别 | 典型操作示例 | 用户确认要求 |
|---|---|---|---|
| **ReadOnly** — 只读操作 | 🟢 自动允许 | `grep`/`find`/`cat`/`ls`/文件阅读/搜索 | 无需确认 |
| **WorkspaceWrite** — 工作区写入 | 🟡 契约范围内允许 | 创建/修改代码文件、编辑配置、写测试 | 需在任务契约范围内；超出范围需确认 |
| **DangerFullAccess** — 危险操作 | 🔴 必须用户确认 | `npm install`/`pip install`/`docker`/`rm -rf`/`curl \| bash`/外部API调用 | **每次必须确认**，无例外 |

**提权规则：**
- 当前操作的权限需求 ≤ 当前会话权限级别 → 自动允许
- 当前操作需要更高权限 → 向用户请求临时提权（说明操作内容和风险）
- 用户拒绝提权 → 操作被拒绝，Agent 必须寻找替代方案或上报
- ⛔ **默认权限级别为 WorkspaceWrite**（不是 DangerFullAccess），这是有意为之的安全默认值
- ℹ️ 会话权限级别由外部 harness（如 IDE 插件、CLI 工具）在会话开始时初始化，AGENT.md 规范不控制此行为

**Pre/Post 工具执行安全检查：**
- [ ] **Pre-Tool**: 执行任何写操作前，确认操作在任务契约范围内
- [ ] **Pre-Tool**: 执行 shell 命令前，扫描是否包含危险模式（`rm -rf /`、`curl | bash`、`chmod 777`、`> /dev/sda`、`sudo`、`eval`、`exec`、`python -c`、`node -e`）
- [ ] **Post-Tool**: 文件写入后，确认变更文件数量在预期范围内（单次不应超过 3 个新文件）
- [ ] **Post-Tool**: Shell 命令执行后，检查 exit code，非零时主动上报而非忽略

## 依赖安全
- [ ] 不得自行引入未经授权的第三方依赖
- [ ] 引入新依赖前必须向用户确认
- [ ] 引入新依赖必须检查：主流维护中（非 deprecated/abandoned）、无已知 CVE、不在可疑 registry（如 typosquat 包名）

## 供应链安全（autoresearch 场景）
- [ ] `/autoresearch:fix` 修复依赖错误时，**禁止**自动升级主版本（major）依赖，必须向用户确认
- [ ] 修复 CI 失败时，不可引入 `curl | bash` 或未知来源的 script 步骤


## 自动化合规验证
可以使用如下命令验证当前环境状态：
```bash
bash .agent/scripts/health-check.sh .
```
