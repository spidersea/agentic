# Changelog

本项目遵循 [Semantic Versioning](https://semver.org/) 和 [Keep a Changelog](https://keepachangelog.com/) 规范。

## [1.1.0] - 2026-03-25

### Added
- **CLI 工具** (`bin/agentic`): 支持 `init`, `validate`, `health`, `stress-test`, `version` 子命令
- **框架结构验证器** (`validate-structure.sh`): 7 类 17 项自动化检查
- **压力升级状态机** (`escalation-tracker.sh`): 程序化 L0-L4 状态管理 + 文件持久化
- **量化评分引擎** (`stress-test-engine.sh`): 5 维度 100 分制评分，输出 A-F 评级
- **本能管理器** (`instinct-manager.sh`): list/add/score/promote/prune 子命令
- **自动化测试套件** (`tests/`): 4 套件，20+ 断言，覆盖语法/结构/状态机/健康检查
- **Makefile**: `make test`, `make validate`, `make health`, `make stress-test`, `make lint`
- **参考项目** (`examples/demo-project/`): 端到端 SOP 演示
- **平台适配文档** (`docs/platform-adapters.md`): Cursor, VS Code, Aider 适配指南
- **贡献指南** (`CONTRIBUTING.md`)
- **README 实际示例**: 6 个对话式使用示例（折叠展示）

### Changed
- **README.md**: 新增开发者工具章节、更新文件树、更新维护清单
- **agentic-dev-kit/README.md**: 新增 CLI/Makefile 文档、更新目录结构

## [1.0.0] - 2026-03-24

### Added
- 四阶段 SOP（Research → Contract → Execution → Verification）
- Phase 0 复杂度自动路由（🟢轻量 / 🟡标准 / 🔴完整）
- 28 个 Skill（含 `world_class_coding`, `escalation`, `continuous-learning` 等）
- 22 个 Workflow（含 `/new-feature`, `/debug`, `/review`, `/autoresearch` 等）
- 5 个专职 Agent（planner, reviewer, tester, security-reviewer, doc-updater）
- 5 个规则文件（code-style, code-review, testing, security, red-lines）
- 4 个自动化脚本（session-start, session-end, health-check, setup-graph）
- 压力升级系统（L1-L4）+ 三条红线
- 持续学习系统（本能提取 + 置信度评分）
- 会话生命周期钩子（自动存档/恢复）
- CP-1 到 CP-4 检查点协议
