# AGENTS.md · Agentic 开发规范

> 本目录是开发规范仓库。agentic-dev-kit/ 是可复制到项目的模板。

## 知识复利系统

已集成到 `agentic-dev-kit/` 模板中。新项目执行 `cp agentic-dev-kit/AGENTS.md . && cp -r agentic-dev-kit/.agent .` 后即获得：

- **AGENTS.md**：会话开始自动执行 memory-protocol + dreaming 检查
- **.agent/memory/**：6 文件记忆库（session / user / project / patterns / decisions / domain）
- **.agent/memory/.dreaming-log.md**：每小时自动 dreaming 触发

依赖的全局 Skill（需部署到 `~/.codex/skills/`）：
- memory-protocol v4.0
- dreaming v3.0
- hooks-lifecycle v1.0
- quality-operating-system v1.0
- continuous-learning v1.0
