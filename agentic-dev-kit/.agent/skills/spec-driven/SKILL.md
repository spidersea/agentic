---
name: spec-driven
description: 规格驱动开发（SDD）— 在编码之前通过行为规格与人类达成一致，结构化防控 AI 幻觉。融合 OpenSpec 框架精华。
---

# 规格驱动开发技能 (Spec-Driven Development)

> 基于 [OpenSpec](https://github.com/Fission-AI/OpenSpec/) 框架的核心理念，
> 融入 agentic-dev-kit 的四阶段 SOP 体系。
> 核心原则：**先达成一致，再编写代码。**

---

## 第一章：核心理念

### 1.1 为什么需要规格层

AI 编码助手在没有明确规格时容易产生幻觉：
- 需求仅存在于聊天记录中，随对话推进逐渐模糊
- AI 凭"理解"编码，但理解可能与用户意图不一致
- 修改行为缺乏可追溯性——不知道"系统原本应该怎么工作"

**规格层**解决这些问题：在代码之前建立一份结构化的行为契约，作为"系统当前如何工作"的单一事实来源。

### 1.2 设计哲学

| 原则 | 说明 |
|---|---|
| **fluid not rigid** | 没有阶段门禁，随时可回溯修改任何产物 |
| **iterative not waterfall** | 边建边学，规格随实现发现的新信息而更新 |
| **easy not complex** | 默认轻量级（Lite Spec），高风险时升级为完整规格 |
| **brownfield-first** | 适配已有代码库，使用增量规格（Delta Specs）而非全量重写 |

---

## 第二章：规格层 (Specs Layer)

### 2.1 目录结构

```
openspec/
├── specs/                          ← 主规格（系统行为的事实来源）
│   ├── auth/
│   │   └── spec.md
│   ├── payments/
│   │   └── spec.md
│   └── ui/
│       └── spec.md
├── changes/                        ← 活跃变更（每个功能一个文件夹）
│   ├── add-dark-mode/
│   │   ├── .openspec.yaml
│   │   ├── proposal.md
│   │   ├── specs/ui/spec.md        ← delta spec
│   │   ├── design.md
│   │   └── tasks.md
│   └── archive/                    ← 已归档变更（审计轨迹）
│       └── 2025-01-24-add-dark-mode/
└── config.yaml                     ← 可选：项目级配置
```

### 2.2 规格格式 (Spec Format)

规格文件描述**可观测行为**，不包含实现细节：

```markdown
# Auth Specification

## Purpose
应用程序的身份认证与会话管理。

## Requirements

### Requirement: 用户认证
系统 SHALL 在登录成功后签发 JWT 令牌。

#### Scenario: 有效凭据
- GIVEN 用户持有有效凭据
- WHEN 用户提交登录表单
- THEN 返回 JWT 令牌
- AND 用户被重定向到仪表板

#### Scenario: 无效凭据
- GIVEN 无效的凭据
- WHEN 用户提交登录表单
- THEN 显示错误信息
- AND 不签发令牌

### Requirement: 会话过期
系统 MUST 在 30 分钟无操作后使会话失效。

#### Scenario: 空闲超时
- GIVEN 一个已认证的会话
- WHEN 30 分钟内无操作
- THEN 会话被标记为无效
- AND 用户必须重新认证
```

### 2.3 RFC 2119 关键词

| 关键词 | 含义 | 使用场景 |
|---|---|---|
| **MUST / SHALL** | 绝对要求，不可违反 | 核心功能、安全约束 |
| **SHOULD** | 推荐实现，例外需要理由 | 最佳实践、性能优化 |
| **MAY** | 可选实现 | 增强功能、UI 偏好 |

### 2.4 规格准则

**规格 IS**：
- 用户或下游系统可依赖的可观测行为
- 输入、输出和错误条件
- 外部约束（安全、隐私、兼容性）
- 可被测试或验证的场景

**规格 IS NOT**：
- 内部类/函数名
- 库或框架选择
- 逐步实现细节（属于 `design.md` 或 `tasks.md`）

> **快速判断**：如果实现可以变化而外部可见行为不变，那它就不属于规格。

### 2.5 渐进严格度 (Progressive Rigor)

| 级别 | 默认？ | 适用场景 | 内容深度 |
|---|---|---|---|
| **Lite Spec** | ✅ 默认 | 绝大多数变更 | 简短行为描述 + 范围 + 几个验收检查 |
| **Full Spec** | 手动升级 | 跨团队变更、API/合约变更、安全/隐私变更 | 完整 Requirements + Scenarios + 边界条件 |

---

## 第三章：变更管理 (Change Management)

### 3.1 变更文件夹

每次功能开发对应一个独立的变更文件夹，包含 4 个产物（Artifacts），按依赖链排列：

```
proposal ──────► specs ──────► design ──────► tasks ──────► implement
    │               │             │              │
   why            what           how          steps
 + scope        changes       approach      to take
```

#### Proposal (`proposal.md`) — 回答"为什么"

```markdown
# Proposal: 添加深色模式

## Intent
用户在夜间使用时反馈眼睛疲劳，希望支持深色模式和系统偏好跟随。

## Scope
包含：
- 设置中的主题切换开关
- 系统偏好检测
- localStorage 持久化

不包含：
- 自定义颜色主题（后续工作）
- 按页面单独设置主题

## Approach
使用 CSS 自定义属性实现主题切换，React Context 管理状态。
首次加载检测系统偏好，允许手动覆盖。
```

#### Delta Specs (`specs/`) — 回答"变什么"

增量描述行为变更，使用 ADDED/MODIFIED/REMOVED 标记：

```markdown
# Delta: UI Specification

## ADDED

### Requirement: 主题选择
系统 SHALL 允许用户在浅色和深色主题之间切换。

#### Scenario: 手动切换
- GIVEN 用户在设置页面
- WHEN 用户点击主题切换开关
- THEN 界面立即切换为所选主题
- AND 偏好保存到 localStorage
```

#### Design (`design.md`) — 回答"怎么做"

技术方案和架构决策。

#### Tasks (`tasks.md`) — 回答"做哪些步骤"

实施清单，与四阶段 SOP 的任务分解一致：

```markdown
# Tasks

## 1. 主题基础设施
- [ ] 1.1 创建 ThemeContext
- [ ] 1.2 添加 CSS 自定义属性
- [ ] 1.3 实现 localStorage 持久化

## 2. UI 组件
- [ ] 2.1 创建 ThemeToggle 组件
- [ ] 2.2 添加系统偏好检测
```

### 3.2 归档 (Archive)

变更完成后执行归档：
1. 检查 tasks.md 完成状态
2. 将 delta specs 合并回 `openspec/specs/`
3. 变更文件夹移动到 `openspec/changes/archive/YYYY-MM-DD-<name>/`

> 归档后，主规格成为更新后的事实来源。审计轨迹保留在 archive 中。

### 3.3 并行变更

多个变更可同时进行，各自独立。当两个变更修改同一规格时，通过检查实际代码实现来解决冲突。

---

## 第四章：与四阶段 SOP 的融合

规格驱动开发与现有四阶段 SOP 互补，不替代：

```
                  ┌──────────────────────────────────────┐
                  │         规格驱动层 (Spec Layer)        │
                  │                                      │
Phase 1 调研 ────►│ /spec:propose → proposal + delta specs│
                  │ + design + tasks                     │
                  └──────────┬───────────────────────────┘
                             │
Phase 2 契约 ────────────────┤  验收契约基于 specs 中的场景
                             │
Phase 3 编码 ────────────────┤  严格按 tasks.md 逐项实现
                             │
Phase 4 验证 ────────────────┤  三维验证 + 对抗审查
                             │
              ────────────────┤
归档 ────────►│ /spec:archive → delta 合并 + 审计归档    │
              └──────────────────────────────────────────┘
```

### 4.1 三维验证 (Three-Dimensional Verification)

归档前执行三维度检查（与 `/review` 的对抗审查互补）：

| 维度 | 验证内容 |
|---|---|
| **完整性 (Completeness)** | 所有任务完成、所有需求已实现、场景已覆盖 |
| **正确性 (Correctness)** | 实现匹配规格意图、边界条件已处理 |
| **一致性 (Coherence)** | 设计决策反映在代码中、命名模式一致 |

---

## 第五章：使用指南

### 5.1 何时使用规格驱动

| 场景 | 推荐做法 |
|---|---|
| 新功能开发（≥3 文件） | ✅ 使用 `/spec:propose` 启动 |
| 简单 bug 修复、配置修改 | ❌ 直接修复，无需规格 |
| API 或公共接口变更 | ✅ 强烈推荐，升级为 Full Spec |
| 架构重构 | ✅ 必须使用，含完整场景覆盖 |
| 已有 openspec/ 目录的项目 | ✅ 自动检测并融入现有规格 |

### 5.2 初始化

在项目根目录创建 `openspec/` 目录结构：

```bash
mkdir -p openspec/specs openspec/changes
```

或在 `/new-feature` 流程中，当判断变更范围适合规格驱动时，Agent 自动创建。

### 5.3 命令速查

| 命令 | 用途 |
|---|---|
| `/spec:propose <name>` | 创建变更并生成全部规划产物 |
| `/spec:archive [name]` | 归档完成的变更，合并 delta 到主规格 |

### 5.4 规格维护建议

- 每次归档后检查主规格是否仍然清晰、无矛盾
- 过时的规格条目应标记为 DEPRECATED 或移除
- 当 specs 目录下文件超过 10 个时，考虑按领域重组
