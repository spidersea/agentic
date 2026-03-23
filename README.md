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

## 🗺️ 这是什么，解决什么问题

| 没有这套规范时 | 有这套规范后 |
|---|---|
| AI 直接写代码，跳过需求确认 | 每次新功能先挑战需求假设，再确认方案 |
| 不会写测试或测试覆盖率极低 | 强制先写测试（TDD），覆盖率目标 80%/95% |
| Bug 修复靠猜，越改越乱 | Iron Law：先找根因再修复，3次失败就质疑架构 |
| 跨会话丢失上下文 | 标准化交接备忘录 + 断点恢复协议 |
| 引入不需要的依赖或版本 | 禁止未授权依赖，引入前必须验证 CVE |
| 代码改了但文档没更新 | `/finish` 前自动 diff 文档，同步 README/CHANGELOG |
| AI 声称完成但没真正验证 | 证据先行：必须运行命令看到输出才算完成 |

**核心机制**：四阶段 SOP（调研 → 契约 → 编码 → 验证）+ 结构化规格（spec）+ 闭环检查点

---

## 🎯 日常使用——你只需要记住这几个命令

### 开发新功能（最常用）

```
/new-feature
```

AI 会自动走完整流程：
1. **前提挑战** — 主动质疑需求假设（「你要加弹窗，但真正要解决的问题是什么？」）
2. **需求确认** — 每次只问一个问题 + 必须提 2-3 个方案对比
3. **规格文档** — 自动创建 `openspec/` 变更文件夹（proposal + specs + design + tasks）
4. **计划拆分** — 每个任务含完整代码 + 精确命令 + 预期输出（可直接粘贴执行）
5. **编码验证** — 每完成一个模块立即跑测试，不等到最后再统一验证
6. **闭环验收** — 测试全绿 + 契约核验 + 文档同步 → 提交你审批
7. **分支收尾** → 自动调用 `/finish`

### 排查 Bug

```
/debug
```

强制流程：分析 → 声明范围边界（防止改出边界）→ 3次修复失败自动质疑是否架构问题 → 举一反三扫描同类问题

> 需要自主持续扫描整个仓库的 bug？用 `/autoresearch:debug`（无界迭代直到干净）

### 代码审查

```
/review
```

三角审查：**专家 A** 找所有风险点 → **辩手 B** 逐条反驳 → **裁判 C** 根据证据裁定真实问题列表

### 写测试 / TDD

```
/test     ← 补写现有代码的测试（覆盖率目标 80%/95%）
/tdd      ← 先写测试再写代码（Red-Green-Refactor 循环）
```

### 跨会话保存 & 恢复

```
/checkpoint    ← 保存当前进度（Phase/文件/测试/决策）
/handoff       ← 生成交接备忘录（含 git commit hash + 可执行下一步）
/resume        ← 新会话恢复（精确感知检查点后的代码变化）
```

> 标准流程：完成阶段性工作 → `/checkpoint` → 下次开新会话 → `/resume`

### 自主优化（高级）

```
/autoresearch              ← 自主迭代优化（覆盖率/性能/包大小等指标）
/autoresearch:security     ← OWASP + STRIDE 安全审计 + 自动修复
/autoresearch:fix          ← 自动修复 lint/类型/构建/测试错误直到归零
/autoresearch:ship         ← 发布流程（PR/部署/内容发布）
```

### 规范维护

```
/evolve        ← 每 2-4 周清理规则（触发率分析 + git 效能指标 + 去重）
/stress-test   ← 每月合规压测（8 项自动评分，满分 100）
/init          ← 新项目初始化（自动检测技术栈 + 生成定制配置）
/context-reset ← 上下文被污染时清理恢复
/finish        ← 分支收尾（测试验证 + 文档同步 + merge/PR/keep/discard）
```

---

## 🏗️ 技能系统

### 核心编程技能（自动加载）

| 技能 | 作用 |
|---|---|
| `world_class_coding` | **所有工作流的行为基础**：四阶段 SOP + TDD + 对抗验收 + 检查点 + Boil the Lake 完整性原则 |
| `code-graph` | 影响分析（blast radius）+ 8 种依赖查询 + 精准文件选择（≤5个）。未安装时自动降级 |
| `spec-driven` | 规格驱动开发：RFC 2119 + Given/When/Then + delta specs 增量管理 |
| `autoresearch` | 自主迭代：修改→验证→保留/回滚→重复，支持 `Iterations: N` 有界迭代 |

### 全栈前端技能

**Tier 1 — 高频场景（AI 主动识别加载）**

| 技能 | 何时使用 |
|---|---|
| `frontend-design` | 创建生产级 UI（遵循真实设计原则，不是泛化 AI 美学） |
| `audit` | 无障碍 / 性能 / 响应式 全面审计（建议在 `/review` 后使用）|
| `adapt` | 跨设备响应式适配 |
| `harden` | 错误处理、i18n、文本溢出、边界情况强化 |
| `polish` | **上线前最后一步**——全面质量门禁 |

**Tier 2 — 微调场景（自然语言触发，说需求即可）**

```
animate     ← 「给这个卡片加微交互动画」
colorize    ← 「帮我优化配色，建立色彩体系」
bolder      ← 「视觉冲击力不够，关键元素不突出」
quieter     ← 「设计太重了，太抢眼」
delight     ← 「加一些愉悦感和个性触感」
distill     ← 「太复杂了，帮我精简」
clarify     ← 「优化按钮文案和错误提示」
critique    ← 「从 UX 角度评估这个设计」
normalize   ← 「统一 Token、间距、颜色规范」
extract     ← 「把这段 UI 提取成可复用组件」
optimize    ← 「加载太慢，渲染性能有问题」
onboard     ← 「设计引导流和空状态页面」
```

---

## 📁 项目结构

```
AGENT.md                    ← 复制到项目根目录（AI 路由表，<80行有效内容）
AGENT.local.md              ← 个人本地偏好（自动加入 .gitignore）
.agent/
├── skills/                 ← 技能（AI 按场景自动加载）
│   ├── world_class_coding/ ← 核心编码规范
│   ├── code-graph/         ← 代码知识图谱
│   ├── spec-driven/        ← 规格驱动开发
│   ├── autoresearch/       ← 自主迭代优化
│   ├── frontend-design/    ← 前端 UI 开发
│   └── [17 个前端子技能]/  ← animate/audit/polish 等（按需调用）
├── workflows/              ← 工作流（/命令 触发）
│   ├── new-feature.md      ← /new-feature
│   ├── debug.md            ← /debug
│   ├── review.md           ← /review
│   ├── test.md / tdd.md    ← /test / /tdd
│   ├── checkpoint.md       ← /checkpoint
│   ├── handoff.md          ← /handoff
│   ├── resume.md           ← /resume
│   ├── finish.md           ← /finish
│   ├── evolve.md           ← /evolve
│   ├── init.md             ← /init
│   ├── spec-propose.md     ← /spec:propose
│   ├── spec-archive.md     ← /spec:archive
│   ├── stress-test.md      ← /stress-test
│   └── context-reset.md    ← /context-reset
└── rules/                  ← 规则（按文件路径自动匹配）
    ├── code-style.md       ← JS/TS/Python/Go/Rust 代码风格
    ├── code-review.md      ← 6 维度审查标准
    ├── testing.md          ← 测试规范
    └── security.md         ← 安全基线 + 供应链规则

# autoresearch 运行时产物（建议加入 .gitignore）
security/  debug/  fix/  ship/
```

---

## ⚙️ 支持环境

| 环境 | 状态 |
|---|---|
| **Antigravity IDE（桌面版）** | ✅ 全功能支持，`/命令` 在聊天框输入 |
| **Gemini CLI** | ✅ 全功能支持，`/命令` 在终端输入 |

> 复制文件到项目根目录后，AI 自动识别并加载，无需任何额外配置。

---

## 🔧 定制化

### 添加项目专属规则

在 `AGENT.md` 底部的 `## 项目规则` 区域添加：

```markdown
## 项目规则
- 本项目使用 Python 3.12 + FastAPI
- 所有 API 必须有 OpenAPI 文档
- 当编写 API 代码时 → 读取 `.agent/rules/api-conventions.md`
```

或在 `.agent/rules/` 创建独立规则文件（支持 `paths` 路径范围限定）：

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

## 🔄 规范自维护建议

| 周期 | 行动 | 命令 |
|---|---|---|
| 每次发现 AI 不良行为 | 添加一条针对性规则 | 手动编辑 `AGENT.md` 或 `.agent/rules/` |
| 每 2-4 周 | 清理规则（触发率分析 + git效能指标）| `/evolve` |
| 规则超过 20 条 | 必须清理合并 | `/evolve` |
| 每月 / `/evolve` 后 | 合规压测（8 项，满分 100）| `/stress-test` |
| 上下文被污染 | 清理并恢复 | `/context-reset` |

---

## 📚 延伸阅读

本套件融合了以下框架的精华：

- [How To Be A World-Class Agentic Engineer](https://github.com/spidersea/agentic) — 核心方法论
- [Anthropic CLAUDE.md 规范](https://docs.anthropic.com/claude-code) — 规则系统设计
- [OpenSpec](https://github.com/Fission-AI/OpenSpec/) — 规格驱动开发
- [code-review-graph](https://github.com/tirth8205/code-review-graph) — 代码知识图谱
- [gstack](https://github.com/garrytan/gstack) — 工程效能哲学（Boil the Lake）
- [superpowers](https://github.com/obra/superpowers) — 计划可执行性标准
