---
description: 会话模式提取 — 从当前会话中提取编码模式并保存为本能
---

# 会话模式提取

> 从当前会话中提取反复出现的编码模式（本能），评估置信度并保存。
> 触发方式: `/learn`
> 前置技能: `.agent/skills/continuous-learning/SKILL.md`

## 步骤

// turbo
1. **扫描信号源**
   收集当前会话中的模式信号：
   ```bash
   # 查找最新的 checkpoint 和 handoff 文件
   find . -name "checkpoint-*.md" -mtime -1 2>/dev/null | head -5
   find . -name "handoff-*.md" -mtime -1 2>/dev/null | head -5
   # 今天的 git commits
   git log --since="1 day ago" --oneline 2>/dev/null | head -20
   ```
   - 读取找到的 checkpoint/handoff 文件
   - 回顾当前会话中用户的纠正行为和反复强调

// turbo
2. **识别模式**
   从扫描结果中提取行为模式，按类别分组：
   - `code-quality`: 代码质量相关（命名、结构、边界处理…）
   - `testing`: 测试相关（覆盖率、测试策略…）
   - `security`: 安全相关
   - `architecture`: 架构设计相关
   - `workflow`: 工程流程相关

   每个模式必须包含：
   - **pattern**: 一句话描述该模式
   - **context**: 具体场景/证据（在哪次操作中观察到）
   - **category**: 分类

// turbo
3. **去重与合并**
   ```bash
   # 检查是否已有本能文件
   cat .agent/instincts/pending.yml 2>/dev/null || echo "# 空 — 首次提取"
   ```
   - 对比已有本能：语义相同 → 提升 confidence + 追加 source_session
   - 全新模式 → 新建条目，confidence=1

// turbo
4. **写入本能文件**
   - 确保 `.agent/instincts/` 目录存在
   - 将提取结果写入/追加到 `.agent/instincts/pending.yml`

5. **输出报告**
   向用户展示提取结果：
   ```markdown
   ## 本能提取报告
   - **扫描范围**: [checkpoint 数 + commit 数]
   - **新发现**: [N 条新本能]
   - **置信度提升**: [M 条已有本能获得验证]
   - **候选升级** (confidence≥4): [列表]
   - **建议**: [后续行动 — 如运行 /evolve 升级高置信度本能]
   ```

## 注意事项

- ⚠️ 仅提取与代码质量/工程流程相关的模式，不提取业务逻辑
- 每次提取不超过 5 条新本能，避免噪声过多
- 低置信度本能需要多次验证才能升级，这是设计使然
