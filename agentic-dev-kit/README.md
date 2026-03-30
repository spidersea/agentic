# Agentic Dev Kit — 可移植 AI 开发规范套件

## 这是什么？

一套标准化的 AI 智能体开发规范，可直接复制到任何项目中使用。基于 "How To Be A World-Class Agentic Engineer" 原则、CLAUDE.md 开发体系精华、业界共识和最新的 AGENT.md 开放标准提炼。

**核心能力**:
- 📋 四阶段标准操作流程（Research → Contract → Execution → Verification）
- ⛳ 可持续检查点协议（CP-1 ~ CP-4），支持断点续作和跨会话交接
- 🛡️ 防御性提示设计（角色锚定、输出约束、不确定性声明）
- ⚔️ 对抗验收模式（Expert A / Opponent B / Referee C）
- 🏗️ 通用架构纪律（代码设计、错误处理、安全基线）
- 🔄 规则自进化协议（反馈捕获、退化检测、Spa Day 清理）
- 📁 模块化规则系统（路径范围限定、渐进式加载、本地覆盖）
- 🚦 TDD 编程范式（Red-Green-Refactor 循环、适用场景指南、反模式清单）

## 目录结构

```
AGENT.md                              ← 复制到项目根目录（逻辑路由表）
AGENT.local.md                        ← 个人本地覆盖（加入 .gitignore）
Makefile                              ← 一键命令入口（make test / validate / health）
bin/
└── agentic                           ← CLI 工具（init / validate / health / stress-test）
tests/                                ← 🧪 自动化测试（4 套件，20+ 断言）
├── test-all.sh                       ← 测试 Runner
├── test-scripts-syntax.sh            ← 脚本语法检查
├── test-validate-structure.sh        ← 结构验证器测试
├── test-escalation-tracker.sh        ← 状态机行为测试（11 cases）
└── test-health-check.sh              ← 健康检查测试
.agent/
├── skills/
│   ├── world_class_coding/           ← 核心编码技能（四阶段 SOP、TDD、对抗验收）
│   │   └── SKILL.md
│   ├── frontend-design/              ← 前端设计技能（生产级 UI 开发）
│   │   └── SKILL.md
│   ├── escalation/                   ← 失败压力升级（L1-L4）
│   ├── continuous-learning/          ← 持续学习（本能提取）
│   ├── hooks-lifecycle/              ← 会话生命周期钩子
│   ├── autoresearch/                 ← 自主迭代引擎（6 个子命令）
│   ├── code-graph/                   ← 代码知识图谱
│   ├── spec-driven/                  ← 规格驱动开发
│   ├── animate/ ~ teach-impeccable/  ← 12 个前端微调技能
│   └── ...                           ← 共 28 个技能
├── workflows/                        ← 📋 标准流程（22 个）
├── agents/                           ← 🤖 专职助手（5 个）
├── rules/                            ← 📏 规则文件（5 个）
│   ├── code-style.md                 ← 代码风格规则
│   ├── code-review.md                ← 代码审查标准
│   ├── testing.md                    ← 测试规范规则
│   ├── security.md                   ← 安全基线规则
│   └── red-lines.md                  ← 三条红线（绝对底线）
├── scripts/                          ← ⚙️ 自动化脚本（10 个）
│   ├── validate-structure.sh         ← 框架结构验证器（7 类 17 项检查）
│   ├── escalation-tracker.sh         ← 压力升级状态机（程序化 L0-L4）
│   ├── stress-test-engine.sh         ← 量化评分引擎（5 维度 100 分制）
│   ├── score-rules.sh                ← 规范库量化检测引擎 (基于系统、落地自动维度)
│   ├── score-workflows.sh            ← 工作流量化检测引擎 (100分制)
│   ├── score-skills.sh               ← 核心能力评分体系 (包含软词排查与终端沙箱要求)
│   ├── health-check.sh               ← 指令膨胀检测（Token 估算）
│   ├── session-start.sh              ← 会话启动检查
│   ├── session-end.sh                ← 会话结束自动保存
│   └── setup-graph.sh                ← 代码图谱初始化
└── instincts/                        ← 🧠 经验笔记（AI 学到的东西）
```

## 支持环境

| 环境 | AGENT.md | Skills | Workflows | Rules |
|---|---|---|---|---|
| **Antigravity IDE（桌面版）** | ✅ 自动加载 | ✅ 自动加载 | ✅ `/命令` 在聊天框输入 | ✅ 按路径自动匹配 |
| **Gemini CLI** | ✅ 自动加载 | ✅ 自动加载 | ✅ `/命令` 在终端输入 | ✅ 按路径自动匹配 |

> 不需要任何额外配置。复制文件到项目根目录后，AI 自动识别并加载。

## 快速开始

### 1. 复制到新项目

```bash
cp AGENT.md /path/to/your-project/
cp -r .agent /path/to/your-project/
```

也可以直接在 Finder 中拖拽复制，效果一样。

### 2. 初始化项目（推荐）

在聊天框中输入 `/init`，AI 会自动扫描项目并定制配置。

### 3. 打开项目，直接用

在 Antigravity IDE 中打开项目后，在聊天框中直接输入斜杠命令：

| 你想做什么 | 输入 | AI 会做什么 |
|---|---|---|
| 初始化配置 | `/init` | 扫描项目，生成定制化的 AGENT.md 和规则文件 |
| 开发新功能 | `/new-feature` | 自动走 4 阶段 SOP（调研→契约→编码→验收闭环） |
| 排查 Bug | `/debug` | 强制使用中立提示词，不预设偏见 |
| 审查代码 | `/review` | Expert A / Opponent B / Referee C 对抗审查 |
| 写测试 | `/test` | 按测试金字塔编写（单元→集成→E2E） |
| TDD 开发 | `/tdd` | 按 Red-Green-Refactor 循环驱动开发 |
| 保存进度 | `/checkpoint` | 生成标准检查点文件 |
| 暂停，下次继续 | `/handoff` → 关会话 → 新会话 `/resume` | 安全交接并恢复 |
| 清理规则膨胀 | `/evolve` | 盘点、去重、合并、清理 |
| 清理上下文 | `/context-reset` | 清理无关上下文，按协议恢复必要信息 |
| 量化指标升级 | `/autoresearch` | 核心引擎特性！对当前能力库执行自循环无损改造与 100 分机械护城河重塑 |

> **你不需要记住 SKILL.md 的全部内容。** AI 会自动加载。你只需要记住这几个 `/命令`。

### 技能分类速查 (Skills Catalog)

技能分为两大类，分别侧重代码开发和前端设计：

#### 编码方法论 (Coding Methodology)

| 技能 | 说明 | 调用方式 |
|---|---|---|
| `world_class_coding` | 核心编码技能：四阶段 SOP、TDD、对抗验收、检查点协议 | 自动加载（通过 AGENT.md 路由） |

#### 前端设计 (Frontend Design) — 来自 impeccable.style

> 这些技能可在聊天框中用自然语言调用，如：“帮我 animate 这个卡片组件”、“对首页做一次 audit”。

| 类别 | 技能 | 说明 |
|---|---|---|
| **创建** | `frontend-design` | 生产级 UI 开发，避免泛化 AI 美学 |
| **增强** | `animate` | 添加动画和微交互 |
|  | `colorize` | 添加战略性配色 |
|  | `bolder` | 放大视觉冲击力 |
|  | `delight` | 增加愉悦感和个性触感 |
| **精简** | `distill` | 剥离多余复杂度，回归精华 |
|  | `quieter` | 降低过于强烈的视觉设计 |
|  | `clarify` | 优化 UX 文案、错误信息、标签 |
| **审查** | `audit` | 无障碍、性能、主题、响应式全面审计 |
|  | `critique` | UX 视角的设计评估与反馈 |
| **适配** | `adapt` | 跨屏幕/设备/平台响应式适配 |
|  | `harden` | 错误处理、i18n、文本溢出、边界情况 |
|  | `normalize` | 统一到设计规范体系 |
| **提取** | `extract` | 提取可复用组件和设计 Token |
| **性能** | `optimize` | 加载速度、渲染、动画、图片优化 |
| **上线** | `polish` | 发布前的最终质量检查 |
| **引导** | `onboard` | 引导流、空状态、首次体验设计 |
| **初始化** | `teach-impeccable` | 一次性设置，收集项目设计上下文 |

### 4. 验证生效

观察 AI 是否：
- ✅ 开发前先进行技术调研，产出精确技术规格
- ✅ 编码前建立验收契约，定义可验证的成功标准
- ✅ 编码时按需加载文件（≤5 个），不引入未授权依赖
- ✅ 每个 Phase 完成后记录检查点
- ✅ 验证时使用中立提示词，不带预设偏见
- ✅ 在契约未完成前不宣布任务完成

### 5. 添加项目规则

在 `AGENT.md` 底部的"项目规则"区域添加：

```markdown
## 项目规则 (Project-Specific Rules)
- 本项目使用 Python 3.12 + FastAPI
- 所有 API 必须有 OpenAPI 文档
- 当编写 API 代码时 → 读取 `.agent/rules/api-conventions.md`
```

也可以创建独立规则文件到 `.agent/rules/` 目录，支持 `paths` frontmatter 路径范围限定：

```yaml
---
description: API 开发规则
paths:
  - "src/api/**/*.py"
---
# API 开发规则
- 所有端点必须包含输入验证
- 使用标准错误响应格式
```

### 6. 个人偏好覆盖

创建 `AGENT.local.md`（自动加入 `.gitignore`），添加个人偏好而不影响团队配置：

```markdown
# 个人配置覆盖
- 我偏好使用 Vim 风格的快捷键
- 代码注释使用中文
```

### 7. 层级嵌套（大型项目）

对于 monorepo 或大型项目，可在子目录中放置更具体的 `AGENT.md`：

```
project-root/
├── AGENT.md                    ← 全局规则
├── AGENT.local.md              ← 个人覆盖（.gitignore）
├── .agent/
│   ├── skills/...              ← 全局技能
│   ├── workflows/...           ← 全局工作流
│   └── rules/...               ← 全局规则文件
├── frontend/
│   └── AGENT.md                ← 前端特有规则（覆盖全局）
└── backend/
    └── AGENT.md                ← 后端特有规则（覆盖全局）
```

## CLAUDE.md 融合说明

本套件融合了 Anthropic CLAUDE.md 开发体系的精华理念：

| 来自 CLAUDE.md 的理念 | 在本套件中的实现 |
|---|---|
| `.claude/rules/` 路径范围规则 | → `.agent/rules/` + `paths` frontmatter |
| `@文件引用` 渐进式加载 | → AGENT.md 中的 `@文件引用` 语法 |
| `CLAUDE.local.md` 本地覆盖 | → `AGENT.local.md` 个人配置 |
| 多层级配置继承 | → 全局 → 项目 → 子目录 → 本地覆盖 |
| `/init` 初始化 | → `/init` 工作流 |
| `/clear` 上下文清理 | → `/context-reset` 工作流 |
| 厨房水槽、反复纠正等反模式命名 | → SKILL.md 第三章经典反模式 |

> 无论你之前使用 CLAUDE.md、Cursor Rules 还是其他 AI 编程规范，本套件的理念和机制都是兼容且互补的。

## 开发者工具

### CLI

```bash
bin/agentic init ./my-project    # 初始化新项目
bin/agentic validate             # 验证框架结构（17 项检查）
bin/agentic health               # 指令膨胀检测
bin/agentic stress-test          # 量化评分（满分 100）
```

### Makefile

```bash
make test           # 运行全量自动化测试（4 套件）
make validate       # 框架结构验证
make health         # 健康检查
make stress-test    # 量化评分
make lint           # 脚本语法检查
```

## 维护建议

| 周期 | 行动 | 快捷方式 |
|---|---|---|
| 每次发现 Agent 不良行为 | 添加一条针对性规则 | 手动编辑 AGENT.md 或 `.agent/rules/` |
| 每 2-4 周 | 整合清理规则，移除过时或矛盾的条目 | `/evolve` |
| 规则超过 20 条时 | 必须进行一次全面清理合并 | `/evolve` |
| 提交代码前 | 跑一遍自动化测试 | `make test` |
| 每月 | 检查框架结构和评分 | `make validate && make stress-test` |
| 上下文被不相关任务污染时 | 清理上下文并按协议恢复 | `/context-reset` |

> ⚠️ `AGENT.md` 总行数建议不超过 80 行有效内容。规则超过 5 条时，应拆分为独立的 `.agent/rules/*.md` 文件并通过路由引用。

