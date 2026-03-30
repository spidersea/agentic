---
description: 创建规格驱动的变更提案 — 生成 proposal + delta specs + design + tasks
---

# 规格驱动变更提案 (Spec Propose)

> 触发方式: `/spec:propose <change-name>`
> 依赖技能: `.agent/skills/spec-driven/SKILL.md`
>
> 本工作流可独立使用，也可在 `/new-feature` Phase 1 中自动调用。

## 前置条件

- `<change-name>` 使用 kebab-case（如 `add-dark-mode`、`fix-login-redirect`）
- 避免泛化命名（如 `update`、`changes`、`wip`）

## 步骤

1. **读取规格驱动技能**
   读取 `.agent/skills/spec-driven/SKILL.md`，理解规格格式和产物依赖链。

2. **初始化变更目录**
   - 如果 `openspec/` 目录不存在，创建基础结构：
     ```bash
     mkdir -p openspec/specs openspec/changes
     ```
   - 创建变更文件夹：`openspec/changes/<change-name>/`

3. **生成 Proposal (`proposal.md`)**
   - 与用户确认变更意图和范围（⚠️ 每次只问一个问题）
   - 必须提出 2-3 个替代方案并附带权衡分析
   - 明确区分 "In Scope" 和 "Out of Scope"
   - **📋 非技术摘要块（必须包含，供非技术用户验收）**：
     在 proposal.md 顶部插入以下固定格式的摘要，用**完全不含技术术语的语言**回答：
     ```markdown
     ## 📋 一句话总结（非技术版）
     > [用一句话描述：这次改动完成后，用户会看到/能做什么不同的事]
     
     ## ✅ 会做的事
     - [功能点1，用户视角描述]
     - [功能点2，用户视角描述]
     
     ## ❌ 不会做的事（Out of Scope）
     - [明确排除的内容，防止误解]
     
     ## ⚠️ 会影响到什么
     - [现有功能中，哪些会受到影响或改变]
     ```
     用户只需读这一块（1-2 分钟），确认 AI 理解的需求是否正确，无需阅读技术细节。
   - 产出 `openspec/changes/<change-name>/proposal.md`

4. **生成 Delta Specs (`specs/`)**
   - 判断严格度级别：
     - **Lite Spec（默认）**: ≤2 个 Requirements + 数个关键 Scenarios
     - **Full Spec**: API 变更、安全变更、跨团队变更 → 完整 Requirements + Scenarios + 边界条件
   - 如果 `openspec/specs/` 已有相关领域规格，先阅读现有规格
   - 使用增量格式（ADDED/MODIFIED/REMOVED）描述行为变更
   - 使用 RFC 2119 关键词（SHALL/MUST/SHOULD/MAY）
   - 使用 Given/When/Then 场景格式
   - 产出 `openspec/changes/<change-name>/specs/{domain}/spec.md`

5. **生成 Design (`design.md`)**
   - 基于 proposal 和 specs 编写技术方案
   - 包含架构决策及其理由
   - 包含数据流或组件关系（文字描述或 ASCII 图）
   - 列出将创建/修改的文件清单
   - 📊 如果代码图谱可用，执行 `query_graph` 辅助分析模块依赖
   - 产出 `openspec/changes/<change-name>/design.md`

6. **生成 Tasks (`tasks.md`)**
   - 基于 design 拆分为具体实施步骤
   - 按功能模块分组，使用层级编号（1.1, 1.2 ...）
   - 每个任务粒度控制在 2-5 分钟可完成
   - **每个任务必须包含（P0 可执行标准）**:
     - 精确文件路径（Create / Modify / Test）
     - **完整代码**（不可写"添加验证逻辑"等模糊描述，必须给出可直接粘贴的代码片段）
     - **精确运行命令 + 预期输出**（如 `pytest tests/auth/ -v` → 预期 PASS）
     - 验证步骤（如何确认这一步成功）
   - 产出 `openspec/changes/<change-name>/tasks.md`

// turbo
7. **提交审批**
   - 向用户展示所有生成的产物概要
   - 等待用户确认或修改反馈
   - 如果用户要求修改，回到对应步骤更新产物（流式灵活，无阶段门禁）

8. **衔接后续**
   - 用户确认后，可直接进入 `/new-feature` Phase 2（验收契约）
   - 或直接按 `tasks.md` 开始编码
   - 指引执行 `/checkpoint` 记录规划状态

如果阻塞，可求助 `/debug` 流程。
