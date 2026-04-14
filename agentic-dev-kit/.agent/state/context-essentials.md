# Context Essentials（上下文压缩后自动注入）

> 本文件在每次 `/compact` 或 auto compaction 后自动注入到 Agent 上下文，确保关键规则不被压缩丢失。
> 保持精简 — 不超过 50 行，只放"丢失会导致灾难"的规则。

## 核心行为约束（永不丢失）

1. **Escalation 规则**: 连续 2 次失败 → L1 切换方案，3 次 → L2 深度调查，4 次 → L3 七项清单，5+ → L4 拼命模式，7+ → L5 Mythos。压力状态读取自 `.escalation-state.json`。
2. **验证义务**: 所有修改必须通过验收命令验证（build + test），禁止空口说"已完成"。
3. **Guard 回归**: 修改后运行 Guard 命令确保未引入回归。
4. **禁止放弃**: 七项清单（escalation L3）全部 `[x]` 前禁止声称"无法解决"。

## 当前任务边界（每次更新）

<!-- Lead Agent 在每次 compact 前更新此段 -->
- **当前目标**: [待更新]
- **作用域**: [待更新]
- **验收条件**: [待更新]

## 活跃的 Escalation 状态

<!-- 从 .escalation-state.json 同步 -->
- **当前等级**: L0
- **连续失败**: 0
- **当前方法论**: 默认
- **已排除假设**: 无

## 禁止清单（当前项目）

<!-- 从 CLAUDE.md / rules/ 提取的关键禁止项 -->
- 不引入未授权的外部依赖
- 不修改 `.agent/` 目录下的结构文件（除非任务明确要求）
- 不使用 `eval()` / `exec()` 等危险函数

## 关键文件路径（快速参考）

- 压力状态: `.escalation-state.json`
- 代码规范: `.agent/rules/code-style.md`
- 质量模式: `.agent/skills/quality-patterns/SKILL.md`
- 历史失败: `.agent/state/memory-palace/failure-patterns.jsonl`
- 隐性传统: `.agent/state/tacit-tradition-map.md`
