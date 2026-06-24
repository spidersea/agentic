# AGENTS.md · Agentic 开发规范

> 本目录是开发规范仓库。agentic-dev-kit/ 是可复制到项目的模板。

## 知识复利系统

已集成到 `agentic-dev-kit/` 模板中。新项目执行 `cp agentic-dev-kit/AGENTS.md . && cp -r agentic-dev-kit/.agent .` 后即获得：

- **AGENTS.md**：会话开始自动执行 memory-protocol + dreaming 检查
- **.agent/memory/**：6 文件记忆库（session / user / project / patterns / decisions / domain）
- **.agent/memory/.dreaming-log.md**：每小时自动 dreaming 触发
- **.agent/scripts/loop-health.sh**：循环工程健康检查与 evidence ledger
- **.agent/scripts/safe-rollback.sh**：破坏性回滚前置防护
- **.agent/scripts/hook-self-test.sh**：post-tool hook 兼容性自测
- **.agent/scripts/loop-terminal-verdict.sh**：连续 PASS 证据后的终态判定
- **.agent/hooks/post-tool/**：兼容 Codex Desktop 工具名的失败/记忆/Polanyi/过度自信探针
- **.agent/automations/**：loop-health 与有写入能力 automation 的风险接受模板

依赖的全局 Skill（需部署到 `~/.codex/skills/`）：
- memory-protocol v4.0
- dreaming v3.0
- hooks-lifecycle v1.0
- quality-operating-system v1.0
- continuous-learning v1.0

## 终态循环工程入口

复制模板后，项目可用以下命令验证规范栈是否可运行：

- `bash .agent/scripts/loop-health.sh --record .`
- `bash .agent/scripts/hook-self-test.sh`
- `bash .agent/scripts/safe-rollback.sh status`
- `bash .agent/scripts/loop-terminal-verdict.sh 7`

终态不是一次检查通过，而是 `loop-health.sh --record` 在连续观察窗口内持续 PASS，且没有未接受的 WARN/CRITICAL。
