# Agentic Dev Kit

> 把 AI 从「会写代码的助手」升级为「遵守工程纪律的开发团队成员」的可移植规范套件

**30 秒安装 · 零配置 · 支持 Antigravity IDE / Gemini CLI**

---

## ⚡ 30 秒快速开始

```bash
# 1. 复制到你的项目
cp AGENT.md /path/to/your-project/
cp -r .agent /path/to/your-project/

# 2. 打开项目，在 AI 聊天框输入
/init
```

就这两步。AI 会自动扫描项目、生成定制配置，然后你就可以开始用了。

---

## 🗺️ 这是什么

| 没有这套规范时 | 有这套规范后 |
|---|---|
| AI 直接写代码，跳过需求确认 | 每次新功能先挑战需求假设，再确认方案 |
| 不会写测试或测试覆盖率极低 | 强制先写测试（TDD），覆盖率目标 80%/95% |
| Bug 修复靠猜，越改越乱 | Iron Law：先找根因再修复，3次失败就质疑架构 |
| 跨会话丢失上下文 | 自动状态保存 + 交接备忘录 + 断点恢复协议 |
| AI 声称完成但没真正验证 | 证据先行：必须运行命令看到输出才算完成 |
| 规范越堆越多导致 AI 退化 | 持续学习 + 定期进化 + 合规压测闭环 |

**核心机制**：四阶段 SOP（调研 → 契约 → 编码 → 验证）+ 结构化规格 + 闭环检查点 + 持续学习

---

## 🏛️ 架构总览

本规范由 **5 层** 组成，从上到下依次为：

```
┌─────────────────────────────────────────────────────────┐
│  AGENT.md  — 逻辑路由表（告诉 AI 什么场景读什么文件）       │
├─────────────────────────────────────────────────────────┤
│  Skills（技能）— 行为规范和领域知识（27 个）                │
├─────────────────────────────────────────────────────────┤
│  Workflows（工作流）— /命令 触发的标准步骤（21 个）         │
├─────────────────────────────────────────────────────────┤
│  Agents（专职代理）— 可委派的子 Agent（5 个）              │
├─────────────────────────────────────────────────────────┤
│  Rules（规则）— 编码规范 + 安全基线（4 个 + 自进化）       │
│  Scripts（脚本）— 自动化辅助（4 个）                       │
└─────────────────────────────────────────────────────────┘
```

### 加载策略

| 级别 | 含义 | 何时加载 |
|---|---|---|
| 🔴 **始终加载** | 每次会话必须读取 | 会话开始时（AGENT.md + session-start.sh） |
| 🟠 **主动加载** | AI 按场景自动加载 | 检测到匹配场景时（如开始编码 → world_class_coding） |
| 🟡 **命令加载** | 用户执行 `/命令` 时加载 | 用户主动触发 |
| 🟢 **按需加载** | 使用特定功能时加载 | 特定命令触发（如 `/config-scan` → config-security） |
| 🔵 **自然语言** | 用自然语言描述需求时自动匹配 | 说「加个动画」→ animate |

---

## 🎯 命令速查表

### 日常开发（高频）

| 命令 | 用途 | 重要度 |
|---|---|---|
| `/new-feature` | 启动新功能开发（自动走 4 阶段 SOP） | 🔴 核心 |
| `/debug` | 中立 Bug 排查（强制无偏见提示词） | 🔴 核心 |
| `/review` | 对抗式代码审查（专家 A → 辩手 B → 裁判 C） | 🔴 核心 |
| `/test` | 补写测试（覆盖率目标 80%/95%） | 🔴 核心 |
| `/tdd` | TDD 开发（Red-Green-Refactor 循环） | 🔴 核心 |

### 会话管理

| 命令 | 用途 | 重要度 |
|---|---|---|
| `/checkpoint` | 保存当前进度（Phase/文件/测试/决策） | 🟠 重要 |
| `/handoff` | 生成交接备忘录 → 自动执行 session-end 钩子 | 🟠 重要 |
| `/resume` | 恢复上下文 → 自动执行 session-start 钩子 | 🟠 重要 |
| `/context-reset` | 清理上下文污染并按协议恢复 | 🟡 辅助 |
| `/hooks` | 管理会话生命周期钩子（status/run/clean） | 🟢 进阶 |

### 自主迭代（高级）

| 命令 | 用途 | 重要度 |
|---|---|---|
| `/autoresearch` | 自主迭代优化（覆盖率/性能/包大小等指标） | 🟠 重要 |
| `/autoresearch:security` | OWASP + STRIDE 安全审计 + 自动修复 | 🟠 重要 |
| `/autoresearch:fix` | 自动修复 lint/类型/构建/测试错误直到归零 | 🟠 重要 |
| `/autoresearch:debug` | 自主 Bug 猎手（科学方法 + 迭代追查） | 🟠 重要 |
| `/autoresearch:ship` | 发布流程（PR/部署/内容发布 8 阶段） | 🟡 辅助 |

### 持续学习与进化

| 命令 | 用途 | 重要度 |
|---|---|---|
| `/learn` | 从当前会话提取编码模式，保存为本能（instinct） | 🟠 重要 |
| `/instinct` | 本能管理（status / import / export / prune） | 🟡 辅助 |
| `/evolve` | 定期规则清理 + 本能升级 + 聚类为 Skill | 🟠 重要 |
| `/stress-test` | 合规压测（8 项评分，满分 100） | 🟡 辅助 |

### 规格与项目管理

| 命令 | 用途 | 重要度 |
|---|---|---|
| `/spec:propose` | 创建规格驱动的变更提案 | 🟡 辅助 |
| `/spec:archive` | 归档已完成变更 | 🟡 辅助 |
| `/finish` | 分支收尾（测试 + 文档同步 + merge/PR） | 🟠 重要 |
| `/init` | 新项目初始化 | 🟡 首次 |

### 安全与审计

| 命令 | 用途 | 重要度 |
|---|---|---|
| `/config-scan` | 扫描 Agent 配置文件的安全风险（A-F 评级） | 🟢 进阶 |
| `/harness-audit` | 配置健康度审计 + Token 效率 + 模型路由建议 | 🟢 进阶 |
| `/skill-create` | 从 Git 历史提取编码模式生成 Skill（新项目冷启动） | 🟢 进阶 |

---

## 🧠 技能系统详解

### Tier 1 — 核心技能（AI 自动识别并加载）

| 技能 | 触发场景 | 作用 |
|---|---|---|
| `world_class_coding` | 编码/重构/TDD/Debug | **所有工作流的行为基础**：四阶段 SOP + TDD + 对抗验收 + 检查点 |
| `code-graph` | 影响分析/依赖查询 | 代码图谱：blast radius + 8 种查询 + 精准文件选择 |
| `spec-driven` | 规格管理/行为契约 | RFC 2119 + Given/When/Then + delta specs 增量管理 |
| `autoresearch` | 自主迭代/安全审计/发布 | 修改→验证→保留/回滚→重复，支持有界 `Iterations: N` |
| `frontend-design` | 前端 UI 开发 | 生产级界面创建（真实设计原则，非泛化 AI 美学） |
| `polish` | 上线前检查 | 质量门禁 |
| `audit` | 无障碍/性能审计 | 全面审计 |
| `adapt` | 响应式适配 | 跨设备适配 |
| `harden` | UI 健壮性 | 错误处理/i18n/溢出 |
| `continuous-learning` | 每次会话 | 📦 **新增** — 本能提取 + 置信度评分 + 自动升级规则 |
| `hooks-lifecycle` | 每次会话 | 📦 **新增** — 自动状态保存/恢复（session-start/end 钩子） |
| `doc-lookup` | Phase 1 调研 | 📦 **新增** — 结构化文档检索（项目内 + 依赖 API） |

### 按需加载技能（使用对应命令时加载）

| 技能 | 触发命令 | 作用 |
|---|---|---|
| `config-security` | `/config-scan` | 📦 **新增** — Agent 配置安全扫描（密钥/权限/注入检测，A-F 评级） |
| `skill-creator` | `/skill-create` | 📦 **新增** — 从 Git 提交历史提取编码模式，生成 Skill 草稿 |

### Tier 2 — 微调技能（自然语言触发）

> 用自然语言描述需求即可自动加载：

```
animate     ← 「给这个卡片加微交互动画」
colorize    ← 「优化配色，建立色彩体系」
bolder      ← 「视觉冲击力不够」
quieter     ← 「设计太重了」
delight     ← 「加一些愉悦感」
distill     ← 「太复杂了，帮我精简」
clarify     ← 「优化文案」
critique    ← 「评估这个设计」
normalize   ← 「统一 Token 规范」
extract     ← 「提取为组件」
optimize    ← 「性能优化」
onboard     ← 「设计引导流」
```

---

## 🤖 专职 Agent 委派

> 📦 **新增** — 可委派的专职 Sub-Agent，每个有限定的工具集和职责。

| Agent | 职责 | 限定工具 | 适用场景 |
|---|---|---|---|
| `planner` | Phase 1 技术规格规划 | Read, Search, List | 需求分析、影响评估 |
| `reviewer` | 代码审查（A/B/C 对抗） | Read, Grep, Search | 并行审查 |
| `tester` | 测试编写和运行 | Read, Write, Execute | 并行测试 |
| `security-reviewer` | 安全审查（OWASP/STRIDE） | Read, Grep, Search | 安全审计 |
| `doc-updater` | 文档同步 | Read, Write, Search | 变更后文档更新 |

> **使用原则**：并行任务（如同时 review + 写文档）时委派更高效。简单顺序任务使用主 Agent 即可。

---

## 🔄 持续学习系统

> 📦 **新增** — Agent 越用越懂你的项目。

```
┌─────────────┐     ┌──────────────┐     ┌───────────────┐
│  /learn     │────▶│  本能提取     │────▶│  pending.yml  │
│  会话中提取  │     │  confidence=1 │     │  .agent/      │
└─────────────┘     └──────────────┘     │  instincts/   │
                                         └───────┬───────┘
                                                 │ 多次会话验证
                                                 ▼
┌─────────────┐     ┌──────────────┐     ┌───────────────┐
│  /evolve    │────▶│  自动升级     │────▶│  .agent/      │
│  定期进化    │     │  confidence=5 │     │  rules/*.md   │
└─────────────┘     └──────────────┘     └───────────────┘
```

| 置信度 | 条件 | 动作 |
|---|---|---|
| 1 | 首次出现 | 记录观察 |
| 3 | 2 个会话验证 | 标记候选 |
| 5 | 5+ 个会话验证 | **自动升级为正式规则** |

**工作流**：开发 → `/learn` 提取 → 定期 `/evolve` 升级 → `/instinct prune` 清理过期

---

## 🔗 会话生命周期钩子

> 📦 **新增** — 自动状态保存/恢复，不再依赖手动 `/checkpoint`。

| 钩子 | 触发时机 | 脚本 | 作用 |
|---|---|---|---|
| session-start | 会话开始 / `/resume` | `.agent/scripts/session-start.sh` | 发现最新检查点 + git 状态 + 本能状态 |
| session-end | 会话结束 / `/handoff` | `.agent/scripts/session-end.sh` | 自动生成 auto-checkpoint |

> 钩子是**安全网**，不替代手动 `/checkpoint`。当你忘记保存时提供最低限度的状态保留。

---

## 📁 项目结构

```
AGENT.md                       ← 复制到项目根目录（AI 路由表，<200 行有效内容）
AGENT.local.md                 ← 个人本地偏好（自动加入 .gitignore）
.agent/
├── skills/                    ← 技能（27 个，AI 按场景自动加载）
│   ├── world_class_coding/    ← 🔴 核心编码规范
│   ├── code-graph/            ← 🟠 代码知识图谱
│   ├── spec-driven/           ← 🟠 规格驱动开发
│   ├── autoresearch/          ← 🟠 自主迭代优化（含 security/ship/fix/debug）
│   ├── continuous-learning/   ← 🟠 📦 持续学习系统
│   ├── hooks-lifecycle/       ← 🟠 📦 会话生命周期钩子
│   ├── doc-lookup/            ← 🟠 📦 文档检索
│   ├── config-security/       ← 🟢 📦 配置安全扫描（/config-scan 时按需加载）
│   ├── skill-creator/         ← 🟢 📦 Git 历史技能生成（/skill-create 时按需加载）
│   ├── frontend-design/       ← 🟠 前端 UI 开发
│   └── [12 个前端子技能]/     ← 🔵 animate/audit/polish 等（自然语言触发）
├── workflows/                 ← 工作流（21 个，/命令 触发）
│   ├── new-feature.md         ← /new-feature        🔴 核心
│   ├── debug.md               ← /debug              🔴 核心
│   ├── review.md              ← /review             🔴 核心
│   ├── test.md / tdd.md       ← /test / /tdd        🔴 核心
│   ├── checkpoint.md          ← /checkpoint          🟠 重要
│   ├── handoff.md             ← /handoff             🟠 重要
│   ├── resume.md              ← /resume              🟠 重要
│   ├── finish.md              ← /finish              🟠 重要
│   ├── evolve.md              ← /evolve              🟠 重要
│   ├── learn.md               ← /learn               🟠 📦 持续学习
│   ├── instinct.md            ← /instinct            🟡 📦 本能管理
│   ├── hooks.md               ← /hooks               🟢 📦 钩子管理
│   ├── config-scan.md         ← /config-scan         🟢 📦 配置安全
│   ├── harness-audit.md       ← /harness-audit       🟢 📦 健康审计
│   ├── skill-create.md        ← /skill-create        🟢 📦 技能生成
│   ├── init.md                ← /init                🟡 首次
│   ├── stress-test.md         ← /stress-test         🟡 定期
│   ├── context-reset.md       ← /context-reset       🟡 辅助
│   ├── spec-propose.md        ← /spec:propose        🟡 辅助
│   └── spec-archive.md        ← /spec:archive        🟡 辅助
├── agents/                    ← 📦 专职代理（5 个，可委派）
│   ├── planner.md             ← 技术规划
│   ├── reviewer.md            ← 代码审查
│   ├── tester.md              ← 测试
│   ├── security-reviewer.md   ← 安全审查
│   └── doc-updater.md         ← 文档同步
├── rules/                     ← 规则（按文件路径自动匹配）
│   ├── code-style.md          ← 代码风格
│   ├── code-review.md         ← 审查标准
│   ├── testing.md             ← 测试规范
│   └── security.md            ← 安全基线
├── scripts/                   ← 自动化脚本
│   ├── health-check.sh        ← 定量健康检查
│   ├── setup-graph.sh         ← 代码图谱初始化
│   ├── session-start.sh       ← 📦 会话启动钩子
│   └── session-end.sh         ← 📦 会话结束钩子
└── instincts/                 ← 📦 本能数据（自动生成，建议加入 .gitignore）
    ├── pending.yml            ← 活跃本能
    └── promoted.yml           ← 已升级归档
```

---

## 🔧 定制化

### 添加项目专属规则

在 `AGENT.md` 底部 `## 项目规则` 区域添加，或在 `.agent/rules/` 创建独立规则文件（支持 `paths` 路径范围限定）：

```yaml
---
description: API 开发规则
paths:
  - "src/api/**/*.py"
---
- 所有端点必须包含输入验证
- 使用标准错误响应格式
```

### 个人偏好覆盖

创建 `AGENT.local.md`（自动加入 `.gitignore`），添加个人偏好而不影响团队配置。

### 大型项目 / Monorepo

```
project-root/
├── AGENT.md          ← 全局规则
├── .agent/           ← 全局技能 + 工作流 + 规则
├── frontend/
│   └── AGENT.md      ← 前端特有规则（覆盖全局）
└── backend/
    └── AGENT.md      ← 后端特有规则（覆盖全局）
```

---

## 🔄 规范自维护

| 周期 | 行动 | 命令 |
|---|---|---|
| 每次会话结束 | 提取本次编码模式 | `/learn` |
| 每 2-4 周 | 清理规则 + 升级本能 + 去重 | `/evolve` |
| 规则超过 20 条 | 必须清理合并 | `/evolve` |
| 每月 / `/evolve` 后 | 合规压测（8 项评分，满分 100） | `/stress-test` |
| 上下文被污染 | 清理并恢复 | `/context-reset` |
| 定期 | 检查配置安全 + 完整性 | `/config-scan` + `/harness-audit` |
| 新项目接入 | 从 Git 历史冷启动规范 | `/skill-create` |

---

## ⚙️ 支持环境

| 环境 | 状态 |
|---|---|
| **Antigravity IDE（桌面版）** | ✅ 全功能支持，`/命令` 在聊天框输入 |
| **Gemini CLI** | ✅ 全功能支持，`/命令` 在终端输入 |

> 复制文件到项目根目录后，AI 自动识别并加载，无需任何额外配置。

---

## 📚 延伸阅读

本套件融合了以下框架的精华：

- [How To Be A World-Class Agentic Engineer](https://github.com/spidersea/agentic) — 核心方法论
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — 持续学习、Hooks、Sub-Agent、配置安全
- [Anthropic CLAUDE.md 规范](https://docs.anthropic.com/claude-code) — 规则系统设计
- [OpenSpec](https://github.com/Fission-AI/OpenSpec/) — 规格驱动开发
- [code-review-graph](https://github.com/tirth8205/code-review-graph) — 代码知识图谱
- [gstack](https://github.com/garrytan/gstack) — 工程效能哲学（Boil the Lake）
- [superpowers](https://github.com/obra/superpowers) — 计划可执行性标准
