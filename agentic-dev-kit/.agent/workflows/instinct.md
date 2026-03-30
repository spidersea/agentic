---
description: 本能管理 — 查看、导入、导出、清理本能
---

# 本能管理

> 管理持续学习系统中的本能（instinct）数据。
> 触发方式: `/instinct [子命令]`
> 前置技能: `.agent/skills/continuous-learning/SKILL.md`

## 子命令

### `/instinct status` — 查看本能状态

// turbo
1. 读取本能文件：
   ```bash
   cat .agent/instincts/pending.yml 2>/dev/null || echo "暂无本能数据"
   cat .agent/instincts/promoted.yml 2>/dev/null
   ```

2. 输出状态报告：
   ```markdown
   ## 本能状态
   - **活跃本能**: [N 条]
   - **已升级**: [M 条]
   - **按类别分布**:
     | 类别 | 数量 | 最高置信度 |
     |---|---|---|
     | code-quality | X | Y |
     | testing | X | Y |
     | ... | ... | ... |
   - **候选升级** (confidence≥4):
     - [本能 pattern + confidence]
   - **指引**: [如需升级，运行 /evolve]
   ```

---

### `/instinct import <file>` — 导入本能

1. 读取指定的 YAML 文件
2. 验证格式正确性（必须有 pattern, category, confidence 字段）
3. 与本地本能去重（语义相同的 pattern → 跳过或合并）
4. 导入的本能 confidence 重置为 1（需要在本项目中重新验证）
5. 追加到 `.agent/instincts/pending.yml`
6. 报告导入结果

---

### `/instinct export` — 导出本能

// turbo
1. 导出所有活跃本能：
   ```bash
   mkdir -p .agent/instincts/exported
   cp .agent/instincts/pending.yml ".agent/instincts/exported/instincts-$(basename $(pwd))-$(date +%Y%m%d).yml"
   ```
2. 告知用户导出路径

---

### `/instinct prune` — 清理过期本能

// turbo
1. 读取 `.agent/instincts/pending.yml`
2. 标记以下条目为 `pruned`：
   - 创建超过 60 天且 confidence ≤ 2
   - 状态为 `expired`
3. 将被清理的条目移动到归档（或直接移除）
4. 报告清理结果：
   ```markdown
   ## 本能清理报告
   - **清理前**: [N 条活跃本能]
   - **清理后**: [M 条活跃本能]
   - **移除**: [列表 + 原因]
   ```

如果阻塞，可求助 `/debug` 流程。
