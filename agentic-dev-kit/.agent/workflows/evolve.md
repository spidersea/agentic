---
description: 规则进化与清理流程 — 定期整合规则，移除冲突和冗余
---

# 规则进化流程 (Spa Day)

> 定期清理 Rules、Skills 和 AGENT.md，防止规则膨胀导致 Agent 性能退化。
> 触发方式: `/evolve`
> 建议频率: 每 2-4 周执行一次，或当发现退化信号时立即执行。

## 退化信号（触发条件）

出现以下任一信号时，应执行本流程：
- Agent 开始忽略某些规则
- Agent 表现出矛盾行为（某些场景做A，某些场景做B）
- 规则总数超过 20 条
- Agent 需要读取超过 5 个 md 文件才能开始工作
- 同一类规则出现在多个文件中

## 步骤

// turbo
0. **运行定量健康检查**
   ```bash
   bash .agent/scripts/health-check.sh
   ```
   - 记录退出码和报告中的关键指标
   - 将指标作为后续清理的数据依据（哪些文件最大、总 token 多少）
   - **上下文重量检查**（防止 AGENT.md 和 openspec 积压）：
     ```bash
     # AGENT.md 行数（目标 <80 行有效内容）
     wc -l AGENT.md
     # openspec 未归档变更数（>5 个需考虑归档）
     ls openspec/changes/ 2>/dev/null | wc -l
     # 最大的 skill 文件（>400 行考虑拆分）
     find .agent/skills -name "SKILL.md" | xargs wc -l | sort -rn | head -5
     ```
     - AGENT.md > 200 行 → ⚠️ 超重，优先精简路由表（合并同类行、Tier 2 压缩）
     - openspec/changes/ > 5 个未归档 → ⚠️ 建议运行 `/spec:archive` 清理

// turbo
1. **回顾与反思 (Retrospective)**
   在清理规则前，先回顾近期使用情况：
   - 汇总近期 5-10 个会话中的高频问题和重复纠正
   - 识别反复出现的摩擦模式（如 Agent 反复犯同一类错误）
   - 将高频问题提炼为新规则或技能优化项
   - 标记已被自动化或产品更新解决的旧摩擦点（待淘汰）
   - **规则触发分析**: 评估每条规则近期是否被实际触发（被应用于某个决策/防止了某个错误）
     - 从未被触发的规则 → 候选淘汰或合并
     - 被触发但频繁被违反的规则 → 需要加强或拆分为更小的约束
     - 触发后有效防止问题的规则 → 保留，优先级提升
   - **工程效能指标**（运行以下命令，让回顾有数据支撑）：
     ```bash
     # 近2周提交数和净 LOC
     git log --since="2 weeks ago" --oneline | wc -l
     git diff --stat HEAD~20 HEAD 2>/dev/null | tail -1
     # 测试文件覆盖率趋势
     git log --since="2 weeks ago" --name-only --pretty="" | grep -E "test|spec" | sort -u | wc -l
     ```
     - 测试文件占比 < 20% → ⚠️ 标记为增长项，纳入新规则候选
     - 热点文件（同一文件多次修改）→ 识别为高风险区域，建议加强测试

// turbo
1.5 **会话经验提取 + 本能聚合（持续学习）**
   扫描近期 checkpoint 文件、handoff 备忘录和本能数据：
   ```bash
   # 查找最近的检查点文件
   find . -name "checkpoint-*.md" -newer .agent/rules/code-style.md 2>/dev/null | head -10
   find . -name "handoff-*.md" -newer .agent/rules/code-style.md 2>/dev/null | head -5
   # 读取本能数据
   cat .agent/instincts/pending.yml 2>/dev/null || echo "# 暂无本能数据"
   ```

   **A. 模式提取**（委派给 `/learn`）：
   - 如本次 evolve 前未运行过 `/learn`，建议先执行 `/learn` 提取当前会话模式
   - `/learn` 负责提取，本步骤专注于升级/聚合/清理
   - ℹ️ 提取规则：仅提取与代码质量和工程流程相关的模式，不提取项目业务逻辑

   **B. 本能升级**（从 instincts 目录）：
   - confidence=5 的本能 → **自动升级**为 `.agent/rules/{category}.md` 中的正式规则
     - 升级后将原本能移动到 `.agent/instincts/promoted.yml` 归档
   - confidence≥4 的本能 → 向用户推荐升级，列出具体 pattern 和证据

   **C. 本能聚类**：
   - 同一 category 下 3+ 条本能 → 建议合并为一个新 Skill 草稿
   - 输出聚类建议供用户审核

   **D. 过期清理**：
   - 创建超过 60 天且 confidence≤2 → 标记 `expired`
   - 提示用户运行 `/instinct prune` 清理

// turbo
2. **盘点现有规则**
   收集所有规则来源：
   - `AGENT.md` 中的强制规则和项目规则
   - `.agent/skills/` 中的所有技能文件
   - `.agent/rules/` 目录中的所有模块化规则文件（如存在）
   - 向用户确认是否有其他未纳入的隐式规则

// turbo
3. **分类与统计**
   - 将所有规则按主题分组（编码规范、测试、安全、架构、流程…）
   - 统计每组的规则数量
   - 标注每条规则的来源文件

4. **去重扫描**
   - 识别语义相同但表述不同的规则
   - 提出合并建议（保留更精确的表述）

5. **冲突检测**
   - 识别互相矛盾的规则对
   - 对每对冲突，列出两条规则的具体内容
   - 向用户请求裁决：保留哪条、修改为什么

6. **淘汰评估**
   - 识别已被 Agent 内置能力覆盖的过时规则（如早期的 stop-hook 相关规则）
   - 识别从未被触发过或已不适用的规则
   - 结合步骤 1 回顾中标记的旧摩擦点
   - 向用户确认后移除

// turbo
7. **重组优化**
   - 如果某个类别超过 5 条规则，建议拆分为独立的 `.agent/rules/{类别}.md` 文件
   - 更新 AGENT.md 的路由表，指向新的规则文件
   - 确保 AGENT.md 保持在 200 行有效内容以内

8. **产出清理报告**
   向用户提交清理报告：
   ```
   ## 规则进化报告
   - **清理前**: [X 条规则, Y 个文件]
   - **清理后**: [X' 条规则, Y' 个文件]
   - **合并**: [合并的规则列表]
   - **移除**: [移除的规则列表及理由]
   - **冲突解决**: [已解决的冲突及裁决结果]
   - **重组**: [文件结构变更说明]
   - **新增 (来自回顾)**: [从近期摩擦中提炼的新规则/技能]
   ```

9. **自动化升级评估**
   - 检查是否有技能已稳定运行 3+ 次且无需人工干预
   - 对稳定技能建议升级为自动化（定时执行）
   - 原则：**Skills 定义方法，Automations 定义调度**。手动不稳定的流程不要急于自动化。

10. **验证**
    - 清理完成后，建议用户在下一个实际任务中观察 Agent 行为
    - 如果发现过度清理（某些需要的规则被误删），及时补回
