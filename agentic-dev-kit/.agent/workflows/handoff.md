---
description: 生成跨会话交接备忘录 — 标准化交接产物，用于将任务安全传递到新会话
---

# 生成交接备忘录

> 按照 SKILL.md 第四章的交接协议，生成精简的任务交接文件。
> 触发方式: `/handoff`

## 步骤

1. **收集当前状态**
   - **必须**确认当前任务名称和所处 Phase
   - **必须**检查最近的检查点状态，如果不存在，**必须**先执行 `/checkpoint` 创建
   - 整理已完成和待完成的工作
   - **强制**先执行 `/checkpoint` 确保最新状态已保存（不可跳过）

// turbo
2. **提炼核心背景**
   - 从当前会话中提取后继会话**最需要知道的核心上下文**
   - **必须**严格控制在 5 句话以内
   - 只保留对继续工作至关重要的信息，**禁止**包含冗余内容

// turbo
3. **整理关键文件**
   - **必须**列出后继会话需要读取的文件（不超过 5 个）
   - **必须**按优先级排序：契约 > 实施计划 > 核心代码 > 测试

// turbo
4. **记录已验证决策**
   - **必须**列出本会话中已经做出并验证通过的技术决策
   - 这些决策后继会话不可重新讨论

// turbo
5. **生成交接备忘录**
   **必须**按以下模板生成，**禁止**省略任何字段：

   ```markdown
   ## 任务交接备忘录
   - **任务名称**: [TaskName]
   - **当前状态**: [Phase X, CP-Y 已通过]
   - **交接时 git commit**: [git rev-parse --short HEAD 输出]
   - **核心背景** (≤5 句): [核心上下文摘要]
   - **关键文件**:
     1. [文件路径和说明]
     2. [文件路径和说明]
   - **已验证通过的决策**:
     - [决策1]
     - [决策2]
   - **待解决问题**:
     - [具体的、含完整命令的可执行下一步1]（如: `pytest tests/auth/ -v` → 预期 PASS）
     - [具体的、含完整命令的可执行下一步2]
   - **风险提示**: [未解决的阻塞项或注意事项，无则填"无"]
   ```

// turbo
5.3 **标准化交接包 (Standardized Handoff Package)**
   > 对照 ATA「new-chat-ready」和「agent-handoff」Skill 原始内容校准：
   > - agent-handoff: **3 层 Receipt** (L0 核心 ~200字 / L1 上下文 ~500字 / L2 背景 ~2000字)
   > - agent-handoff: **Claim 文件锁** (intent + lease_minutes + 4级冲突告警)
   > - agent-handoff: **PII 脱敏** (13 条正则规则覆盖凭证/个人信息/内部资产)
   > - new-chat-ready: **失败驱动压缩** ("前任为什么没做某事"比"前任做了什么"更有价值)
   > - new-chat-ready: **Project MD Sync** (将稳定知识沉淀到项目文档，减少未来重复学习)

   在交接备忘录的基础上，**必须**生成以下标准化产物：

   **a) 3 层 Receipt 上下文快照** (`handoff-context.md`)：
   > 对照 agent-handoff 的 L0/L1/L2 分层设计，按 Token 预算控制。

   ```markdown
   ## L0 核心摘要 (~200 字，接手者必读)
   - **session_id**: [当前会话标识]
   - **timestamp**: [交接时间]
   - **task_phase**: [当前 Phase]
   - **escalation_peak**: [L0-L4, 如有]
   - **一句话状态**: [当前在做什么 + 下一步是什么]
   - **待办事项**: [最关键的 1-3 件未完成工作]
   - **已改文件**: [核心变更文件列表]

   ## L1 上下文 (~500 字，按需展开)
   ### Active Files (新会话必须加载)
   | 优先级 | 文件路径 | 加载原因 |
   |--------|---------|---------|
   | P0 | [task.md / spec] | 任务契约 |
   | P1 | [核心代码文件] | 当前变更 |
   | P2 | [测试文件] | 验证覆盖 |

   ### 关键决策 (含被否决的方案)
   | 决策 | 选择 | rationale | 否决方案 |
   |------|------|-----------|---------|
   | [决策1] | [选项A] | [原因] | [选项B: 为什么不选] |

   ### Environment State
   - **branch**: [当前分支名]
   - **uncommitted_changes**: [有/无]
   - **test_status**: [最近一次测试结果]

   ## L2 背景 (~2000 字，深挖时读取)
   ### 失败方案记录 (失败驱动压缩)
   > 对照 new-chat-ready: 优先保留"为什么没做/为什么失败"
   - **未完成事项 + 阻塞原因**（最高优先）
   - **被否决的方案及其 rationale**
   - **尝试过但失败的方法**（新会话不应重复）

   ### Knowledge Transfer
   - **discovered_patterns**: [本会话发现的模式]
   - **pending_instincts**: [本会话产生的待确认本能]
   ```

   **b) PII 脱敏规则**（对照 agent-handoff 的 13 条正则）：
   > 交接产物中的 git diff 在写入前必须过脱敏规则。

   | 类别 | 检测模式 | 替换 |
   |------|---------|------|
   | 凭证 | API Key / OAuth Secret / JWT Token / 私钥文件 | `[REDACTED:CREDENTIAL]` |
   | 个人信息 | 手机号 / 身份证号 / 邮箱 | `[REDACTED:PII]` |
   | 内部资产 | 内网 IP / 私有域名 / 数据库连接串 | `[REDACTED:INTERNAL]` |
   | 云厂商凭证 | AccessKey / GitHub Token / ARN | `[REDACTED:CLOUD_KEY]` |

   命中即替换（不可逆），并在 Receipt 的 warnings 字段记录脱敏事件。

   **c) Project 知识沉淀扫描**（对照 new-chat-ready 的 Project MD Sync）：
   - 检查本会话是否产生了**可复用的项目知识**（非任务临时状态）
   - 稳定的系统级经验、重复的用户纠正 → 建议写入 AGENTS.md 或 PROJECT_MEMORY.md
   - 向用户报告：Synced / Candidates not synced / Skipped

   **d) 恢复命令序列** (新会话的第一条指令)：
   ```bash
   # 新会话恢复序列（粘贴到新会话的第一条消息）
   请先执行 /resume，然后读取以下文件：
   1. [handoff-context.md 路径] — 先看 L0 核心摘要
   2. [task.md 路径]
   3. [关键代码文件]
   当前在 [branch] 分支，Phase [X]，下一步是 [具体动作]。
   ```

// turbo
5.5 **执行会话结束钩子**
   ```bash
   bash .agent/scripts/session-end.sh
   ```
   自动保存 auto-checkpoint。

6. **交接确认**
   - **必须**将交接备忘录保存到项目磁盘中（**禁止**仅在对话中输出而不写入文件）
   - 提示用户：在新会话中使用 `/resume` 即可安全恢复

如果阻塞，可求助 `/debug` 流程。
