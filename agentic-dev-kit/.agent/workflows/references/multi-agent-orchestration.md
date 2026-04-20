---
description: 多Agent工作流编排细节 (从 multi-agent.md 抽离加载)
---

# 多 Agent 编排细节 (Orchestration Details)

> 此文件保存 `/multi-agent` 工作流相关的执行细则和代码，在主流程运转到对应生命周期时查阅。

## 1. 任务拆解与冲突预检代码

**子任务 JSON 模板：**
```json
{
  "role": "Coder | Tester | Explorer | Reviewer",
  "scope": "src/api/**/*.ts",
  "validation_command": "npm test",
  "context": ["file1", "file2"],
  "prohibited": ["core/kernel.ts"],
  "depends_on": ["task-001"],
  "blocks": ["task-005"]
}
```

**冲突预检 (交集检测逻辑)：**
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
- 无交集: ✅ 可并行
- 交集 ≤ 2 个文件: ⚠️ 串行执行，先完成的合并后再启动后续
- 交集 > 2 个文件: ❌ 重新拆解子任务，消除交集

---

## 2. 环境部署命令

**Git Worktree 与消息存储：**
```bash
# 写入型 Teammate (Coder/Tester) 独立 worktree
git worktree add .worktrees/task-001-coder -b agent/task-001
mkdir -p .agent/state/agent-messages
```

**orchestration.md 看板模板:**
```markdown
---
workflow: multi-agent
total_tasks: 3
platform_level: Level 1
---
| Task ID | 角色 | Status | depends_on | Worktree |
|---------|------|--------|------------|----------|
| task-001 | Coder | pending | - | .worktrees/task-001-coder |
```

---

## 3. 三级分派策略详细指令

### Level 0: 原生并行 (Claude Code Agent Teams)
Lead 直接 spawn 独立 Teammate Agent。隔离：写入型在独立 worktree，只读型在独立上下文。产出报告写入 `agent-messages/`。

### Level 1: 手动并行 (多终端)
Lead 产出新终端控制指令：
```text
终端 A (task-003):
cd .worktrees/task-003-coder
"你是 Coder Agent。读取 .agent/agents/coder.md。控制范围 [scope]。完成后写报告到 ../.agent/state/agent-messages/..."
```

### Level 2: 串行角色切换 (单会话如 Antigravity / Cursor)
**角色切换协议**:
1. 清空心理偏见 (认知重启)
2. 读取目标角色的 Agent 定义
3. 严格遵循约束执行子任务
4. 产出报告到 `agent-messages/`
5. 切回 Lead，接管评估。

---

## 4. 合并与清理实操

**分层 Git 合并:**
```bash
git checkout <基础分支> && git pull
# 按DAG序列按序合并
git merge agent/task-001 --no-ff -m "multi-agent: merge task-001"
git merge agent/task-002 --no-ff -m "multi-agent: merge task-002"
```

**状态重置:**
```bash
# Worktree 回收
git worktree remove .worktrees/task-001-coder
git branch -d agent/task-001

# 消息归档
mkdir -p .agent/state/agent-messages/archive/$(date +%Y%m%d)
mv .agent/state/agent-messages/task-*.md .agent/state/agent-messages/archive/$(date +%Y%m%d)/
rm .agent/state/orchestration.md
```
