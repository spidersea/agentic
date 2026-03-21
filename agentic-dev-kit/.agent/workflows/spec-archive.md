---
description: 归档已完成变更 — 三维验证 + delta specs 合并 + 审计归档
---

# 规格归档 (Spec Archive)

> 触发方式: `/spec:archive [change-name]`
> 依赖技能: `.agent/skills/spec-driven/SKILL.md`
>
> 在变更完成后执行，将增量规格合并回主规格，保留审计轨迹。

## 前置条件

- `openspec/changes/<change-name>/` 目录存在且包含产物
- 如果未指定 `change-name`，自动检测当前活跃变更（`openspec/changes/` 下非 archive 的文件夹）

## 步骤

1. **选择归档目标**
   - 如果提供了 `change-name`，定位 `openspec/changes/<change-name>/`
   - 如果未提供，列出所有活跃变更供用户选择
   - 如果有多个已完成变更，询问是否批量归档

2. **检查完成状态**
   - 读取 `tasks.md`，统计已完成（`[x]`）和未完成（`[ ]`）任务数
   - 如果有未完成任务：
     - ⚠️ 警告用户，但不阻断归档
     - 询问是否继续归档或先完成剩余任务

3. **三维验证**
   执行三维度结构化检查：

   **3.1 完整性 (Completeness)**
   - 所有 tasks.md 中的任务是否已勾选
   - specs 中的所有 Requirements 是否有对应实现
   - 每个 Scenario 是否有测试覆盖或验证证据

   **3.2 正确性 (Correctness)**
   - 实现是否匹配 specs 中定义的行为意图
   - 边界条件和错误场景是否已处理
   - 搜索代码库确认实现与规格一致

   **3.3 一致性 (Coherence)**
   - design.md 中的架构决策是否反映在代码中
   - 命名模式是否与 design.md 一致
   - 如有偏差，标记为 WARNING 并建议更新 design.md

   **验证结果分类**：
   | 级别 | 说明 | 是否阻断归档 |
   |---|---|---|
   | CRITICAL | 规格承诺的行为未实现 | ✅ 阻断 |
   | WARNING | 实现与产物不一致但功能正常 | ❌ 不阻断（标记） |
   | SUGGESTION | 潜在改进空间 | ❌ 不阻断 |

4. **合并 Delta Specs**
   - 读取 `openspec/changes/<change-name>/specs/` 中的 delta specs
   - 解析 ADDED / MODIFIED / REMOVED 标记
   - 合并到 `openspec/specs/` 对应域目录：
     - **ADDED**: 追加新的 Requirements 和 Scenarios
     - **MODIFIED**: 更新已有内容，保留未提及的部分
     - **REMOVED**: 从主规格中移除对应条目
   - 如果目标 spec 文件不存在，从 delta 创建新文件

   > ⚠️ 合并是智能的（不是简单复制粘贴）。保留主规格中未被 delta 触及的内容。

5. **执行归档**
   - 生成归档目录名：`openspec/changes/archive/YYYY-MM-DD-<change-name>/`
   - 移动整个变更文件夹到归档目录
   - 确认归档成功

// turbo
6. **输出归档报告**
   向用户展示归档摘要：
   - 归档的变更名称和日期
   - Delta 合并结果（添加/修改/移除了哪些规格条目）
   - 验证结果摘要（CRITICAL / WARNING / SUGGESTION 计数）
   - 主规格当前状态

7. **后续建议**
   - 建议检查合并后的主规格文件是否清晰、无矛盾
   - 如有多个活跃变更，询问是否继续归档下一个
   - 建议执行 `/checkpoint` 记录归档状态
