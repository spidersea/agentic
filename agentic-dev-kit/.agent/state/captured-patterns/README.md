# Captured Patterns — 项目级经验积累库

> 隐性知识的沉淀池。每次 Polanyi Excavation、Adversary 攻击、Escalation 中发现的**项目特有模式**
> 都应以 pattern 文件沉淀在此目录中，成为 Agent 的"长期记忆"。

## Pattern 文件格式

```yaml
---
id: CP-001
name: Redis 连接未保护
category: infrastructure  # infrastructure | auth | data | performance | concurrency | logic
severity: high            # critical | high | medium | low
discovered: 2026-04-10
source: polanyi-excavation  # polanyi-excavation | adversary-attack | escalation-l3 | manual
---

## 触发条件
当代码中使用 Redis 但未在初始化阶段检查连接状态时触发。

## 检测模式
```bash
grep -rn "redis\|Redis\|ioredis\|createClient" --include="*.ts" --include="*.js" --include="*.py"
```

## 证据
- `src/cache/index.ts:12` — 直接调用 `redis.get()` 但未捕获 ECONNREFUSED
- `src/cache/index.ts:1` — 未在 module 级别 await 连接就绪

## 应对策略
1. 添加连接就绪检查 (`redis.ping()`)
2. 包装所有 Redis 操作为 try-catch + fallback
3. 添加健康检查端点验证 Redis 可用性

## 历史出现
- 2026-04-08: 首次发现于 escalation L3
- 2026-04-10: Polanyi excavation 确认为隐性规则
```

## 目录结构

```
captured-patterns/
├── README.md          ← 本文件
├── CP-001-*.md        ← 各 pattern 文件
├── CP-002-*.md
└── tacit-snapshot-*.md ← Polanyi Hook 自动归档的快照
```

## 积累协议

| 来源 | 写入条件 | 写入方式 |
|------|---------|---------|
| Polanyi Excavation | 发现新的隐性规则 | 手动创建 pattern 文件 |
| Adversary 攻击 | 发现项目特有漏洞模式 | Adversary 报告后由主 Agent 沉淀 |
| Escalation L3+ | 七项检查清单触发的新发现 | 主 Agent 自动沉淀 |
| polanyi-persist.sh Hook | tacit-tradition-map 更新时 | 自动归档快照到本目录 |

## 读取时机

- **autoresearch Setup Phase**: Step 2 Polanyi Excavation 前加载已有 patterns
- **Adversary Agent**: 攻击前扫描已有 patterns 避免重复发现
- **上下文恢复**: AGENT.md Step 4 memory-palace 读取时联动读取
