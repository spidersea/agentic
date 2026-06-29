---
description: 多 Agent 编排工作流 — 将大任务拆解为 Lead + Teammates 并行协作架构，含冲突感知协议
---

# 多 Agent 编排工作流

> 触发方式: `/multi-agent`
>
> 将跨模块任务拆解为多个 Teammate Agent 并行/有序执行，Lead 负责分派、监控、合并和验收。
> 本流程调用 `.agent/skills/multi-agent/SKILL.md` 的架构和协议，执行细节见 `.agent/workflows/references/multi-agent-orchestration.md`。
>
> **与 `/new-feature` 关系**: 它是 `/new-feature` Phase 3 的**执行策略选项**。单Agent足够时切勿启动。

---

## 前置条件 & 适用性 (Step 1)
- Phase 1 调研完成并产出精确规格。
- **适用信号**: 修改独立模块数≥3；模块低耦合可解耦；C+T 存在并行收益。如不满足，回退单体。

## 0. 终点契约（防断层打卡）
第一秒钟，在 `task.md` 建立追溯检查表：
```markdown
### /multi-agent 编排流
- [ ] 0/1. 终点契约 + 适用性判定
- [ ] 2. 任务拆解(DAG) + 冲突检测
- [ ] 3. 初始化(Worktree/看板)
- [ ] 4. 下发执行 (按平台Level)
- [ ] 5. 合并组装 (Message+Git)
- [ ] 6. 全局查验 (Review/Crosstest)
- [ ] 7. 现场回收 (归档清理)
```
必须打满 `[x]` 才可宣布完成。

---

## 2. 结构化拆解与防撞 (DAG / Conflict)
- 将任务拆为不可拆的基元 (5-15mins)。每个包分配角色 (Coder/Tester 等)、独立 glob 边界。
- 构建 `depends_on` 形成的 DAG，无依赖直接丢入等待池，循环依赖直接报错退回。
- 【预检策略】：检测任意两任务 Glob 交集。交集文件>2 的任务直接判定为**不可并行**，强制建立串行链并记录，否则合并阶段会严重爆炸。详细算法见 `.agent/workflows/references/multi-agent-orchestration.md`。

---

## 3. 部署独立空间 (Init)
1. 为写入 Teammate 创建分支与子层工作树 (`git worktree add`)。
2. 创建信使通道 `<.agent/state/agent-messages/>`。
3. 创建中央调度看板 `orchestration.md` (存放在状态信使目录下) 维护 Task IDs 和依赖图谱。

---

## 4. 平台级分派决策 (Dispatch)

> **降级路由**: 根据当前终端环境能力自动适配
- **Level 0 (原生 spawn)**: Lead 动态孕育子进程度过孤立会话，子体存入独立文件栈。
- **Level 1 (多窗人工)**: Lead 指引用户开多终端派发 Prompt 字符串给子会话。
- **Level 2 (单轨降级)**: Antigravity/Cursor 等环境采用角色串行切换法。即通过模拟拓扑执行序列顺次扮演各个子 Agent。（必须强制“心理重置”并读角色文档）。

*(详见 reference: 3. 三级分派策略详细指令)*

---

## 4.5 冲突感知协议 (Conflict-Aware Protocol)
> 对照 ATA「whocoding 谁也在码」和「agent-handoff」Skill 原始内容校准：
> - whocoding: **自动触发** (修改已有函数/核心模块时强制触发，非人工启动)
> - whocoding: **4 级风险分级** (none/low/medium/high，不同级别不同决策)
> - whocoding: **行级 blame 考古** (识别 Bug Fix/Hotfix 防御逻辑，防误删)
> - whocoding: **关联文件溯源** (上次提交时共同改动的文件，防漏改)
> - whocoding: **活跃分支 4 维过滤** (时效/相关/命名/MR 状态)

### 自动触发规则（对照 whocoding 强制触发）
以下场景**自动**执行冲突检测，无需用户显式请求：
- Teammate 要修改一个已存在的函数/方法/类
- 目标文件是核心公共模块（Service 层、工具类、接口定义、配置文件）
- 当前 session 中已经修改过至少一个文件（多步骤任务）

### 实时冲突探测
- **文件锁注册**: 每个 Teammate 开始工作前，在 `.agent/state/agent-messages/locks.json` 注册自己的**写入文件集**
- **冲突矩阵检查**: Lead 每次派发新任务前，与已有锁集做交集检查
  - 交集为空 → 可并行
  - 交集 ≤2 文件 → 标记为 CAUTION，串行化冲突文件的写入
  - 交集 >2 文件 → 强制串行，任务退回重新排序

### 4 级风险评估（对照 whocoding 风险分级）
| 风险 | Agent 决策 |
|------|-----------|
| **none** | 直接执行 |
| **low** | 正常执行，日志记录 |
| **medium** | 附带规避建议执行，Lead 审核 |
| **high** | 采用规避策略后执行，需 Lead 确认 |

### 行级 blame 考古（对照 whocoding 核心特性）
> 核心观察：修改一行代码前，必须知道**这行代码为什么在这里**。
- 对每个被修改的代码段，执行 `git blame` 检查历史
- 识别 **Bug Fix / Hotfix 防御逻辑**（commit 消息含 fix/hotfix/bugfix）
- 如果目标行段是之前的 Bug Fix → 标记为高风险，Teammate 必须保留该逻辑或提供替代防御
- 识别行段的原始作者和修改频率

### 关联文件溯源（对照 whocoding 防漏改）
- 对每个被修改的文件，检查**上次提交时共同改动的其他文件**
- 如果存在关联文件 → 提示 Teammate 检查是否需要同步更新
- 防止"改了 Service 忘了改 DTO"、"改了接口忘了改实现"的漏改问题

### 语义冲突检测（超越文件级）
- 检测**接口契约冲突**: Agent A 修改了函数签名，Agent B 调用了旧签名
- 检测**状态流冲突**: Agent A 修改了数据模型，Agent B 依赖旧模型的字段
- 检测方式: 合并前 Lead 执行 `grep -rn` 扫描被修改函数/类的调用方

### 冲突解决优先级
1. **数据模型变更** → 模型修改方优先，调用方适配
2. **公共 API 变更** → 先合并 API 变更，后合并调用方
3. **配置文件冲突** → Lead 手动合并，不自动处理
4. **测试文件冲突** → 合并所有测试，取并集

---

## 5. 控制并与 Git 缝合 (Merge)
- Lead 开启事件轮询，检查 `agent-messages/` 目录中状态 (`completed/failed/blocked`)。
- 当上游节点完成后，通过信号灯唤醒阻塞节点。
- 所有末端收敛后，切换到 Base，按照 DAG **前序拓扑顺序逐一 git merge 子 worktree 分支**。
- 遇重大冲突由 Lead 冻结合并分析。

---

## 6. 集成审判门 (Check & /review)
合并并非胜利，合并仅为开始：
1. **全局回溯**: 必须在合并后的混合体上执行 `Make test / QA`，不能依靠单个 Agent 独立测试成绩。
2. **影响面检查**: 过回归用例。
3. **一致性 Review**: `/review` 强制入场，审计：跨节点的接口连贯性，命名漂移，死代码遗留物。
   * -> VERDICT: FAIL 摘出故障点回分派。 -> PASS 进入回收。

---

## 7. 打扫战场 (GC & Learn)
- 卸载所有临时挂载的 `git worktree remove`，抹除分支。
- 日志文件归档移入 `archive` 腾空信使目录。
- 如发生典型经验（拆解失误、高级降级模式），开启 `/learn` 抓取进入体系库。

---

### 系统禁令 (Red Lines)
❌ 在可单 Agent 搞定的小功能内强开体系
❌ 未做全局 Glob 互斥检查便派发（导致合并爆炸）
❌ Teammate 越过 worktree 进行读写污染
❌ 跳过整体合入后的全量验证
❌ 未注册文件锁就开始并行写入（冲突感知协议）
❌ 合并时跳过语义冲突检测（接口/状态流）
