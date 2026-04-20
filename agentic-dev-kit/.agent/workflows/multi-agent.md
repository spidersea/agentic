---
description: 多 Agent 编排工作流 — 将大任务拆解为 Lead + Teammates 并行协作架构
---

# 多 Agent 编排工作流

> 触发方式: `/multi-agent`
>
> 将跨模块任务拆解为多个 Teammate Agent 并行/有序执行，Lead 负责分派、监控、合并和验收。
> 本流程调用 `.agent/skills/multi-agent/SKILL.md` 的架构和协议，执行细节见 `references/multi-agent-orchestration.md`。
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
- 【预检策略】：检测任意两任务 Glob 交集。交集文件>2 的任务直接判定为**不可并行**，强制建立串行链并记录，否则合并阶段会严重爆炸。详细算法见 `references/multi-agent-orchestration.md`。

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
