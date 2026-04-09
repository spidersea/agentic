# Memory Palace — 持久化外部记忆

> 邪修六式：克服 AI 单轮幻灭（Single-Turn Amnesia）和上下文压缩丢失。
> 在文件系统中构建持久化的"外部记忆"，补偿上下文窗口的结构性限制。

## 文件结构

| 文件 | 用途 | 写入时机 |
|------|------|---------|
| `decisions.jsonl` | 每个重大决策的 why + context | 每次 write/edit 关键文件后 |
| `assumptions.jsonl` | 当前有效的假设列表 | 每轮推理开始时 |
| `failure-patterns.jsonl` | 已知的失败模式 | 命令失败时 |
| `attack-surface.md` | 当前系统的攻击面地图 | 安全审计后 |

## 数据格式

### decisions.jsonl
```json
{"ts": "2026-04-09T12:00:00Z", "file": "src/auth.ts", "action": "modify", "reason": "将 JWT 验证从中间件移至路由级别", "confidence": 0.85}
```

### assumptions.jsonl
```json
{"ts": "2026-04-09T12:00:00Z", "assumption": "Redis 连接池在应用启动时已初始化", "source": "src/db/init.ts:42", "verified": false}
```

### failure-patterns.jsonl
```json
{"ts": "2026-04-09T12:00:00Z", "cmd": "npm test", "error": "ECONNREFUSED 127.0.0.1:6379", "root_cause": "Redis 未启动", "resolution": "启动 Redis 后重试"}
```

## 使用协议

### 写入（自动）
- PostToolUse hook (`memory-update.sh`) 自动在关键操作后写入
- Escalation 事件自动记录到 `failure-patterns.jsonl`

### 读取（上下文恢复时）
- 会话开始 / 上下文压缩后，按以下优先级读取：
  1. `assumptions.jsonl` — 全部（当前有效的假设不可丢失）
  2. `decisions.jsonl` — 最后 10 条
  3. `failure-patterns.jsonl` — 最后 5 条
  4. `attack-surface.md` — 仅安全审计模式下读取
