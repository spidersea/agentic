# 代理路由表大全 (Router Tables)

> 此文件承载 `AGENT.md` 下推的大型路由映射表。
> 当需要在特定场景下查找应调用哪个工作流或技能时，查阅本文档。

## 1. 技能路由表 (Skill Routing)

### Tier 1 — 核心技能
| 场景 | 加载技能 |
|---|---|
| 新功能开发、重构 | `.agent/skills/world_class_coding/SKILL.md` |
| 架构审查微观设计 | `.agent/skills/world_class_coding/coding-architecture/SKILL.md` |
| 编写测试用例、TDD | `.agent/skills/world_class_coding/testing-discipline/SKILL.md` |
| 规则进化与清理 | `.agent/skills/world_class_coding/rule-evolution/SKILL.md` |
| 代码图谱、影响评估 | `.agent/skills/graphify/SKILL.md` |
| 疑难杂症模式积累 | `.agent/state/captured-patterns/{名称}.md` |
| 规格驱动(OpenSpec) | `.agent/skills/spec-driven/SKILL.md` |
| 自主优化、安全审计 | `.agent/skills/autoresearch/SKILL.md` |
| 自然语言转DSL | `.agent/skills/agent-dsl/SKILL.md` |
| 前端UI开发 | `.agent/skills/frontend-design/SKILL.md` |
| 上线前设计审查 | `.agent/skills/polish/SKILL.md` |
| 无障碍/性能审计 | `.agent/skills/audit/SKILL.md` |
| 健壮性安全加固 | `.agent/skills/harden/SKILL.md` |
| 多 Agent 编排指令 | `.agent/skills/multi-agent/SKILL.md` |
| 对抗推理模式库 | `.agent/skills/quality-patterns/SKILL.md` |
| AI 优先脚手架工程 | `.agent/skills/ai-first/SKILL.md` |
| 进入全新陌生领域 | `.agent/skills/domain-mastery/SKILL.md` |

### Tier 2 — 辅助与专用技能
| 场景 | 加载技能 |
|---|---|
| 高风险任务进入强对抗深思 | `.agent/skills/dark-cultivation/SKILL.md` |
| 外部 API / 项目文档检索 | `.agent/skills/doc-lookup/SKILL.md` |
| 设计系统对齐 | `.agent/skills/normalize/SKILL.md` |
| 可复用组件 / Token 抽取 | `.agent/skills/extract/SKILL.md` |
| 前端性能优化 | `.agent/skills/optimize/SKILL.md` |
| 微交互与视觉增强 | `.agent/skills/visual-enhance/SKILL.md` |
| 认识论 / 隐性知识视角 | `.agent/skills/polanyi/SKILL.md` |
| Git 分支与提交纪律 | `.agent/skills/world_class_coding/version-control/SKILL.md` |

### 工作流路由表 (Workflow Routing)

| 命令 | 用途 | 对应文件 |
|---|---|---|
| `/init` | 初始化项目 | `.agent/workflows/init.md` |
| `/new-feature` | 4 阶段开发 | `.agent/workflows/new-feature.md` |
| `/debug` | 中立 Debug | `.agent/workflows/debug.md` |
| `/review` | 对抗式代码审查 (A/B/C) | `.agent/workflows/review.md` |
| `/tdd` | 红绿重构开发 | `.agent/workflows/tdd.md` |
| `/checkpoint` | 保存当前进度 | `.agent/workflows/checkpoint.md` |
| `/handoff` | 生成交接备忘录 | `.agent/workflows/handoff.md` |
| `/resume` | 恢复检查点上下文 | `.agent/workflows/resume.md` |
| `/evolve` | 规则清洁 | `.agent/workflows/evolve.md` |
| `/context-reset` | 上下文重置 | `.agent/workflows/context-reset.md` |
| `/spec:propose` | 规格驱动提案 | `.agent/workflows/spec-propose.md` |
| `/spec:archive` | 规格归档 | `.agent/workflows/spec-archive.md` |
| `/hooks` | 生命周期干预 | `.agent/workflows/hooks.md` |
| `/escalate` | 压力攀升测试 | `.agent/workflows/escalate.md` |
| `/learn` | 经验提取与沉淀 | `.agent/workflows/learn.md` |
| `/finish` | 分支收尾 | `.agent/workflows/finish.md` |
| `/multi-agent` | 多 Agent 编排 | `.agent/workflows/multi-agent.md` |
| `/skill-create` | 创建新 Skill | `.agent/workflows/skill-create.md` |
| `/skill:capture` | 捕获新 Skill 模式 | `.agent/workflows/skill-capture.md` |
| `/stress-test` | 合规压测 | `.agent/workflows/stress-test.md` |
| `/config-scan` | 配置扫描 | `.agent/workflows/config-scan.md` |
| `/harness-audit` | 规范系统审计 | `.agent/workflows/harness-audit.md` |
| `/instinct` | 本能管理 | `.agent/workflows/instinct.md` |
| `/autoresearch:*` | 自主循环族（security/ship/fix/review/debug/plan） | `.agent/skills/autoresearch/SKILL.md` |

## 2. Agent 委派路由 (Delegation Agent Matrix)

> 定义在 `.agent/agents/` 下的主职分身。
- **explorer**: 代码探索调研 (ReadOnly)
- **planner**: 技术规格规划 (ReadOnly)
- **coder**: 功能实现写作 (WorkspaceWrite)
- **reviewer**: 代码冲突审查 (ReadOnly)
- **verifier**: 逆向验证构建 (WorkspaceWrite)
- **tester**: 测试编写执行 (WorkspaceWrite)
- **security-reviewer**: 威胁模型分析 (ReadOnly)
- **adversary**: 极度破坏红队 (ReadOnly)
- **doc-updater**: 伴随文档同步 (WorkspaceWrite)

## 3. 维护与体检入口 (Maintenance & Diagnostics)

| 场景 | 入口文件 |
|---|---|
| 规范健康扫描 | `.agent/scripts/health-check.sh` |
| 框架结构校验 | `.agent/scripts/validate-structure.sh` |
| Markdown 链接完整性校验 | `.agent/scripts/md-linker.sh` |
| Skill 质量扫描 | `.agent/scripts/skill-audit.sh` |
| Rules 密度扫描 | `.agent/scripts/score-rules.sh` |
| Skills 密度扫描 | `.agent/scripts/score-skills.sh` |
| Workflows 密度扫描 | `.agent/scripts/score-workflows.sh` |
| Escalation 状态机实现 | `.agent/scripts/escalation-tracker.sh` |
| Graphify 初始化脚手架 | `.agent/scripts/setup-graph.sh` |
| 压测量化评分引擎 | `.agent/scripts/stress-test-engine.sh` |
| 本能系统程序化管理 | `.agent/scripts/instinct-manager.sh` |
| 会话开始恢复 | `.agent/scripts/session-start.sh` |
| 会话结束收尾 | `.agent/scripts/session-end.sh` |

## 4. 规则矩阵 (Rule Matrix)

| 场景 | 规则文件 |
|---|---|
| 通用编码风格 | `.agent/rules/code-style.md` |
| 代码审查与质量门禁 | `.agent/rules/code-review.md` |
| 安全基线 | `.agent/rules/security.md` |
| 红线与禁区 | `.agent/rules/red-lines.md` |
| 测试编写与执行纪律 | `.agent/rules/testing.md` |
| 临时分析脚本自造边界 | `.agent/rules/tool-creation.md` |

## 5. 运行时状态文件 (Runtime State)

| 产物 | 用途 |
|---|---|
| `.agent/.escalation-state` | 当前压力等级、失败计数、方法论切换 |
| `.agent/state/context-essentials.md` | 压缩后回注的核心约束 |
| `.agent/state/tacit-tradition-map.md` | 项目隐性传统与约定 |
| `.agent/state/review_checklist.md` | 审查期辅助清单 |
| `.agent/state/memory-palace/README.md` | 失败模式和记忆宫殿说明 |
| `.agent/state/captured-patterns/README.md` | 项目已捕获模式说明 |

## 6. 钩子脚本入口 (Hook Script Inventory)

| Hook | 文件 | 作用 |
|---|---|---|
| Post-Tool | `.agent/hooks/post-tool/guard-enforcer.sh` | 守护回归与 guard 纪律 |
| Post-Tool | `.agent/hooks/post-tool/memory-update.sh` | 更新记忆沉淀 |
| Post-Tool | `.agent/hooks/post-tool/overconfidence-detector.sh` | 检测“未验证即完成” |
| Post-Tool | `.agent/hooks/post-tool/polanyi-persist.sh` | 持久化 tacit tradition |
| Post-Tool | `.agent/hooks/post-tool/reasoning-relay-check.sh` | 校验 deep-think 推理接力产物 |
