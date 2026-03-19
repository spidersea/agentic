# AGENT.md

> 本文件是 AI 智能体的**逻辑路由表**，不是规则大全。
> 它只负责告诉 Agent：在什么场景下，去读哪个文件。
> 保持精简（<80 行有效内容），超出时拆分为独立文件并在此路由引用。

---

## 上下文恢复协议 (Context Recovery)

**每次会话开始或上下文压缩/重置后，Agent 必须按以下顺序执行恢复：**

1. 读取本文件 `AGENT.md`
2. 根据当前任务场景，加载对应的 Skill（见下方路由表）
3. 读取最新的检查点或状态文件（如存在）
4. 读取当前任务的实施计划和验收契约
5. 读取当前正在修改的核心文件（≤5 个）

⚠️ **禁止凭"记忆残影"继续工作。** 如果无法找到检查点文件，必须向用户确认当前状态后再继续。

---

## 技能路由 (Skill Routing)

| 场景 | 加载技能 | 重点章节 |
|---|---|---|
| 新功能开发、核心代码修改、重构 | `.agent/skills/world_class_coding/SKILL.md` | 全文 |
| TDD 驱动开发 | `.agent/skills/world_class_coding/SKILL.md` | §10.5 TDD 编程范式 + §10 测试纪律 |
| Debug、排查问题 | `.agent/skills/world_class_coding/SKILL.md` | Phase 4 + 中立提示词 |
| 编写或修改测试 | `.agent/skills/world_class_coding/SKILL.md` | Phase 2（契约）+ Phase 4（验证） |
| 跨会话任务续作 | `.agent/skills/world_class_coding/SKILL.md` | 第五章：可持续节点协议 |
| 前端 UI 开发 | `.agent/skills/frontend-design/SKILL.md` | 全文 |
| 设计增强/精简/审查 | 对应名称的 `.agent/skills/{名称}/SKILL.md` | 全文 |
| 代码结构分析、影响评估、依赖查询 | `.agent/skills/code-graph/SKILL.md` | 全文 |

> **渐进式加载**: Agent 首次只需读取技能的 frontmatter（name + description）。判断相关后再加载全文。避免不必要的上下文消耗。

---

## 工作流路由 (Workflow Routing)

| 命令 | 用途 | 工作流文件 |
|---|---|---|
| `/init` | 初始化项目 AI 开发配置 | `.agent/workflows/init.md` |
| `/new-feature` | 启动新功能开发（自动走 4 阶段 SOP） | `.agent/workflows/new-feature.md` |
| `/debug` | 中立 Debug（强制无偏见提示词） | `.agent/workflows/debug.md` |
| `/review` | 对抗式代码审查（A/B/C 模式 + 审查标准） | `.agent/workflows/review.md` |
| `/test` | 编写和运行自动化测试（测试金字塔） | `.agent/workflows/test.md` |
| `/tdd` | TDD 驱动开发（Red-Green-Refactor 循环） | `.agent/workflows/tdd.md` |
| `/checkpoint` | 生成标准检查点记录 | `.agent/workflows/checkpoint.md` |
| `/handoff` | 生成跨会话交接备忘录 | `.agent/workflows/handoff.md` |
| `/resume` | 从检查点恢复任务上下文 | `.agent/workflows/resume.md` |
| `/evolve` | 规则进化与清理（Spa Day） | `.agent/workflows/evolve.md` |
| `/stress-test` | 合规压测（标准任务 + 自动评分） | `.agent/workflows/stress-test.md` |
| `/context-reset` | 清理上下文污染并按协议恢复 | `.agent/workflows/context-reset.md` |

---

## 规则路由 (Rules Routing)

> 模块化规则文件存放在 `.agent/rules/` 目录中。Agent 根据当前操作的文件路径自动匹配并加载对应规则。
> 规则文件支持 `paths` frontmatter 限定生效范围，无 `paths` 则全局生效。

| 操作场景 | 自动加载规则 |
|---|---|
| 编辑 `src/` 或 `lib/` 下的代码文件 | `.agent/rules/code-style.md` |
| 编辑或创建测试文件 | `.agent/rules/testing.md` |
| 代码审查 / `/review` 工作流 | `.agent/rules/code-review.md` |
| 所有场景 | `.agent/rules/security.md` |

> **扩展**: 当项目规则超过 5 条时，应创建新的 `.agent/rules/{主题}.md` 文件并在此路由。

---

## 渐进式上下文加载 (Progressive Disclosure)

### `@文件引用` 语法

Agent 可使用 `@文件路径` 在需要时按需引用其他文件内容，避免一次性加载过多信息：

```
项目概览 → @README.md
依赖与命令 → @package.json 或 @pyproject.toml
Git 工作流 → @docs/git-workflow.md
```

### 配置层级与继承

支持多级配置，子级覆盖父级，精确匹配优先：

| 层级 | 文件位置 | 作用域 | 是否提交 git |
|---|---|---|---|
| 全局 | `~/.agent/AGENT.md` | 所有项目 | 否 |
| 项目 | `./AGENT.md` | 当前项目 | ✅ 是 |
| 子目录 | `子目录/AGENT.md` | 该子目录 | ✅ 是 |
| 本地覆盖 | `./AGENT.local.md` | 当前用户 | ❌ 否（加入 .gitignore） |

> `AGENT.local.md` 用于个人偏好（如 IDE 配置、个人编码习惯），不影响团队共享配置。

---

## 强制规则 (Hard Rules)

1. **禁用偏见提示**: Debug 时禁止使用"帮我找 bug"、"这段代码有什么问题"等预设偏见提示词，必须使用中立提示
2. **禁止未授权依赖**: 不得自行引入技术规格中未定义的第三方依赖
3. **契约优先**: 除非验收契约中的所有条件全部通过，否则不得标记任务完成
4. **会话隔离**: 禁止在单个会话中串联超过 3 个不相关任务
5. **检查点纪律**: 每个 Phase 完成后必须记录检查点，跨会话时必须产出交接备忘录
6. **不确定时停下**: 当不确定某个实现细节时（置信度 < 80%），必须标注 `[不确定]` 并提供备选方案，不可自行猜测并继续
7. **影响感知**: 修改任何被其他模块依赖的公共函数/类/接口前，必须先分析调用方列表并评估影响范围。如果代码图谱可用，必须通过 `get_impact_radius` 量化。修改公共 API 签名、参数、返回值后，必须搜索并同步更新所有引用该接口的文档（README、API 文档、JSDoc/注释、CHANGELOG 等）。
8. **证据先行**: 禁止在未执行验证命令并确认输出的情况下声称"完成"、"通过"、"修复"。"应该没问题"、"看起来正确"、"大概率通过"等措辞等同于未验证。必须：运行命令 → 读取输出 → 确认结果 → 才能声称。

---

## 项目规则 (Project-Specific Rules)

> 在此处添加项目特有的规则。当规则超过 5 条时，应拆分为 `.agent/rules/*.md` 并在此路由引用。

<!-- 示例:
- 本项目使用 Python 3.12 + FastAPI
- 所有 API 必须有 OpenAPI 文档
- 当编写 API 代码时 → 读取 `.agent/rules/api-conventions.md`
-->
