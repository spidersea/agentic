# AGENTS.md · 知识复利系统

> 本文件由 agentic-dev-kit 提供。复制到项目根目录后，Codex 自动加载。

## ⚠️ 会话开始 · 强制执行序列

每次会话开始时，在回答用户任何问题之前，必须依次执行：

### Step 1: 加载 memory-protocol Skill
读取 `skills/memory-protocol/SKILL.md`，加载记忆读写协议和 5-Stage Progression。

### Step 2: 检查是否需要 Dreaming
先解析记忆路径：优先项目 `.agent/memory/`；如果当前工作区没有项目记忆，使用全局 `~/.codex/memories/`；旧路径 `~/.codex/memory/` 只读兼容迁移，不再写入。

读取当前记忆根目录下的 `.dreaming-log.md`。
- 距上次 ≥ 1 小时 → **立即自动执行 dreaming**
- 从未 dreaming + 条目 ≥ 8 → **立即自动执行 dreaming**
- 否则跳过

如触发 dreaming：加载 `skills/dreaming/SKILL.md` → 备份 → Cut → Add → Organize → Stage 推进 → 聚合 → Sanity Check → 更新日志。

### Step 3: 读取项目记忆
读取 `.agent/memory/session.md`（断点续跑）+ 全部 memory 文件。

### Step 4: 加载项目上下文
读取 `AGENT.md`，执行已有的上下文恢复协议和路由规则。

### Step 5: 开始工作

---

## 会话中 · 自动行为

| 触发 | 动作 | 目标文件 |
|---|---|---|
| 被用户纠正 | 写入 Stage 3+ 记忆 | user.md |
| 发现隐性规则 | 写入 Stage 3+ 记忆 | project.md |
| 遇到失败 | 写入 Stage 1-2 + Failure Class | patterns.md |
| 3+ 次复现的教训 | Skills Compound | 对应 Skill |

## Loop Engineering · 运行时防护

- 每次修改后用证据闭环，不用信心闭环。
- 终端/命令失败由 `.agent/hooks/post-tool/` 识别，必须兼容 `run_command`、`exec_command`、`functions.exec_command`、`bash`、`Execute` 等工具名。
- 写入类 hook 必须兼容 `apply_patch`、`functions.apply_patch`、`write_to_file`、`replace_file_content`、`multi_replace_file_content`、`Write`。
- 破坏性回滚必须先通过 `.agent/scripts/safe-rollback.sh status` 或 autoresearch 的 agent-owned worktree 条件；不满足时只允许 `git revert`、局部反向 patch 或停止并报告 dirty files。
- 每日或长循环中运行 `bash .agent/scripts/loop-health.sh --record .` 记录 evidence。
- 只有 `bash .agent/scripts/loop-terminal-verdict.sh 7` 在足够连续 PASS 证据下通过，才允许称为循环工程终态。

## 会话结束 · 强制写入

更新 `.agent/memory/session.md`：完成了什么 / 待继续 / 下次起点。
