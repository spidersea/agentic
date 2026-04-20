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

### 工作流字典 (Workflows)
- `/init`: 初始化项目
- `/new-feature`: 4阶段开发
- `/debug`: 中立 Debug
- `/review`: 对抗式代码审查 (A/B/C)
- `/tdd`: 红绿重构开发
- `/checkpoint` / `/handoff` / `/resume`: 会话节点管理
- `/evolve`: 规则清洁
- `/context-reset`: 记忆重置
- `/spec:propose` / `/spec:archive`: 规格驱动开发提案与归档
- `/autoresearch:*` : 涵盖 security, ship, fix, review 等自主循环。
- `/hooks` : 生命周期干预
- `/escalate`: 压力攀升测试

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
