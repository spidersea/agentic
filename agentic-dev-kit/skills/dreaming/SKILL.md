---
name: dreaming
description: 梦境记忆整理协议 v3.0 — Stage-Aware 记忆整理、Stage 推进评估、Failure Pattern 聚合分析。含自动备份、SHA追踪、回滚、幻觉防御和健康检查。
version: 3.0.0
---

# 梦境记忆整理协议（Dreaming Protocol）v3.0

> v3.0 新增：Stage-Aware 整理（不再只看置信度，而是看知识推进阶段）、
> Stage 推进评估（何时从 Stage 1→3、3→4、标记 Stage 5）、
> Failure Pattern 聚合分析（按 Failure Class 聚类）。

---

## 触发方式

用户说 `$dreaming` 或 `执行 dreaming` 或 `整理记忆`。

推荐频率：活跃项目每周一次；或任一 memory 文件超 300 行。

---

## 第零步 · Backup（强制）⚠️

```
cp -r .agent/memory/ .agent/memory/.backups/$(date +%Y-%m-%d-%H%M%S)/
for f in .agent/memory/*.md; do shasum -a 256 "$f"; done > .agent/memory/.pre-dreaming-sha256
```

---

## 第一步 · Cut（裁剪）— Stage-Aware

逐文件扫描。**关键变化**：不以置信度为唯一判据，而是结合 Stage 判断。

| 判定条件 | 动作 |
|---|---|
| Stage 1 且 60 天未被引用、无后续 Stage 推进 | → **可删除**（线索未发展成知识） |
| Stage 1-2 且有矛盾的新记忆（Stage 3+）覆盖 | → **标记删除**，保留新版本 |
| Stage 3 但触发条件已不存在（如废弃的技术栈） | → **标记删除** |
| Stage 3 但内容已被 Stage 4 泛化版本覆盖 | → **标记删除**（或标记为 Stage 5 归档） |
| Stage 4 且用户明确确认过 | → **不可删除** |
| 内容模糊，无法指导行动，无论 Stage | → **标记删除或合并** |
| 置信度 high 但从未在实际会话中被引用 | → ⚠️ **待确认**（标签与行为不一致） |

**新增：Stage 推进建议**

在 Cut 过程中，同时评估哪些记忆可以推进 Stage：

| 条件 | 建议 |
|---|---|
| Stage 1 记忆在 3+ 会话中被观察到 | → 建议推进到 Stage 2（Investigated） |
| Stage 2 记忆已有明确的复现条件和根因 | → 建议推进到 Stage 3（Verified） |
| Stage 3 记忆在 2+ 不同场景中得到验证 | → 建议推进到 Stage 4（Generalized） |
| Stage 4 记忆在过去 30 天 Agent 自动遵循、无需显式引用 | → 建议标记 Stage 5（Indwelled） |

---

## 第二步 · Add（补充）

与 v2.0 相同逻辑，新增：
- 补充记忆时标注初始 Stage（通常 Stage 1-2）
- 如能确定 Failure Class，一并标注

---

## 第三步 · Organize（重组）

新增重组维度：

1. **Stage 分布平衡**：某个文件是否 Stage 1-2 过多（>"线索堆积"）？需要推动验证
2. **Failure Pattern 聚类**：相同 Failure Class 的条目是否分散？建议聚合
3. **推进链完整性**：同一 topic 的 Stage 1→3→4 链条是否完整？断裂处标注

---

## 第四步 · Stage 推进评估（新增）

这是 v3.0 的核心新增——Dreaming 不只是清理，更是**推进知识**。

逐条检查 Stage 1-3 的记忆，给出推进建议：

```markdown
## Stage 推进建议

### 可推进到 Stage 3（Verified）
- 「CI e2e checkout 超时」· Stage 1 → 3
  - 证据：已在 4 次会话中复现，复现条件明确（webhook + checkout 并发）
  - 建议动作：写入复现条件为 Verified fact，关闭调查

### 可推进到 Stage 4（Generalized）
- 「修改 schema 后必须 codegen」· Stage 3 → 4
  - 证据：在 Query/Mutation/Fragment 三类 schema 变更中均验证
  - 建议动作：泛化规则为"任何 schema 变更后必须 codegen"

### 可标记 Stage 5（Indwelled）
- 「用户偏好先确认范围再动手」· Stage 4 → 5
  - 证据：Agent 在过去 30 天默认执行此行为，从未被纠正
  - 建议动作：标记为已内化，从活跃 memory 归档到 .agent/memory/.archive/
```

**推进规则**：
- Stage 推进是**追加**不是覆盖——旧 stage 的记忆保留作为"推进链"证据
- ⚠️ 推进必须用户确认——Dreaming 只建议，不自动执行
- 如果用户拒绝推进，记录拒绝原因（可能是 dreaming 误判）

---

## 第五步 · Failure Pattern 聚合分析（新增）

按 Failure Class 聚合所有 patterns.md 中 Stage 1-4 的失败条目：

```markdown
## Failure Pattern 聚合

### flake（偶发失败）— 3 条
- Stage 1: CI e2e checkout 超时（webhook 竞态）
- Stage 2: Windows runner 偶发 TLS 错误（已定位到 PowerShell 版本）
- Stage 3: npm install 偶发超时（已确认 registry 延迟，加了 retry）

### deterministic（可复现）— 2 条
- Stage 3: ALTER 大表超时 → 规则：迁移必须 batch
- Stage 4: 中间件顺序错误 → 规则：auth 必须在 cors 之前

### config（配置问题）— 1 条
- Stage 3: codegen 未运行 → 规则：schema 变更后必须 codegen

### 聚合洞察
- flake 类占 50%，其中 2/3 已定位根因 → 建议优先推进到 Stage 3
- deterministic 类的两条均已 Stage 3+，质量良好
- 缺少 infra 类失败 → 基础设施稳定或未被记录
```

---

## 第六步 · Sanity Check（幻觉防御闸门）

与 v2.0 相同的 5 道闸门，新增：

| 闸门 | 检查内容 |
|---|---|
| **Stage 一致性** | 推进建议的 Stage 是否与证据匹配？不能凭空将 Stage 1 跳级到 Stage 4 |
| **推进链完整** | 推进后的记忆是否标注了来源 Stage？是否保留了旧 Stage 的记录？ |

---

## 变更执行与 SHA 追踪

同 v2.0：用户确认 → 执行变更 → 计算 post-dreaming SHA256 → diff 对比。

---

## 回滚路径

同 v2.0：从 `.backups/` 恢复。

---

## 执行后：Dreaming 日志 + 健康报告

```markdown
# .agent/memory/.dreaming-log.md

## YYYY-MM-DD Dreaming 记录

### Stage 变更统计
- Stage 推进：1→3: X 条 / 3→4: Y 条 / 4→5 归档: Z 条
- 新增：A 条 (Stage 1: a / Stage 3: b)
- 删除：C 条

### Failure Pattern 分布
- flake: X / deterministic: Y / config: Z / infra: A / human: B / unknown: C

### 健康指标
- 总条目数：XX
- Stage 分布：1:X% / 2:Y% / 3:Z% / 4:A% / 5:B%
- 🔴 Stage 1>40%：线索堆积，需要推动验证
- 🟢 Stage 3+ >60%：知识库健康
```

---

## 安全规则（v3.0 强化）

- ❌ 不删除 Stage 4+ 且用户确认过的记忆
- ❌ 不跳过 Stage 直接推进（Stage 1 不能直接到 Stage 4）
- ❌ 不在没有备份的情况下执行任何变更
- ❌ 不在没有用户确认的情况下执行变更
- ✅ Stage 推进保留旧记录（追加不覆盖）
- ✅ Failure Pattern 聚合不过度简化（保留个例细节）

---

## 与 memory-protocol v3.0 的接口

```
memory-protocol (In-Band)          dreaming (Out-of-Band)
─────────────────────────         ────────────────────────
写入 Stage 1-4 的记忆       →    评估推进到下一个 Stage
写入 Failure Class          →    聚合 Failure Pattern
更新 session.md             →    检查 session.md 是否
                                  与实际推进一致
不做删除/重组               ←    Cut/Add/Organize/推进
```
