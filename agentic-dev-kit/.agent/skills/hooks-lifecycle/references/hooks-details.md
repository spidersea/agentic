---
description: 会话生命周期钩子详细协议与插件配置 (从 SKILL.md 下沉)
---

# 钩子挂载与通信细节 (Hooks Details)

## 1. PostToolUse (命令检测与持久化)

**失败检测逻辑**:
检查 exit code ≠ 0 或包含 `Error:`, `FAILED`, `Exception`, `Permission denied`, `fatal:` 等字样。
若失败则累加失败计数。连续 2 次 L1，连续 3 次 L2。

**持久化 `.escalation-state.json` 格式**:
```json
{
  "level": "L2",
  "consecutive_failures": 3,
  "methodology": "搜索优先",
  "methodologies_exhausted": ["RCA根因分析"],
  "hypotheses_eliminated": ["JWT check"],
  "session_id": "abc-123"
}
```
*必须在计数或等级变化时写入，并在 session-start 或 PreCompact 时读取。*

## 2. PreCompact 与 主动压缩 (Proactive Compaction)

**PreCompact 快照要求**:
在上下文窗口截断前，将关键进展以 Markdown 写出：
```markdown
# 压缩前状态快照
- Escalation 等级: L{0-4} (见 .escalation-state.json)
- 当前活跃任务: ...
- 已尝试/已排除: ...
```
**主动压缩触发标准**: 上下文 > 60% 满，或 autoresearch 超过 10 次，或阶段切换。
必须带强制保留范围：`/compact 保留：当前任务、压力等级、回归命令、修改但未提交文件列表`。

## 3. PostCompact (记忆回注)
压缩后必须强制重新读取 `.agent/state/context-essentials.md`（不超过 50 行），并在其内动态更新“当前任务边界”。

## 4. Claude Code `.claude/hooks.json` 映射

```json
{
  "hooks": {
    "SessionStart": [{"command": "bash .agent/scripts/session-start.sh"}],
    "SessionEnd": [{"command": "bash .agent/scripts/session-end.sh"}],
    "PostToolUse": [{
      "matcher": {"tool_name": "bash"},
      "command": "bash .agent/scripts/post-tool-check.sh"
    }]
  }
}
```

## 5. MCP(模型上下文协议) 与 Plugin 扩展点

- 推荐 MCP：GitHub, Filesystem, Search, Postgres. (通过 `mcp add` 挂载，限 stdio)。
- Plugin 映射：
  - `.agent/skills/` 对应 `skills/`
  - `.agent/agents/` 对应角色包
  - `.agent/rules/` 对应 `CLAUDE.md` 规则注入
