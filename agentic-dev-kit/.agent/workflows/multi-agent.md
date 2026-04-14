---
description: 多 Agent 编排工作流 — 将大任务拆解为 Lead + Teammates 并行协作架构
---

# 多 Agent 编排工作流

> 触发方式: `/multi-agent`
>
> 将跨模块任务拆解为多个 Teammate Agent 并行/有序执行，Lead 负责分派、监控、合并和验收。
> 本流程调用 `.agent/skills/multi-agent/SKILL.md` 中定义的架构和协议。
>
> **与 `/new-feature` 的关系**: `/multi-agent` 不替代 `/new-feature`。它是 `/new-feature` Phase 3 的**一种执行策略** —
> 当任务拆解后子任务间可并行时，Lead 可选择在 Phase 3 内启动 `/multi-agent` 编排。
> 单Agent足够时不要使用本流程（overhead > 收益）。

---

## 前置条件

- Phase 1 调研完成，有精确的技术规格或 openspec 产物
- 任务涉及 ≥ 3 个独立模块的修改，或需要并行审查/测试

## 步骤

### 0. 终点契约（强制打卡）

> ⛔ 与 `/new-feature` 相同的防御机制：对抗注意力衰减与产物断裂。

收到 `/multi-agent` 的**第一秒钟**，在 `task.md` 中创建以下打卡项：

```markdown
### /multi-agent 工作流
- [ ] Step 1: 适用性判断 — 确认多Agent优于单Agent
- [ ] Step 2: 任务拆解 + 依赖DAG + 冲突预检
- [ ] Step 3: 环境准备 — worktree + 消息目录
- [ ] Step 4: 分派执行 — 按平台能力选择并行策略
- [ ] Step 5: 监控合并 — 轮询消息 + git merge
- [ ] Step 6: 统一验收 — 全量验证 + /review
- [ ] Step 7: 清理收尾 — worktree remove + 消息归档
```

除非所有项全部标记 `[x]`，否则**绝对不可**自行宣告完成。

---

### 1. 适用性判断

读取 `.agent/skills/multi-agent/SKILL.md` §7（适用场景判断），对照当前任务进行评估：

| 信号 | 适合多Agent | 不适合 |
|---|---|---|
| 修改模块数 | ≥ 3 个独立模块 | ≤ 2 个文件 |
| 模块间耦合 | 低耦合，可独立编码/测试 | 高耦合，改一处牵一片 |
| 并行收益 | Coder+Tester 可同时工作 | 必须严格串行 |
| 平台支持 | 有 subagent spawn 能力 | 完全无并行手段 |

**决策输出**:
```
适用性判断: ✅ 启动多Agent编排
理由: [具体说明为什么多Agent优于单Agent]
预计 Teammate 数量: [N]
平台降级级别: Level 0/1/2 (参见 platform-adapters.md)
```

如果判断**不适合**，退出本流程，回退到单Agent `/new-feature` Phase 3。

---

### 2. 任务拆解与依赖分析

#### 2.1 子任务拆解

按 `multi-agent/SKILL.md` §3 的模板，将大任务拆分为子任务。每个子任务**必须包含**：

```markdown
## 子任务: [编号]-[名称]

- **分派角色**: Coder | Tester | Explorer | Reviewer | Adversary
- **作用域**: [文件 glob，如 `src/api/**/*.ts`]
- **验收条件**: [可机械验证的条件]
- **上下文依赖**: [需要先读哪些文件]
- **禁止修改**: [不允许触碰的文件列表]
- **depends_on**: [前置子任务 ID 列表，无依赖则为空]
- **blocks**: [被本任务阻塞的后续子任务 ID 列表]
- **优先级**: P0 | P1 | P2
- **预估复杂度**: 简单(5min) | 中等(10min) | 复杂(15min)
- **escalation 继承**: [当前 Lead 的 esc_level]
```

**拆解约束**:
- 每个子任务 5-15 分钟可完成（超过则继续拆）
- 验收条件必须机械化（exit_code / test pass / lint clean）
- 每个子任务的 scope glob 不可与其他子任务重叠（除非标记为串行）

#### 2.2 依赖 DAG 构建

将所有子任务的 `depends_on` 关系构建为有向无环图（DAG）：

```
task-001 (Explorer 调研) ──┐
                           ├──► task-003 (Coder 实现A)  ──┐
task-002 (Tester 写测试) ──┘                               ├──► task-005 (Reviewer 审查)
                           ┌──► task-004 (Coder 实现B)  ──┘
                           │
task-001 ──────────────────┘
```

**拓扑排序调度规则**:
1. 无前置依赖的任务 → 立即并行分派
2. 有前置依赖的任务 → 等待前置任务 `status: completed` 后再分派
3. 检测到循环依赖 → **立即停止**，报告给用户，重新拆解

#### 2.3 冲突预检

分派前，Lead **必须**执行 scope 交集检测：

```bash
# 伪代码：检测任意两个子任务的 scope 是否有文件交集
for each pair (task_i, task_j):
    files_i = glob(task_i.scope)
    files_j = glob(task_j.scope)
    overlap = files_i ∩ files_j
    if overlap is not empty:
        mark (task_i, task_j) as SERIAL_CONSTRAINT
        log "⚠️ task_i 和 task_j 存在作用域交集: {overlap}"
```

**冲突处理策略**:
| 交集情况 | 处理方式 |
|---|---|
| 无交集 | ✅ 可并行 |
| 交集 ≤ 2 个文件 | ⚠️ 串行执行，先完成的合并后再启动后续 |
| 交集 > 2 个文件 | ❌ 重新拆解子任务，消除交集 |

---

### 3. 环境准备

#### 3.1 创建 Git Worktree（写入型 Teammate）

```bash
# 为每个写入型 Teammate (Coder/Tester) 创建独立 worktree
git worktree add .worktrees/task-001-coder -b agent/task-001
git worktree add .worktrees/task-002-tester -b agent/task-002
```

#### 3.2 创建消息目录

```bash
mkdir -p .agent/state/agent-messages
```

#### 3.3 创建编排状态文件

在 `.agent/state/orchestration.md` 中记录当前编排状态：

```markdown
---
workflow: multi-agent
total_tasks: [N]
platform_level: Level 0|1|2
started_at: [ISO时间]
---

## 任务状态看板

| Task ID | 角色 | Status | depends_on | Worktree |
|---------|------|--------|------------|----------|
| task-001 | Explorer | pending | - | - |
| task-002 | Tester | pending | - | .worktrees/task-002-tester |
| task-003 | Coder | blocked | task-001 | .worktrees/task-003-coder |
```

---

### 4. 分派执行

> ⚠️ **平台降级感知**: 按 `platform-adapters.md` 中的多Agent适配级别选择执行策略。

#### Level 0: 原生并行（Claude Code Agent Teams）

Lead 直接 spawn 独立 Teammate Agent，每个 Teammate：
- 接收：子任务描述 + 必要上下文文件路径 + Agent prompt（`.agent/agents/{role}.md`）
- 隔离：写入型在独立 worktree，只读型在独立上下文
- 产出：完成报告写入 `.agent/state/agent-messages/task-{N}-{role}.md`

#### Level 1: 手动并行（多终端/多窗口环境）

Lead 指引用户操作：
```
请在新终端中执行以下操作（可并行打开多个）：

终端 A - Coder (task-003):
  cd .worktrees/task-003-coder
  # 将以下内容作为初始 prompt 发送给 AI：
  "你是 Coder Agent。请阅读 .agent/agents/coder.md 理解你的角色约束。
   你的任务是: [子任务描述]
   作用域: [scope glob]
   验收命令: [验收命令]
   完成后将报告写入 ../.agent/state/agent-messages/task-003-coder.md"

终端 B - Tester (task-002):
  cd .worktrees/task-002-tester
  # [类似指引]
```

#### Level 2: 串行角色切换（单会话环境 — Antigravity/Cursor/Aider）

Lead 在单会话内按拓扑排序**串行**执行每个子任务：

```
执行序列（按 DAG 拓扑序）:

Round 1 — 无依赖任务（可"模拟并行"即连续执行）:
  ① 切换为 Explorer 角色 → 执行 task-001 → 产出报告
  ② 切换为 Tester 角色  → 执行 task-002 → 产出报告

Round 2 — 依赖已满足的任务:
  ③ 读取 task-001 报告 → 切换为 Coder 角色 → cd .worktrees/task-003-coder → 执行 task-003
  ④ 切换为 Coder 角色 → cd .worktrees/task-004-coder → 执行 task-004

Round 3 — 最终审查:
  ⑤ 切换为 Reviewer 角色 → 执行 task-005
```

**角色切换协议**:
1. 清空当前角色的上下文偏见（心理重置）
2. 读取目标角色的 Agent 定义（`.agent/agents/{role}.md`）
3. 读取子任务描述和上下文依赖
4. 执行子任务，严格遵守角色的权限约束
5. 产出报告到 `.agent/state/agent-messages/`
6. 切换回 Lead 角色，评估结果

> ⚠️ 角色切换时 **禁止** 携带前一角色的未验证假设。每次切换都是一次认知重启。

---

### 5. 监控合并

#### 5.1 状态轮询

Lead 定期（每个 Teammate 完成后，或 Level 2 下每个 Round 结束后）检查消息目录：

```bash
ls -la .agent/state/agent-messages/
```

读取每个完成报告的 frontmatter：
- `status: completed` → 检查验收结果，准备合并
- `status: failed` → 检查 esc_level，决定重新分派或 Lead 接管
- `status: blocked` → 检查阻塞原因，解除阻塞或调整 DAG

#### 5.2 依赖信号传导

当 task-A 完成且 task-B `depends_on: [task-A]` 时：
1. Lead 读取 task-A 的完成报告
2. 确认 task-A 验收通过
3. 更新 `orchestration.md` 状态看板
4. 分派 task-B（或在 Level 2 下进入下一 Round）

#### 5.3 接口变更通知

如果 Teammate 修改了公共接口（函数签名、API schema、类型定义）：
1. Teammate 在报告中 `### 接口变更` 段落显式声明
2. Lead 检查是否有其他子任务依赖该接口
3. 如有 → 通知受影响的 Teammate 或在 Level 2 下在后续 Round 中注入变更信息

#### 5.4 Git 合并

所有 Teammate 完成后，Lead 按以下顺序合并：

```bash
# 1. 确保主分支是最新的
git checkout <基础分支>
git pull

# 2. 按拓扑排序中最先完成的顺序逐个合并
git merge agent/task-001 --no-ff -m "multi-agent: merge task-001 (explorer)"
git merge agent/task-003 --no-ff -m "multi-agent: merge task-003 (coder-A)"
git merge agent/task-004 --no-ff -m "multi-agent: merge task-004 (coder-B)"

# 3. 如有冲突
# → 分析冲突范围
# → 简单冲突：Lead 直接解决
# → 复杂冲突：委派 Explorer 分析后 Lead 决策
```

---

### 6. 统一验收

合并完成后，**在合并后的代码上**执行完整验证（不是在各自 worktree 中的孤立验证）：

#### 6.1 全量测试

```bash
# 运行项目完整测试套件
<项目测试命令>  # npm test / pytest / cargo test / etc.
```

所有子任务的验收命令都必须在合并后重新执行一遍，确认集成后仍然通过。

#### 6.2 回归检查

确认合并未引入回归：
- 合并前已有的测试全部通过
- 如有代码图谱：执行 `get_impact_radius` 检查影响范围

#### 6.3 对抗式审查

强制执行 `/review`，审查重点：
- 跨子任务的**接口一致性**（A 改了函数签名，B 的调用方是否同步？）
- 跨子任务的**命名一致性**（A 用 `userId`，B 用 `user_id`？）
- 合并后的**死代码**（A 删了某函数，B 还在用？）

#### 6.4 裁定

```
## VERDICT: PASS | FAIL | PARTIAL
- integration_tests: ✅/❌ [命令 + 输出]
- regression_tests:  ✅/❌ [命令 + 输出]
- cross_task_review: ✅/❌ [发现的跨任务问题数]
- interface_consistency: ✅/❌ [检查结果]
```

- VERDICT=FAIL → 定位失败的子任务 → 重新分派修复（单个 Teammate 修复，无需全部重来）
- VERDICT=PASS → 进入清理

---

### 7. 清理收尾

#### 7.1 Worktree 清理

```bash
# 列出所有工作树
git worktree list

# 逐个清理
git worktree remove .worktrees/task-001-coder
git worktree remove .worktrees/task-002-tester
# ...

# 清理远程跟踪分支（可选）
git branch -d agent/task-001 agent/task-002 agent/task-003
```

#### 7.2 消息归档

```bash
# 将消息移动到归档目录（保留审计轨迹）
mkdir -p .agent/state/agent-messages/archive/$(date +%Y%m%d)
mv .agent/state/agent-messages/task-*.md .agent/state/agent-messages/archive/$(date +%Y%m%d)/

# 清理编排状态文件
rm .agent/state/orchestration.md
```

#### 7.3 经验提取

如果编排过程中出现以下情况，触发 `/learn` 提取经验：
- 某个拆解模式特别高效 → 记录为模式
- 某种冲突反复出现 → 记录为避坑经验
- 平台降级策略的实际效果 → 记录反馈

#### 7.4 链接 `/finish`

执行 `/finish` 完成最终的分支收尾（merge/PR/keep/discard）。

---

## 禁止事项

- ❌ 单 Agent 足够时启动多 Agent 编排（overhead > 收益）
- ❌ 未做冲突预检就并行分派（合并时炸裂）
- ❌ Teammate 跨 worktree 写入（隔离被破坏）
- ❌ Lead 盲信 Teammate 的 `status: completed`（必须运行验收命令确认）
- ❌ 跳过合并后的统一验收（孤立通过 ≠ 集成通过）
- ❌ 忘记清理 worktree（磁盘泄漏）

## 与现有流程的关系

| 流程 | 关系 |
|------|------|
| `/new-feature` | 多Agent是 Phase 3 的一种执行策略选项，不替代 `/new-feature` |
| `/review` | Step 6 强制调用 `/review` 进行跨任务一致性审查 |
| `/finish` | Step 7 链接 `/finish` 完成分支收尾 |
| `/checkpoint` | 每个 Step 完成后建议执行 `/checkpoint` |
| `escalation` | Teammate 继承 Lead 的 esc_level；Teammate 超过 L3 交回 Lead |
| `agent-dsl` | `/dsl --multi-agent` 可自动触发本工作流 |

## 自动化合规验证
可以使用如下命令验证当前环境状态：
```bash
bash .agent/scripts/health-check.sh .
```
