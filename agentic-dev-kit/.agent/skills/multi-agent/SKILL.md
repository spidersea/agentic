---
name: multi-agent
description: |
  多 Agent 编排协议 — 将单 Agent 角色扮演升级为真正的多 Agent 并行协作。
  定义 Lead/Teammate 架构、git worktree 隔离、任务分解模板、消息传递协议。
  对齐 Claude Code Agent Teams 能力，同时保留 escalation/autoresearch/Polanyi 行为约束。
version: 1.0.0
---

# 多 Agent 编排协议 (Multi-Agent Orchestration)

> 灵感来源：Claude Code Agent Teams（2026-02）— Lead + Teammates 并行协作架构。
> 核心升级：从"单 Agent 内部角色切换"升级为"多个独立 Agent 并行工作 + 结构化协调"。

---

## 1. 编排架构

```
Lead Agent (主控)
├── 任务分解 → 子任务清单
├── 分派 → Teammate Agents（并行）
├── 监控 → 进度 + 失败检测
├── 合并 → git merge + 冲突解决
└── 验收 → /review 质量门

Teammate Agents (执行者)
├── Coder    — 功能实现（Read + Write + Execute）
├── Tester   — 测试编写与执行（已有 agents/tester.md）
├── Reviewer — 对抗审查（已有 agents/reviewer.md）
├── Explorer — 调研探索（已有 agents/explorer.md）
└── Adversary — 红队攻击（已有 agents/adversary.md）
```

### 角色矩阵

| 角色 | 职责 | 工具权限 | 隔离方式 | 对应文件 |
|------|------|---------|---------|---------|
| **Lead** | 任务分解、分派、合并、质量审查 | Full | 主分支 | 当前会话的主 Agent |
| **Coder** | 功能实现、重构、Bug 修复 | Read + Write + Execute | git worktree | `agents/coder.md` |
| **Tester** | 测试编写与执行 | Read + Write (test/) + Execute | git worktree | `agents/tester.md` |
| **Explorer** | 调研、文档、上下文收集 | ReadOnly | 独立上下文 | `agents/explorer.md` |
| **Reviewer** | A/B/C 对抗审查 | ReadOnly | 独立上下文 | `agents/reviewer.md` |
| **Adversary** | 红队攻击 | ReadOnly (L5 可升级) | 独立上下文 | `agents/adversary.md` |

---

## 2. 隔离原则

### 2.1 Git Worktree 隔离（Coder/Tester）

写入型 Teammate 必须在独立 git worktree 中工作：

```bash
# Lead 在分派前创建 worktree
git worktree add .worktrees/coder-task-N -b agent/coder-task-N
git worktree add .worktrees/tester-task-N -b agent/tester-task-N
```

**规则**：
- 每个 Teammate 只能修改自己 worktree 内的文件
- Teammate 之间不可跨 worktree 写入
- 完成后由 Lead 执行 `git merge` + 冲突解决
- worktree 在任务完成且合并后清理：`git worktree remove .worktrees/xxx`

### 2.2 上下文隔离（Explorer/Reviewer/Adversary）

只读型 Teammate 通过独立上下文（subagent 调用）隔离：
- 每个 subagent 收到的 prompt 包含：任务描述 + 必要上下文文件路径
- subagent 的输出写入 `.agent/state/agent-messages/` 供 Lead 读取
- subagent 不继承 Lead 的上下文窗口状态

### 2.3 .gitignore 约定

```gitignore
# Multi-Agent worktrees（不入库）
.worktrees/
.agent/state/agent-messages/
```

---

## 3. 任务分解模板

Lead 将大任务分解为子任务时，每个子任务**必须包含**以下结构：

```markdown
## 子任务: [编号]-[名称]

- **分派角色**: Coder | Tester | Explorer | Reviewer | Adversary
- **作用域**: [文件 glob，如 `src/api/**/*.ts`]
- **验收条件**: [可机械验证的条件，如 `npm test -- --grep "auth" 通过`]
- **上下文依赖**: [需要先读哪些文件，列出路径]
- **禁止修改**: [不允许触碰的文件列表]
- **优先级**: P0 | P1 | P2
- **预估复杂度**: 简单 | 中等 | 复杂
- **escalation 继承**: [当前 Lead 的 esc_level，Teammate 继承此等级作为起始压力]
```

### 分解原则

1. **每个子任务 5-15 分钟可完成** — 超过 15 分钟的任务继续拆分
2. **验收条件必须机械化** — 使用 exit_code / test pass / lint clean，禁止"看起来不错"
3. **声明依赖顺序** — 如果子任务 B 依赖子任务 A 的输出，必须标明（使用下方 §3.5 的 `depends_on` 字段）
4. **禁止修改清单** — 防止 Coder 越界修改不该改的文件（对齐 Guard 概念）

---

## 3.5 依赖协调协议 (Dependency Coordination)

> 当子任务之间存在依赖关系时，Lead 必须遵循本协议确保执行有序、冲突可控。

### 3.5.1 子任务依赖声明

在 §3 的子任务模板中追加以下字段：

```markdown
- **depends_on**: [前置子任务 ID 列表，无依赖则为 `[]`]
- **blocks**: [被本任务阻塞的后续子任务 ID 列表]
```

### 3.5.2 拓扑排序调度

Lead 按依赖 DAG 的拓扑排序分派子任务：

1. **Wave 0**：所有 `depends_on: []` 的子任务 → 立即**并行**分派
2. **Wave N**：前置依赖全部 `status: completed` 的子任务 → 解除阻塞，分派执行
3. **死锁检测**：如果检测到循环依赖（A→B→C→A）→ **立即停止**，报告用户重新拆解

```
示例 DAG:

Wave 0:  task-001 (Explorer)   task-002 (Tester)
              │                      │
              ▼                      │
Wave 1:  task-003 (Coder A)          │
              │                      ▼
              ▼               task-004 (Coder B)
Wave 2:  task-005 (Reviewer) ◄───────┘
```

### 3.5.3 冲突预检

Lead 在分派前**必须**检测所有子任务的作用域是否有文件交集：

| 交集情况 | 处理方式 |
|---|---|
| 无交集 | ✅ 可并行分派 |
| 交集 ≤ 2 个文件 | ⚠️ 标记**串行约束**：按 DAG 顺序先后执行，不可并行 |
| 交集 > 2 个文件 | ❌ 拆解失败：退回重新拆分子任务，消除交集后重试 |

### 3.5.4 阻塞等待与信号传导

消息 frontmatter 增加等待状态：

```markdown
---
from: coder
task_id: task-003
status: waiting
waiting_for: [task-001]
---
```

**Lead 轮询协议**：
1. 读取消息目录中所有 `status: completed` 的报告
2. 对照 `orchestration.md` 状态看板，找出已解除阻塞的后续任务
3. 分派解除阻塞的任务（Level 0/1 下 spawn；Level 2 下进入下一 Round）

### 3.5.5 增量接口变更通知

当 Teammate 修改了公共接口（函数签名变更、API schema 变更、类型定义变更），必须在完成报告中**显式声明**：

```markdown
### 接口变更（⚠️ 需通知依赖方）
- `src/api/auth.ts`: `login(email, password)` → `login(credentials: LoginCredentials)`
- 影响范围: 所有调用 `login()` 的模块
```

Lead 在收到含接口变更的报告后：
1. 检查 `blocks` 字段，确定受影响的后续子任务
2. 向受影响子任务的 Teammate 注入接口变更信息（Level 0/1 通过消息文件；Level 2 在下一 Round 前置读取）
3. 如果已完成的子任务使用了旧接口 → Lead 标记该子任务为**需修复**，重新分派

---

## 4. 消息传递协议

Teammate 之间不共享上下文窗口，通过文件系统传递消息：

### 4.1 消息目录结构

```
.agent/state/agent-messages/
├── task-001-coder.md        # Coder 的完成报告
├── task-002-tester.md       # Tester 的测试结果
├── task-003-explorer.md     # Explorer 的调研报告
├── review-round-1.md        # Reviewer 的审查报告
└── adversary-attack.md      # Adversary 的攻击报告
```

### 4.2 消息格式

```markdown
---
from: coder
task_id: task-001
status: completed | failed | blocked
esc_level: L0
---

## 完成报告

### 修改的文件
- `src/api/auth.ts` (新增 OAuth handler)
- `src/middleware/session.ts` (修改 session 生命周期)

### 验收结果
- [x] `npm test -- --grep "auth"` 通过 (exit_code=0)
- [x] `tsc --noEmit` 通过

### 未解决问题
[如有]

### 需要 Lead 决策的事项
[如有]
```

### 4.3 Lead 的合并协议

1. 读取所有 Teammate 的完成报告
2. 检查报告中的 status — 所有 `completed` 才可合并
3. 如有 `failed`：检查 esc_level → 决定是重新分派还是 Lead 亲自处理
4. 执行 `git merge` — 如有冲突，人工解决或使用 Explorer 辅助分析
5. 合并后运行全量验收（Guard 命令 + 全部子任务的验收条件）

---

## 5. 与现有流程的集成

| 现有流程 | 多 Agent 编排的增强 |
|---------|-------------------|
| **autoresearch** | Lead 可将迭代中的子任务分派给 Teammate 并行执行，加速循环 |
| **autoresearch:review** | Reviewer + Adversary 作为 Teammate 并行审查，替代串行的 A→B→C |
| **escalation** | Teammate 继承 Lead 的 esc_level；Teammate 失败时 Lead 收到失败信号并决定升级 |
| **agent-dsl** | DSL 编译时可指定 `--multi-agent` 修饰符，将大任务自动分解为多 Teammate 架构 |
| **Polanyi Protocol** | Lead 在分解任务前必须完成 Tacit Tradition Map；Teammate 在 prompt 中收到 TTM 摘要 |
| **hooks-lifecycle** | worktree 创建/销毁事件记录到 session-end 钩子的自动检查 |

---

## 6. 使用约束

1. **不是所有任务都需要多 Agent** — 简单任务（`--no-loop` 级）不要启动编排，overhead 不划算
2. **Lead 不能放弃控制** — Lead 负责所有合并和最终验收，不能盲目信任 Teammate 输出
3. **escalation 贯穿全局** — 如果多个 Teammate 同时失败，Lead 的 esc_level 取最高值
4. **worktree 清理** — 任务完成后必须清理 worktree，防止磁盘泄漏
5. **消息不替代验证** — Teammate 的 status=completed 只是声明，Lead 必须运行验收命令确认

---

## 7. 适用场景判断

| 场景 | 推荐模式 | 原因 |
|------|---------|------|
| 单文件 Bug 修复 | 单 Agent | 无需编排 overhead |
| 跨模块功能开发 | 多 Agent | Coder 写代码 + Tester 写测试 并行 |
| 大规模重构 | 多 Agent + Fan-out | 每个文件一个 Coder 实例 |
| 安全审计 | 单 Agent + Adversary 委派 | 已有成熟路径 |
| 架构评审 | Explorer + Reviewer 并行 | 调研和审查并行加速 |
