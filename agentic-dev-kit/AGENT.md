# AGENT.md

> 本文件是 AI 智能体的**逻辑路由表**，不是规则大全。
> 它只负责告诉 Agent：在什么场景下，去读哪个文件。
> 保持精简（<200 行有效内容），超出时拆分为独立文件并在此路由引用。

---

## 上下文恢复协议 (Context Recovery)

**每次会话开始或上下文压缩/重置后，Agent 必须按以下顺序执行恢复：**

1. 读取本文件 `AGENT.md`
2. 执行 `bash .agent/scripts/session-start.sh`（自动发现最新检查点和本能状态）
3. 根据当前任务场景，加载对应的 Skill（见下方路由表）
4. 读取记忆宫殿 `.agent/state/memory-palace/`（邪修六式）：
   - `assumptions.jsonl` — 全部（当前有效的假设不可丢失）
   - `decisions.jsonl` — 最后 10 条（近期决策上下文）
   - `failure-patterns.jsonl` — 最后 5 条 + 与当前任务相关的历史模式
5. 读取经验积累库 `.agent/state/captured-patterns/`（如存在）：
   - 扫描所有 `CP-*.md` 文件的 front-matter（id, name, category, severity）
   - 与当前任务领域匹配的 pattern 全量读取
6. 读取最新的检查点或状态文件（如存在）
7. 读取当前任务的实施计划和验收契约
8. 读取当前正在修改的核心文件（≤5 个）

⚠️ **禁止凭"记忆残影"继续工作。** 如果无法找到检查点文件，必须向用户确认当前状态后再继续。

> **自动压缩感知**: 当对话轮次 > 15 轮 或 累计加载文件行数 > 5000 行时，Agent 应主动建议执行 `/context-reset`。每个 Phase 完成后应主动清理该 Phase 独有的文件缓存。详见 `.agent/workflows/context-reset.md`「自动压缩触发条件」。

### 工作模式上下文（Work Mode Contexts）

> 来自 everything-claude-code 的 contexts/ 理念 + Claude Code 的 `getSessionSpecificGuidanceSection()` 动态注入设计。
> 用户可在会话开始时显式声明，无需 AI 推测：

| 模式 | 声明方式 | AI 应加载 | AI 应避免 |
|---|---|---|---|
| **开发模式** | 「我们现在开始编码」/ `/new-feature` | world_class_coding（全文）+ 测试规则 | 大范围分析、设计讨论 |
| **审查模式** | 「帮我 review 这段代码」/ `/review` | code-review.md + graphify | 主动修改代码 |
| **调研模式** | 「我想了解这个问题」/ 探索性对话 | 轻量加载（≤3 文件） | 执行 SOP 四阶段、写测试 |
| **安全审计模式** | `/autoresearch:security` / `/security-audit` | adversarial-persona(L3) + escalation + autoresearch:security + adversary Agent | 建设性思维、安慰性输出 |

**动态会话指引注入（Session-Specific Guidance）：**

> 进入工作模式后，Agent 应根据**当前可用能力和任务状态**自动注入对应指引，而不是仅靠静态表：

- 📊 **代码图谱可用时** → 自动注入：优先使用 `get_impact_radius` / `get_review_context` 辅助决策
- 🔀 **存在未完成的 fork/子任务时** → 自动注入：不要偷看子任务输出文件、不要预言子任务结果
- 🧪 **项目有测试配置时** → 自动注入：修改 `src/` 代码后必须执行 `/test`
- 🛡️ **存在 `.agent/hooks/pre-tool/` 脚本时** → 自动注入：写操作前将触发 Pre-Tool Hook 检查
- 📋 **存在未完成的任务契约时** → 自动注入：所有操作必须在契约范围内
- 🔒 **非交互模式时** → 自动注入：禁止所有需要用户确认的操作，遇到不可逆操作直接跳过并记录



## 技能路由 (Skill Routing)

### 技能加载策略

> ⚠️ **禁止全量加载所有技能**。按以下分层按需加载，控制 Token 预算。

| 加载层级 | 何时加载 | 包含技能 | 估算 Tokens |
|---------|---------|---------|------------|
| **Always-on** | 每次会话自动 | autoresearch + escalation + agent-dsl | ~12,770 |
| **Workflow-driven** | 工作流触发时 | 由 /new-feature /debug /review 等路由决定 | 按需 |
| **On-demand** | 用户显式 `@` 引用 | graphify, spec-driven, multi-agent 等 | 按需 |
| **Lazy-load** | 首次只读 frontmatter | Tier 2 微调技能 | ~200/个 |

### Tier 1 — 核心技能（主动加载）

| 场景 | 加载技能 | 重点章节 |
|---|---|---|
| 新功能开发、核心代码修改、重构 | `.agent/skills/world_class_coding/SKILL.md` | 全文 |
| 代码架构审查、质量检测、微观设计 | `.agent/skills/world_class_coding/coding-architecture/SKILL.md` | 全文 |
| Git 代码提交、版本控制 | `.agent/skills/world_class_coding/version-control/SKILL.md` | 全文 |
| 编写测试用例、TDD | `.agent/skills/world_class_coding/testing-discipline/SKILL.md` | 全文 |
| 规则进化与清理 | `.agent/skills/world_class_coding/rule-evolution/SKILL.md` | 全文 |
| Debug、排查问题 | `.agent/skills/world_class_coding/SKILL.md` | Phase 4 + 中立提示词 |
| 跨会话任务续作 | `.agent/skills/world_class_coding/SKILL.md` | 第五章 |
| 代码结构分析、知识图谱、影响评估 | `.agent/skills/graphify/SKILL.md` | 全文 |
| 疑难杂症经验结晶 | `.agent/state/captured-patterns/{名称}.md` | 全文 |
| 需求规格管理、行为契约 | `.agent/skills/spec-driven/SKILL.md` | 全文 |
| 持续优化、自主迭代、安全审计 | `.agent/skills/autoresearch/SKILL.md` | 全文（仅手动触发） |
| 自然语言意图编译为 DSL 执行契约 | `.agent/skills/agent-dsl/SKILL.md` | 全文 |
| 前端 UI 开发（生产级界面） | `.agent/skills/frontend-design/SKILL.md` | 全文 |
| 上线前质量检查（含设计评估） | `.agent/skills/polish/SKILL.md` | 全文 |
| 审计（无障碍/性能/响应式） | `.agent/skills/audit/SKILL.md` | 全文 |
| UI 健壮性 + 安全加固 | `.agent/skills/harden/SKILL.md` | 全文 |
| API 文档检索 | `.agent/skills/doc-lookup/SKILL.md` | 全文 |
| 多 Agent 编排协议 | `.agent/skills/multi-agent/SKILL.md` | 全文（`--multi-agent` 时） |
| 对抗推理质量模式库 | `.agent/skills/quality-patterns/SKILL.md` | 全文（审查/adversary 时） |

> **情境触发技能**（检测到条件时自动加载）：
> `escalation`（连续失败 2+ 次）· `hooks-lifecycle`（会话开始/结束/压缩）· `continuous-learning`（`/learn`/`/evolve`/`/handoff`）· `dark-cultivation`（`--dark` 或高风险变更）· `polanyi`（认识论深度，三引擎默认引用）

> **按需加载技能**（使用对应命令时加载）：
> `skill-creator`（`/skill-create`）

### Tier 2 — 微调技能（用自然语言触发，Lazy-load）

> 描述需求时自动匹配：`visual-enhance`（动画/配色/微交互）· `normalize`（Token 规范）· `extract`（组件提取）· `optimize`（性能优化）· `teach-impeccable`（设计上下文初始化）

> **渐进式加载**: 首次只读 frontmatter，相关后再全量加载。**Debug**: `/debug` 单次根因 / `/autoresearch:debug` 持续扫描。

### Token 效率原则（质量优先，不降低标准前提下减少浪费）

**任务复杂度评估** — 开始工作前，先判断任务规模：

| 复杂度 | 判断标准 | 流程适配 |
|---|---|---|
| **轻量**（≤2 文件，无公共 API 变更） | 配置修改、文案调整、样式微调、内部函数小改 | 跳过 CP-1~CP-3（仅保留 CP-4 最终验证）；`/review` 使用快速模式（仅中立阅读 + A 风险扫描，跳过 B/C） |
| **中等**（3-5 文件，有公共 API 变更） | 功能模块新增、接口重构、跨文件重命名 | 完整四阶段 SOP；`/review` 使用标准模式（A/B/C 完整对抗） |
| **重度**（>5 文件或架构变更） | 架构重构、大规模数据迁移、核心模块重写 | 完整四阶段 SOP + git worktree 隔离；`/review` 使用深度模式（分模块逐一审查） |

> ⚠️ **底线不可动**：无论任务多轻量，以下标准永远执行 —— 禁用偏见提示、禁止未授权依赖、证据先行验证、影响感知（含文档同步）。

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
| `/skill:capture` | 从复杂任务中提炼避坑经验和解决模式为微型技能 | `.agent/workflows/skill-capture.md` |
| `/evolve` | 规则进化与清理（Spa Day） | `.agent/workflows/evolve.md` |
| `/stress-test` | 合规压测（标准任务 + 自动评分） | `.agent/workflows/stress-test.md` |
| `/context-reset` | 清理上下文污染并按协议恢复 | `.agent/workflows/context-reset.md` |
| `/finish` | 分支完成收尾（merge/PR/keep/discard + worktree 清理） | `.agent/workflows/finish.md` |
| `/spec:propose` | 创建规格驱动的变更提案（proposal + specs + design + tasks） | `.agent/workflows/spec-propose.md` |
| `/spec:archive` | 归档已完成变更并合并 delta specs 到主规格 | `.agent/workflows/spec-archive.md` |
| `/autoresearch` | 自主迭代优化（修改→验证→保留/回滚→重复） | `.agent/skills/autoresearch/SKILL.md` |
| `/autoresearch:security` | 自主安全审计（STRIDE + OWASP + 红队） | `.agent/skills/autoresearch/SKILL.md` |
| `/autoresearch:ship` | 通用发布流程（8 阶段） | `.agent/skills/autoresearch/SKILL.md` |
| `/autoresearch:fix` | 自主修复循环（测试/类型/lint/构建错误归零） | `.agent/skills/autoresearch/SKILL.md` |
| `/autoresearch:review` | 自助持续代码审查循环（审查→修复收敛） | `.agent/skills/autoresearch/SKILL.md` |
| `/autoresearch:debug` | 自主 Bug 猎手（科学方法 + 迭代追查） | `.agent/skills/autoresearch/SKILL.md` |
| `/learn` | 从当前会话提取编码模式为本能 | `.agent/workflows/learn.md` |
| `/instinct` | 本能管理（status/import/export/prune） | `.agent/workflows/instinct.md` |
| `/hooks` | 三层钩子管理（Pre/Post Tool + Lifecycle） | `.agent/workflows/hooks.md` |
| `/config-scan` | Agent 配置安全扫描（密钥/权限/注入） | `.agent/workflows/config-scan.md` |
| `/harness-audit` | 配置健康度审计 + 模型路由建议 | `.agent/workflows/harness-audit.md` |
| `/skill-create` | 从 Git 历史生成项目编码规范技能 | `.agent/workflows/skill-create.md` |
| `/escalate` | 手动触发压力升级（强制进入 L3 高压模式） | `.agent/workflows/escalate.md` |
| `/dsl` | 将口语化需求编译为三引擎 DSL 执行指令 | `.agent/skills/agent-dsl/SKILL.md` |

---

## 规则路由 (Rules Routing)

> 模块化规则文件存放在 `.agent/rules/` 目录中。Agent 根据当前操作的文件路径自动匹配并加载对应规则。
> 规则文件支持 `paths` frontmatter 限定生效范围，无 `paths` 则全局生效。

| 操作场景 | 自动加载规则 |
|---|---|
| 编辑 `src/` 或 `lib/` 下的代码文件，或调用 `frontend-design` 时 | `.agent/rules/code-style.md` |
| 编辑或创建测试文件 | `.agent/rules/testing.md` |
| 代码审查 / `/review` 工作流 | `.agent/rules/code-review.md` |
| 所有场景 | `.agent/rules/security.md` |
| 所有场景 | `.agent/rules/red-lines.md` |
| 修改 `src/` 或 `lib/` + 安全审计模式 + Escalation L3+ | `.agent/rules/adversarial-persona.md` |

> **扩展**: 当项目规则超过 5 条时，应创建新的 `.agent/rules/{主题}.md` 文件并在此路由。

---

## Agent 委派路由 (Agent Delegation)

> 专职 Sub-Agent 定义在 `.agent/agents/` 目录中。主 Agent 可委派特定任务给 Sub-Agent。
> 借鉴 Claude Code 的 built-in agents（Explore/Plan/Verification）专职化设计：**每个 Agent 有明确的权限边界和角色约束**。

| Agent | 职责 | 权限模式 | 限定工具 | 定义文件 |
|---|---|---|---|---|
| explorer | 代码探索与调研（纯只读） | ReadOnly | Read, Grep, Search, List | `.agent/agents/explorer.md` |
| planner | Phase 1 技术规格规划 | ReadOnly | Read, Search, List | `.agent/agents/planner.md` |
| coder | 功能实现（独立 worktree） | WorkspaceWrite | Read, Write, Execute, Grep | `.agent/agents/coder.md` |
| reviewer | 代码审查（A/B/C 对抗） | ReadOnly | Read, Grep, Search | `.agent/agents/reviewer.md` |
| verifier | 对抗式验证 | WorkspaceWrite | Read, Execute, Search | `.agent/agents/verifier.md` |
| tester | 测试编写和运行 | WorkspaceWrite | Read, Write, Execute | `.agent/agents/tester.md` |
| security-reviewer | 安全审查（OWASP/STRIDE） | ReadOnly | Read, Grep, Search | `.agent/agents/security-reviewer.md` |
| adversary | 红队攻击（纯破坏者） | ReadOnly | Read, Grep, Search | `.agent/agents/adversary.md` |
| doc-updater | 代码变更后文档同步 | WorkspaceWrite | Read, Write, Search | `.agent/agents/doc-updater.md` |

**Agent 能力声明协议：**
> 借鉴 Claude Code 的 agent-specific MCP servers：每个 Agent 定义文件中可声明所需的外部能力。

```markdown
# Agent 定义文件格式（.agent/agents/*.md）
---
name: explorer
permission_mode: ReadOnly          # ReadOnly | WorkspaceWrite | DangerFullAccess
tools: [Read, Grep, Search, List]  # 允许使用的工具白名单
skills: [graphify]                 # 可选：该 Agent 额外加载的技能
capabilities: []                   # 可选：所需的外部能力（MCP server 名称等）
---
[Agent 的 system prompt 内容]
```

> **关键约束**（来自 Claude Code Explore Agent 设计）：
> - **ReadOnly Agent 绝对禁止**：创建/修改/删除文件、运行改变状态的命令、使用重定向写文件
> - **Explorer / Planner 的 Bash 只允许**：`ls`, `git status`, `git log`, `git diff`, `find`, `grep`, `cat`, `head`, `tail`
> - **Verifier 必须主动构造对抗场景**，而非仅确认"看起来没问题"

> **使用原则**: 并行任务（如同时 review + 写文档）时委派更高效。简单顺序任务使用主 Agent 加载不同 Skill 即可。

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

### 配置合并规则

> 借鉴 Claude Code `deep_merge_objects()` 的合并策略，为多级配置定义明确的冲突解决规则。

| 冲突类型 | 合并策略 | 示例 |
|---|---|---|
| 同名**对象** | 子级**递归合并**父级 | 父: `{rules: {security: true}}` + 子: `{rules: {testing: true}}` → `{rules: {security: true, testing: true}}` |
| 同名**标量/列表** | 子级**直接覆盖**父级 | 父: `max_files: 5` + 子: `max_files: 3` → `max_files: 3` |
| 子级**新增**字段 | 直接追加到合并结果 | 父无 `hooks` + 子有 `hooks` → 合并结果包含 `hooks` |
| `AGENT.local.md` | **最终覆盖层**，优先级最高 | 任何字段均覆盖项目级和全局级 |

> **注意**: 列表类型（如路由表条目）是**整体替换**而非追加。如果子级定义了同名列表，父级该列表被完全覆盖。

---

## 强制规则 (Hard Rules)

> 以下规则按优先级排序。Agent 遵守率与规则数成反比——保持精简。

1. **证据先行**: 禁止未验证就声称完成。所有修改必须有可验证的证据（测试通过/构建成功/lint 清零）
2. **契约优先**: 验收契约中的所有条件全部通过才可标记完成
3. **禁用偏见提示**: Debug 时禁止预设偏见提示词，必须使用中立提示
4. **禁止未授权依赖**: 不得自行引入技术规格中未定义的第三方依赖
5. **禁止 Mock 实现**: 功能代码中禁止 mock 数据/placeholder 函数，mock 仅限测试文件
6. **影响感知**: 修改公共 API 前必须分析调用方 + 同步文档。代码图谱可用时必须用 `get_impact_radius`
7. **不确定时停下**: 置信度 < 80% 时标注 `[不确定]` 并提供备选方案
8. **自主决策**: 能自己决定的不问用户。轻量任务直接做完汇报
9. **对抗自检**: 输出"没问题"类结论前必须生成 ≥1 个反例场景
10. **检查点纪律**: 每个 Phase 完成后记录检查点，跨会话产出交接备忘录
11. **工具自造权**: 可在 `.agent/scratch/` 中创建一次性分析脚本（≤100 行，纯读取，执行后清理）

> 详细说明见 `.agent/rules/red-lines.md`（红线一~四）和 `.agent/rules/adversarial-persona.md`。

---

## 输出效率与产品质感 (Output Efficiency & Tone)

> 借鉴 Claude Code 的 `getOutputEfficiencySection()` + `getToneAndStyleSection()`。
> 核心理念：Agent 不只要「完成任务」，还要让输出「像正式产品」。

**输出规范：**
- **结论先行**：先说动作或结论，不要铺垫。用户看的是结果，不是你的思考过程
- **不要过度解释**：代码改动无需逐行解释「为什么」，除非改动非显而易见
- **不要塞无谓表格**：只有 ≥3 行 × ≥2 列的结构化数据才值得用表格
- **短句直给**：能用一句话说清的不要用三句
- **引用格式统一**：代码位置一律用 `文件路径:行号` 格式；Git issue 用 `owner/repo#123`
- **不要乱用 emoji**：emoji 仅用于状态标识（✅❌⚠️），不可用于装饰或语气
- **工具调用前不加冒号**：调用工具时直接调用，不要写「让我来：」「接下来我会：」等铺垫

---

## 项目规则 (Project-Specific Rules)

> 在此处添加项目特有的规则。当规则超过 5 条时，应拆分为 `.agent/rules/*.md` 并在此路由引用。

<!-- 示例:
- 本项目使用 Python 3.12 + FastAPI
- 所有 API 必须有 OpenAPI 文档
- 当编写 API 代码时 → 读取 `.agent/rules/api-conventions.md`
-->
