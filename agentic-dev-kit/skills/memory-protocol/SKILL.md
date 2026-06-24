---
name: memory-protocol
description: 知识复利系统编排者 v4.0 — 自动 Dreaming 触发器、会话钩子集成、质量门。整合 hooks-lifecycle + quality-operating-system + dreaming 为自动运行的知识复利系统。
version: 4.0.0
---

# 知识复利系统（Knowledge Compound System）v4.0

> 这不是一个 Skill，这是**系统的编排者**。
>
> v4.0 将 memory-protocol + hooks-lifecycle + quality-operating-system + dreaming
> 从散件焊成自动运行的知识复利引擎。
>
> 核心理念：用户不需要手动触发任何东西。Agent 在会话边界自动读写记忆、
> 自动判断 dreaming 时机、自动整理知识库。知识复利是默认行为，不需要记命令。

---

## 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                    知识复利系统 v4.0                          │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌───────────────┐  │
│  │ hooks-       │    │ memory-      │    │ quality-      │  │
│  │ lifecycle    │◄───│ protocol     │───►│ operating-    │  │
│  │              │    │ (编排者)      │    │ system        │  │
│  │ session-     │    │              │    │               │  │
│  │ start/end    │    │ 自动触发     │    │ 质量门        │  │
│  │ 强制写       │    │ dreaming     │    │ 审查 dreaming │  │
│  └──────────────┘    └──────┬───────┘    └───────────────┘  │
│                              │                               │
│                       ┌──────▼───────┐                       │
│                       │   dreaming   │                       │
│                       │  (自动执行)   │                       │
│                       └──────────────┘                       │
│                              │                               │
│                       ┌──────▼───────┐                       │
│                       │ .agent/      │                       │
│                       │ memory/      │                       │
│                       │ .backups/    │                       │
│                       └──────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

---

## 核心机制一：会话开始 · 自动 Dreaming 触发

> ⚠️ 这是 v4.0 最关键的变化：dreaming 不再需要手动 `$dreaming`。

### 自动触发逻辑（每次会话开始时执行）

Agent 在会话开始、加载本 Skill 后，**首先**检查 dreaming 触发条件：

```
Step 1: 读取 .agent/memory/.dreaming-log.md
Step 2: 提取最近一次 dreaming 的日期
Step 3: 计算距今天数
Step 4: 检查 memory 文件总行数
Step 5: 按以下规则决定是否触发 dreaming
```

| 条件 | 动作 |
|---|---|
| 距上次 dreaming ≥ 1 小时 | → **自动触发 dreaming**（不等用户说） |
| 距上次 dreaming ≥ 1 小时 且 任一 memory 文件 > 200 行 | → **自动触发 dreaming** |
| 距上次 dreaming < 1 小时 | → 跳过，进入正常会话 |
| 从未执行过 dreaming 且 总条目 ≥ 8 条 | → **自动触发 dreaming**（首次整理） |
| 从未执行过 dreaming 且 总条目 < 8 条 | → 跳过（数据太少不值得整理） |

### 自动执行流程

当触发条件满足时，Agent 按以下步骤自动执行：

```
1. 告知用户："距上次 dreaming 已 X 小时，记忆共 Y 条。正在自动整理..."
2. 加载 dreaming Skill 的完整流程
3. 执行 Step 0: 自动备份
4. 执行 Step 1-6: Cut → Add → Organize → Stage 推进 → Failure Pattern 聚合 → Sanity Check
5. 展示精简结果给用户（仅显示有变更的条目，零变更则一句话"记忆健康，无需整理"）
6. 用户确认变更 → 执行 → SHA 追踪 → 更新 .dreaming-log.md
7. 恢复正常会话流程
```

### 关键设计决策

- **不等用户说**：Agent 主动检查、主动触发。用户不需要记住 `$dreaming` 命令。
- **精简输出**：只有变更才展示细节。零变更时 Agent 说一句"记忆健康，无需整理"就继续。
- **用户确认保留**：Dreaming 的删除/推进建议仍需用户确认（安全底线），但触发不需要用户发起。
- **不阻塞会话**：如果用户有紧急任务，可以说"先跳过 dreaming 直接开始"。

---

## 核心机制二：会话结束 · 强制写入（集成 hooks-lifecycle）

### hooks-lifecycle 集成点

本 Skill 复用了 `hooks-lifecycle` 的两个钩子点：

| hooks-lifecycle 钩子 | 本系统的行为 |
|---|---|
| **session-start** | 读取全部 memory 文件 + 检查 dreaming 触发条件 |
| **session-end** | ⚠️ 强制更新 `session.md`（不可跳过） |

### session-end 强制执行

```
会话即将结束时，Agent 必须：
1. 总结本次完成了什么、待继续什么
2. 更新 session.md 的「最近会话」区域
3. 标注下次会话建议起点
4. 只有 session.md 写入完成后，会话才算真正结束
```

如果 Agent 遗忘此步骤，hooks-lifecycle 的 `session-end` 钩子会强制执行。

---

## 核心机制三：Dreaming 质量门（集成 quality-operating-system）

### 质量门集成

Dreaming 执行完毕后、向用户展示变更前，自动通过 quality-operating-system 的关卡：

| 质量门 | Dreaming 对应检查 |
|---|---|
| **Intake Gate** | Dreaming 的 Cut 建议是否每个都有明确的删除理由？ |
| **Test Gate** | Stage 推进建议是否有证据支持（复现次数、数据来源）？ |
| **Content Gate** | 新增/修改的记忆条目是否格式规范、字段完整？ |
| **Referee Gate** | Sanity Check 是否全部通过？有无矛盾或跳级？ |
| **Learning Gate** | 本次 dreaming 是否有至少 1 条可沉淀的跨会话洞察？ |

**通过标准**：5 门全过 → 展示变更给用户。任一门未过 → 自动修正确认后再展示。

### 首次 dreaming 初始化

如果 `.agent/memory/.dreaming-log.md` 不存在（首次使用），Agent 在会话开始时自动创建：

```markdown
# Dreaming Log

## 系统初始化 · YYYY-MM-DD
- 知识复利系统 v4.0 首次激活
- 下次自动 dreaming 将在 7 天后或记忆 ≥ 8 条时触发
```

---

## 知识推进模型：5-Stage Progression（继承 v3.0）

```
Stage 1: Observed      Stage 2: Investigated       Stage 3: Verified
"我注意到..."           "我在调查..."              "我已确认..."
      ↓                       ↓                          ↓
Stage 4: Generalized     Stage 5: Indwelled
"这条规则适用于..."      "已内化，归档"
```

各阶段定义、写入指引、推进规则与 v3.0 完全相同。详见 dreaming Skill。

---

## 存储结构

```
.agent/memory/
├── session.md           · Resume Pointer（每次会话结束强制更新）
├── user.md              · 用户偏好（Stage 标记）
├── project.md           · 项目规则（Stage 标记）
├── patterns.md          · 成功/失败模式（Stage + Failure Class）
├── decisions.md         · 技术决策（Stage 标记）
├── domain.md            · 领域知识
├── .dreaming-log.md     · Dreaming 执行日志（自动触发依据）
├── .archive/            · Stage 5 归档
└── .backups/            · 自动备份
```

---

## 读取策略（会话开始时执行）

1. 读取 `.dreaming-log.md`，判断是否触发自动 dreaming
2. 如触发 → 执行 dreaming 流程 → 完成后继续
3. 如不触发 → 读取 `session.md`（Resume Pointer）
4. 读取其他 memory 文件，建立完整上下文
5. 开始正常会话

---

## 写入协议（继承 v3.0 + 强化）

### 写入时机

| 场景 | 动作 |
|---|---|
| **会话结束** | ⚠️ 强制：更新 `session.md`（hooks-lifecycle 保障） |
| 用户纠正了你的理解 | 立即写入，Stage ≥ 3 |
| 发现项目特有隐性约定 | 立即写入，Stage ≥ 3 |
| 遇到未分类的失败 | 写入 patterns.md，Stage 1-2 + Failure Class |
| 验证了一个假设/修复 | 推进相关记忆 Stage，追加不覆盖 |
| 完成被认可的有效方案 | 会话结束时写入 |

### 写入格式

```markdown
### [记忆标题]

- **Stage**：1-5
- **Failure Class**（如适用）：flake / config / deterministic / infra / human
- **触发条件**：什么场景下激活
- **内容**：具体的知识、规则或教训
- **置信度**：high / medium / low
- **保鲜期**：数月 / 数周 / 数天
- **来源**：日期 + 事件
- **反例**（如有）：什么情况下不适用
```

---

## 判断原则

- **代价原则**：忘了多痛？→ 决定是否写
- **惊奇原则**：意外吗？→ 决定写什么
- **衰减原则**：能鲜多久？→ 标注保鲜期

---

## Failure Classification

| 分类 | 策略 |
|---|---|
| flake | 偶发 → 重试+记录 |
| config | 配置 → 写入隐性规则 |
| deterministic | 可复现 → 根因→修复→测试 |
| infra | 平台 → workaround |
| human | 操作 → 写入偏好 |

---

## Skills Compound 机制

条件满足（3+ 次复现 + 与 Skill 相关 + 用户确认）时，写入 Skill 末尾 `## 实战积累（Compound）` 区域。

---

## 与各 Skill 的分工

| Skill | 角色 | 触发 |
|---|---|---|
| **memory-protocol** | 编排者：读写记忆 + 自动触发 dreaming + 质量门 | 自动（AGENTS.md 加载） |
| **dreaming** | 执行者：Cut/Add/Organize/推进/聚合 | 自动（memory-protocol 触发） |
| **hooks-lifecycle** | 保障者：session-start/end 强制执行 | 自动（AGENTS.md 加载） |
| **quality-operating-system** | 审查者：dreaming 质量门 | 自动（dreaming 后触发） |
| **continuous-learning** | 互补者：代码模式提取 | 自动（AGENTS.md 加载） |

