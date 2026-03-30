# Agentic Dev Kit — 工业级可移植 AI 操作系统

## 这是什么？

这不是一份单纯的 Prompt 集合，而是一套**具有生命周期管理、反馈数据闭环与自动化量化护城河**的生产级 AI 代理研发标准基座。本框架提炼自 "How To Be A World-Class Agentic Engineer" 原则与 CLAUDE.md 开发体系，结合完全内置的 **P0 级底层系统**实现了 AI 的自我进化。

它致力于解决大模型工程中的核心挑战：上下文崩塌、幻觉滥造、指令遗忘以及执行边界模糊。

---

## 🚀 核心架构演变 (Core Capabilities)

目前的系统底层已完成全面跃迁，具备了比肩核心操作系统的完整自治管理能力：

1. **♾️ 自我进化流转网 (Data-Driven Evolve Loop)**
   - 告别凭感觉修改 Prompt。通过 `session-end.sh`，每一次操作的特征流都会被记录至 `skill-usage.tsv`，AI 基于量化热度对规则集执行 `/evolve` “淘汰、提取、降级”操作。
2. **🧬 本能萃取与晋升体系 (Instinct -> Skill Promotion)**
   - 不在 `AGENT.md` 中无限堆积长文。系统自动识别开发产生的业务模式（`Instincts/`），随后流转判断：代码强制底线自动送入 `rules/`，复杂的业务 SOP 自动提纯并路由进入 `skills/` 进行装载。
3. **⛓️ 压力拦截与退回系统 (PUA Escalation Archive)**
   - 包含严格的从 L0（无感修复）至 L4（强制跳出求援）的程序化状态机。处理瓶颈时，尝试失败的历史假设将强制归档至 `escalation-history/` 拦截图谱，确保 AI 在跨会话中不再重复踏入相同的逻辑错觉陷阱。
4. **⚖️ 涡轮全自动量化底盘 (Turbo Autoresearch Metrics)**
   - `Rules/` 和 `Skills/` 等所有文件执行前必须通过系统内置机械判定（包含 `score-skills.sh` 满分 100 分的强制检测），保障没有软弱的表述语句，杜绝口嗨。配合 `// turbo` 静默标记链，极大程度提升操作连贯性。
5. **📋 有界标准流程 (World-Class SOP)**
   - 铁面无私的四阶段开发法 (调研 → 契约 → 编码 → 验证)。未出测试结果与闭环承诺单前，不允许判定 `[x] 成功`。

---

## 📂 完全目录结构图解

```
AGENT.md                              ← 项目根指令路由表（大脑总控）
AGENT.local.md                        ← 个人本地覆盖（加入 .gitignore）
Makefile                              ← 面向人类的命令集合入口
bin/
└── agentic                           ← 独立 CLI 监测工具
tests/                                ← 🧪 自动化测试套件
├── test-all.sh
└── test-escalation-tracker.sh        ←...（20+ 测试断言）
.agent/
├── logs/
│   └── skill-usage.tsv               ← 📊 [系统生成] 技能调用次数指纹记录，用于后续淘汰
├── instincts/                        ← 🧠 临时态的本能日志、AI 踩过的坑
│   └── escalation-history/           ← 🚫 [系统生成] 曾让系统奔溃的错误排查路线黑名单
├── skills/                           ← 💡 固态专家技能表
│   ├── world_class_coding/           ← (100/100满分架构) SOP、TDD 和校验对抗核
│   ├── escalation/                   ← PUA 处理拦截网
│   ├── continuous-learning/          ← Instinct 智能清洗及技能树转化漏斗
│   ├── autoresearch/                 ← 自我逻辑 100 分满分进化推演工具
│   └── ...                           ← 共计 28 个微调与工程模块
├── workflows/                        ← 📋 标准执行动作 (20+)
│   ├── new-feature.md / debug.md     ← 带 // turbo 环境扫描挂载标记的主流程
│   └── evolve.md                     ← 数据主导的规则清理清道夫
├── rules/                            ← 📏 具有约束边界的硬指标禁令
│   ├── code-style.md                 ← 风格与编译警告检查
│   ├── testing.md / security.md      ← 合规审计红线
│   └── red-lines.md                  ← AI 的绝对越权底线
└── scripts/                          ← ⚙️ 系统指令环境（完全终端调用）
    ├── validate-structure.sh         ← 沙箱级的文件完整度扫描
    ├── escalation-tracker.sh         ← 拦截死锁的 L0-L4 升档器
    ├── stress-test-engine.sh         ← 全架构量化安全评分
    ├── score-rules.sh                ← [满分要求] 规范检测引擎
    ├── score-skills.sh               ← [满分要求] 各核心能力文件扫描引擎
    ├── score-workflows.sh            ← [满分要求] 工作流结构化执行力检测
    ├── session-start.sh              ← AI 苏醒自检脚本
    └── session-end.sh                ← 睡眠前调用（更新热力 tsv）
```

---

## 🚦 开始使用本操作台

### 1. 将大脑植入您的工程项目
```bash
cp AGENT.md /path/to/your-project/
cp -r .agent /path/to/your-project/
```

### 2. 通过指令链下令
AI 不再需要您灌输指令背景，您只需在聊天框直接触发「预设斜杠工作流」：

| 你想做什么 | 终端触发命令 | 幕后挂载的自动化机理 |
|---|---|---|
| 初始化项目与健康检测 | `/init` | 一键扫描文件结构，执行 `session-start` 并完成路由绑定 |
| 开发新功能 | `/new-feature` | 唤起 Phase 0~4 引擎（按文件改动动态决定由轻到重的测试规范），自动打 checkpoint |
| 排查 Bug 异常 | `/debug` | 禁闭预估偏见。若报错无解，自动引发 `/escalate` 进入记录档案，不再兜圈子 |
| 高级重构清理 | `/evolve` | **读取底层 skill-usage.tsv 记录**，按照使用频率杀掉或吸纳退化的规则组 |
| 跨难度强制求援 | `/escalate` | 触发 `escalation-tracker` 记表逻辑，把失败记录埋进黑历史库 |
| 自主能力提纯 | `/autoresearch` | **利用 `score-*.sh` 执行自我文件修正，维持满分的绝对护城河代码素质** |
| 设计打磨 | `/frontend-design` / `/audit` | 前端精细化 UX/UI 的安全着陆执行组 |

---

## 🔗 P0 核心: “生命体演进” 数据运转路线
大批量的规则与技能维护会导致 AI 最终表现为执行瘫痪（上下文毒药）。系统将自动以如下管线呼吸：

1. **产出期 (Output)**：工作完成并执行 `/handoff` 时，`session-end` 启动，扫描当前上下文使用了哪些指令。
2. **存档期 (TSV File)**：日志静默写入 `logs/skill-usage.tsv`，如果是失败链路，则打向 `escalation-history` 黑名单。
3. **清洗期 (Evolution)**：月末或规则臃肿发生异象时，使用 `/evolve`，AI 基于 TSV 热度记录精准剔除 0 调用项。
4. **固化期 (Continuous Learning)**：如果识别出高重用经验，走 `continuous-learning`，判断是否要晋级写入 `/rules` 或新建入 `/skills`。

---

## ☑️ 对抗合规与质量红线

所有对业务的修改动作和测试均遵守 `World-Class Coding` 中极度残忍的验证标准：
- **无 Mock 原则**：除了在业务验证的隔离测试内允许 Mock，只要跑主线业务，禁止虚造数据（如遇缺乏第三方环境不能推进，它应该走 Escalation 警报系统而不是造假数据往下混指标）。
- **对抗型 Referee 系统**：在排错或者复杂 Code Review 时，必须开启左手互搏：专家 A 敏锐列出可能风险 > 辩手 B 攻击反驳排除 > 裁判层 C 中立收集编译日志定论真实结果。
- **100/100 护城河**：该框架自身的规范体系保证绝对零宽泛语言。所有工作规范已跑通内检评测，不包含“尽量、可能”这种松散判定。

## ⚙️ 开发者环境

可通过以下指令进行 AI 开发时的本地辅助校验：
```bash
make test           # 运行底座自动化验证所有状态机
make validate       # 检查底层大脑架构的健康文件连接
make stress-test    # 对 AI 能力集做量化大考
```

## 个人化与集成

这套工具向下完全兼容 Anthropic 出品的 `CLAUDE.md` 开发架构精神。若是您需要个人独到风格的手法：
- 新建一份 `AGENT.local.md` (已默认忽略提交 Git)
- 如果是大规模层级的项目（Monorepo），请大胆地下放您的专员 `AGENT.md` 至如 `/frontend` 的子仓库内，他会自动与根目录下的全局系统达成规则继承妥协。
