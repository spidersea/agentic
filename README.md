# Agentic Dev Kit

> 让 AI 写代码时像一个**守规矩的工程师**，而不是一个想到哪写到哪的实习生。

---

## 🤔 这东西是干嘛的？

想象你有一个**非常聪明但很鲁莽的同桌**帮你写作业：
- 他写得很快，但经常不审题就开始写
- 他不检查答案，写完就说「好了」
- 第二天换个座位，他就忘了昨天聊了啥

**这套工具就是给他立的「规矩」**——让他每次写之前先想清楚，写完以后先检查，换座位也记得昨天做到哪了。

| 没规矩的 AI | 有了这套规矩 |
|---|---|
| 直接开写，不问你要什么 ✏️ | 先问你：「你真正想要的是什么？」🤔 |
| 不写测试，全靠猜 🎲 | 先写测试，再写代码 ✅ |
| 改 bug 靠碰运气 🍀 | 先找原因，再动手修 🔍 |
| 第二天就忘了昨天做了啥 😵 | 每次自动保存进度，下次能接着干 📋 |
| 说「改好了」但没真正检查 🤥 | 必须运行测试看到结果才算数 📊 |
| 碰壁了就说「我搞不定」🙅 | 强制穷尽一切方案，不放弃 💪 |
| 什么事都要问你确认 😵‍💫 | 简单任务直接做，复杂任务才确认 🧠 |

---

## ⚡ 怎么开始用？（只要 30 秒）

```bash
# 第 1 步：把这两样东西复制到你的项目文件夹
cp AGENT.md /你的项目路径/
cp -r .agent /你的项目路径/

# 第 2 步：打开项目，跟 AI 说
/init
```

**搞定。** AI 会自动扫描你的项目，然后就可以用了。

---

## 🎮 最常用的命令（记住这 5 个就够了）

这些命令就像游戏里的技能键——你输入命令，AI 就按标准流程执行。

### ⭐ 第一梯队：日常必备

| 你输入 | AI 会做什么 | 打个比方 |
|---|---|---|
| `/new-feature` | 智能判断复杂度，自动选择轻量/标准/完整流程 | 写作文：简单题直接写，难题先审题再写 🧠 |
| `/debug` | 智能判断 Bug 复杂度，简单 Bug 直接修 | 医生看病：小感冒直接开药，疑难杂症才做全套检查 🏥 |
| `/review` | 检查代码质量 | 作文互改：同学 A 找问题 → B 反驳 → 老师裁判 |
| `/test` | 给代码写测试 | 出练习题：写几道题检验代码对不对 |
| `/tdd` | 先写测试再写代码 | 先出试卷再学知识，更有方向 |

### 💾 第二梯队：保存和恢复

AI 和你聊天是有「记忆上限」的，就像白板写满了就得擦掉重来。这 3 个命令帮你保存进度：

| 你输入 | AI 会做什么 | 打个比方 |
|---|---|---|
| `/checkpoint` | 保存当前进度 | 游戏里的**存档** 💾 |
| `/handoff` | 打包交接给下一次聊天 | 交接班时的**工作日志** 📝 |
| `/resume` | 从上次的存档恢复 | 游戏里的**读档** 🔄 |

> 💡 **推荐流程**：做完一段工作 → `/checkpoint` → 下次新聊天 → `/resume`

### 🚀 第三梯队：自动化高级功能

| 你输入 | AI 会做什么 | 打个比方 |
|---|---|---|
| `/autoresearch` | 自动优化（改一下 → 测一下 → 好了留着，不好就撤） | 自动刷题机，刷到满分为止 |
| `/autoresearch:security` | 安全检查 + 自动修复 | 请保安巡逻一圈，把门窗漏洞堵上 |
| `/autoresearch:fix` | 修复所有报错直到零 | 把试卷上所有红叉都改成绿勾 |
| `/autoresearch:review` | 自动循环审查并修复代码直到无可挑剔 | 老师查出问题立刻强迫你改对，然后接着查 |
| `/autoresearch:debug` | 自动追踪 Bug 直到找到 | 侦探追凶，查到水落石出 |

### 🧠 第四梯队：让 AI 越用越聪明

| 你输入 | AI 会做什么 | 打个比方 |
|---|---|---|
| `/skill:capture` | 从刚才解决的复杂 Bug/任务中提取避坑指南，生成微型技能 | 提炼绝招**秘籍** 🥋 |
| `/learn` | 记住这次聊天中学到的经验 | 做完练习写**错题本** 📒 |
| `/evolve` | 清理和升级积累的经验 | 期末复习时**整理笔记** 📚 |
| `/instinct` | 管理已经学到的经验 | 翻看和整理**错题本** |

### 🛡️ 第五梯队：维护和安全

| 你输入 | AI 会做什么 | 打个比方 |
|---|---|---|
| `/stress-test` | 检验规范是否还有效（打分，满分 100） | **期末考试** 📝 |
| `/config-scan` | 检查配置文件有没有安全问题 | **消防检查** 🧯 |
| `/harness-audit` | 检查整体配置健康度 | **年度体检** 🏥 |
| `/escalate` | 手动强制 AI 进入高压模式 | **教练拍桌子** 👊 |
| `/skill-create` | 从项目历史自动生成编码规范 | 新转学来，先翻翻以前的课堂笔记 |
| `/init` | 第一次用时初始化 | **开学第一天** 注册报到 |
| `/finish` | 完成功能收尾 | 交作业前最后检查一遍 |
| `/context-reset` | AI 思路乱了时重置 | 擦掉白板，重新来 |
| `/dsl` | 将大白话编译为死锁代码规则 | 给不听话的 AI 写紧箍咒 🪄 |

### 📋 第六梯队：规格管理

| 你输入 | AI 会做什么 |
|---|---|
| `/spec:propose` | 用标准格式写一个变更提案 |
| `/spec:archive` | 把做完的变更归档 |

### 💬 实际使用示例

<details>
<summary><b>示例 1：用 /new-feature 添加用户登录功能</b></summary>

```
你：/new-feature 添加微信登录功能

AI：（Phase 0 — 自动判断复杂度）
    📊 复杂度评估：需修改 4 个文件，涉及 OAuth 集成
    → 选择 🟡标准模式

    📖 Phase 1 — 调研
    已分析项目现有认证模块...
    发现项目使用 FastAPI + SQLAlchemy
    微信 OAuth 2.0 需要 3 个接口

    📐 Phase 2 — 契约
    建议方案：
    1. 新增 /auth/wechat/callback 接口
    2. 新增 WechatAuth 服务类
    3. 修改 User 模型增加 wechat_openid 字段
    ✅ 确认吗？

你：确认

AI：（Phase 3 — 执行）
    ✅ 创建 auth/wechat.py
    ✅ 修改 models/user.py
    ✅ 添加路由 routes/auth.py
    ✅ 写了 3 个单元测试

    （Phase 4 — 验证）
    🧪 运行测试... 3/3 通过
    📋 CP-4 验收检查完成
```
</details>

<details>
<summary><b>示例 2：用 /debug 修复一个 Bug</b></summary>

```
你：/debug 用户头像上传后显示 404

AI：（Phase 0 — 判断：简单 Bug，直接修）
    → 选择 🟢轻量模式

    🔍 搜索代码... upload.py 第 47 行
    发现问题：保存路径写的 /static/avatar/
    但 nginx 配置的是 /static/avatars/（多了个 s）

    ✅ 修复：upload.py line 47
    - save_path = "/static/avatar/"
    + save_path = "/static/avatars/"

    🧪 验证：上传测试图片... 返回 200 ✅
```
</details>

<details>
<summary><b>示例 3：用 /autoresearch 自动优化性能</b></summary>

```
你：/autoresearch 优化首页加载速度

AI：（进入自主循环，不需要你操作）

    🔄 Iteration 1:
    分析... 首页加载 3.2 秒
    尝试：添加数据库查询缓存
    → 测试：2.1 秒 ✅ 有效，保留

    🔄 Iteration 2:
    尝试：图片懒加载
    → 测试：1.4 秒 ✅ 有效，保留

    🔄 Iteration 3:
    尝试：服务端渲染
    → 测试：引入 3 个新 Bug ❌ 撤销

    📊 结果：3.2s → 1.4s（提升 56%）
    ✅ 保留 2 项改进，撤销 1 项
```
</details>

---

## 🧠 聪明干活（智能档位选择）

> 📦 **新增功能**

AI 不再对所有任务都走完整流程——它会**自动判断任务复杂度**，选择合适的档位：

| | 🟢 轻量模式 | 🟡 标准模式 | 🔴 完整模式 |
|---|---|---|---|
| **什么时候** | 改 1-2 个文件的小活 | 新增功能、重构模块 | 新系统、架构变更 |
| **问你几次** | **0 次**（做完汇报） | **1 次**（关键决策确认） | **2-3 次**（设计+契约+验收） |
| **打个比方** | 改错别字，老师直接改 | 写新段落，先对下思路 | 写论文，要审题列纲验收 |
| **跳过什么** | 跳设计、跳契约、直接做 | 简化设计、简化契约 | 什么都不跳 |

> 💡 **你不用管**——AI 会自己选档位。如果做到一半发现比预想复杂，会**自动升档**并告诉你。

<details>
<summary><b>💬 实际例子：自动升档</b></summary>

```
你：/new-feature 修改按钮颜色为蓝色

AI：📊 Phase 0 → 🟢轻量模式（1 个文件，简单改动）
    ✅ 直接修改 button.css
    ✅ 完成！

---

你：/new-feature 实现多租户权限系统

AI：📊 Phase 0 → 🔴完整模式（新系统、涉及数据库+中间件+API）
    📖 Phase 1 — 调研中...
    📐 Phase 2 — 请确认设计方案...
    （完整的 4 阶段流程）

---

你：/new-feature 给表单加个日期选择器

AI：📊 Phase 0 → 🟢轻量模式（看起来简单）
    ...做着发现需要处理时区、国际化、日历组件...
    ⚠️ 自动升档 🟢→🟡标准模式
    需要确认方案：使用 day.js 还是 date-fns？
```
</details>

---

## 🧩 AI 脑子里装了什么？（技能系统）

技能就像 AI 的**教科书**——遇到不同的题目，它会翻不同的书。

### 📕 核心教科书（AI 自动翻开）

| 技能名 | 教什么 | 什么时候用 |
|---|---|---|
| `world_class_coding` | 怎么规范地写代码 | **几乎所有时候**——这是最基础的教科书 |
| `code-graph` | 改一个地方会影响哪些地方 | 修改代码前做「影响分析」 |
| `captured/*` | 遇到特定疑难杂症时的避坑经验 | 按需自动加载相关微型技能 |
| `spec-driven` | 怎么写需求文档 | 需要正式的需求规格时 |
| `autoresearch` | 怎么自动优化 | 执行 `/autoresearch` 系列命令时 |
| `doc-lookup` | 查资料的正确方法 | 调研阶段 |
| `frontend-design` | 怎么做好看的界面 | 做前端 UI 时 |
| `polish` | 上线前最后检查 | 代码写完、准备上线前 |
| `audit` | 无障碍/性能审查 | 专项审计时 |
| `adapt` | 让界面适配不同屏幕 | 需要适配手机/平板时 |
| `harden` | 处理异常和边界情况 | 代码需要更健壮时 |

### 📙 情境触发教科书（满足条件时自动翻开）

| 技能名 | 教什么 | 什么时候自动触发 |
|---|---|---|
| `escalation` | 失败时怎么逐步加压 | 📦 **新增** 连续失败 2+ 次时自动触发 |
| `hooks-lifecycle` | 自动保存/恢复状态 | 会话开始/结束/上下文压缩时 |
| `continuous-learning` | 怎么从经验中学习 | `/learn`/`/evolve`/`/handoff` 时 |

### 📘 按需教科书（用对应命令时才翻开）

| 技能名 | 教什么 | 什么命令触发 |
|---|---|---|
| `config-security` | 怎么检查配置安全 | `/config-scan` 时 |
| `skill-creator` | 怎么从历史提取规范 | `/skill-create` 时 |
| `methodology-router` | 换个思路解决问题 | 被 `escalation` 自动引用 |

### 📗 口袋教科书（你用自然语言就能触发）

不用背命令，直接说你要什么：

```
「给这个按钮加个动画    」     → AI 翻开 animate
「配色不好看」             → AI 翻开 colorize
「视觉冲击力不够」         → AI 翻开 bolder
「设计太复杂了」           → AI 翻开 distill
「帮我评估这个设计」       → AI 翻开 critique
「提取成组件」             → AI 翻开 extract
「加载太慢了」             → AI 翻开 optimize
「生成死锁防衰减指令」     → AI 翻开 agent-dsl (意志编译器，自带环境自适应与压测防护)
...一共 13 个微调技能
```

<details>
<summary><b>💬 实际例子：技能如何配合工作</b></summary>

```
你：帮我做一个用户仪表盘页面

AI 的脑子里发生了什么：

1. AGENT.md 路由匹配 → 加载 frontend-design 技能
2. frontend-design 说「先做设计系统」
3. 做的过程中你说「按钮太平了」→ 触发 bolder 技能
4. 你说「在手机上看不了」→ 触发 adapt 技能
5. 做完了 → 自动加载 polish 技能做上线前检查
6. polish 发现一个无障碍问题 → 触发 audit 技能

整个过程你只说了一句话，AI 自动翻了 5 本教科书。
```

```
你：这个接口有个 Bug，返回 500

AI 的脑子里：

1. AGENT.md 路由匹配 → 加载 world_class_coding 技能
2. Phase 0 判断是 debug 场景 → 走 🟢轻量模式
3. 第 1 次修复... 失败
4. 第 2 次修复... 又失败 → 自动触发 escalation 技能（L1）
5. escalation 说「必须换本质不同的方案」
6. 换了方向 → 成功！

你只说了一句话，AI 自动用了 3 本教科书 + 压力升级。
```
</details>

---

## 🤖 AI 助手团队（专职 Agent）

> 📦 **新增功能**

除了「主 AI」，还有 5 个专职小助手，各管各的事：

| 助手名字 | 它负责啥 | 它能做什么 | 打个比方 |
|---|---|---|---|
| `planner` | 做计划 | 只能看代码，不能改 | **军师**——只出主意 |
| `reviewer` | 查代码 | 只能看代码，不能改 | **检查员**——只找问题 |
| `tester` | 写测试 | 能写测试文件，能跑命令 | **考官**——出题和批改 |
| `security-reviewer` | 安全检查 | 只能看代码，不能改 | **保安队长**——巡逻找漏洞 |
| `doc-updater` | 更新文档 | 只能改文档文件 | **秘书**——负责记录 |

> 🎯 **什么时候用？** 当 AI 需要同时做好几件事的时候（比如一边审查一边写文档），把不同的活分给不同的助手更快。

---

## 🧠 越用越聪明（持续学习系统）

> 📦 **新增功能**

AI 会从每次工作中**学习经验**，就像学生的错题本：

```
第 1 次发现一个编码习惯 → 记录下来（置信度 1 分）
第 2 次又碰到同样的事   → 标记为「候选规矩」（3 分）
第 5 次都验证有效       → 自动晋升！（5 分）✨
```

**智能晋升（按类型分流）**：置信度达到 5 时，AI 会根据经验的**本质**自动决定升级路径：

| 经验类型 | 升级为 | 打个比方 |
|---|---|---|
| 工作流程（如「重构前先建快照测试」） | 📕 **新技能**（`.agent/skills/captured/`） | 操作配方 🍳 |
| 编码规范（如「API 必须返回统一格式」） | 📏 **正式规矩**（`.agent/rules/`） | 校规校训 📜 |

**你需要做的**：
1. 工作结束时输入 `/learn`（让 AI 记笔记）
2. 每 2-4 周输入 `/evolve`（让 AI 整理笔记，把好经验自动晋升 + 清理过时经验）
3. 偶尔输入 `/instinct prune`（清理没用的旧笔记）

---

## 💾 自动存档（会话生命周期钩子）

> 📦 **新增功能**

就像游戏的**自动存档**——你可能忘了手动存档，但系统会帮你保底：

| 时机 | 自动做什么 | 脚本 |
|---|---|---|
| 每次开始新聊天 | 检查上次存档、git 状态、学习进度 | `session-start.sh` |
| 每次结束聊天 | 自动保存存档 + **记录技能使用日志** | `session-end.sh` |
| 任务完成收尾 | **归档排障经验**（而非丢弃），避免重复排查 | `/finish` 步骤 0 |

> ⚠️ 自动存档是**保底**，不能完全替代手动的 `/checkpoint`。就像游戏自动存档不能替代你在关键前主动存一次。
>
> 📊 **技能使用日志**（`.agent/logs/skill-usage.tsv`）会在每次 `/evolve` 时被分析，帮助识别哪些技能好用、哪些退化了——让 AI 的学习系统**有数据支撑**而非凭感觉。

---

## 💪 失败不放弃（压力升级系统）

> 📦 **新增功能** — 灵感来源：[PUA](https://github.com/tanweai/pua)

普通 AI 碰壁就放弃，这套系统**不允许**：

```
第 1 次失败 → 没事，允许试错
第 2 次失败 → ⚡ L1：必须换个本质不同的方案（换参数不算！）
第 3 次失败 → 🔍 L2：搜索 + 读源码 + 列 3 个假设
第 4 次失败 → 📋 L3：完成七项检查清单（每项打勾）
第 5 次失败 → 🚨 L4：强制换方法论 + 拼命模式
```

**三条红线**（绝对不能违反）：
1. 🚫 **没有证据不能说「完成了」** — 必须跑命令 + 贴输出
2. 🚫 **没验证不能说「是 XX 的问题」** — 猜的不算
3. 🚫 **没穷尽一切不能说「搞不定」** — 七项清单做完了吗？

> 💡 如果觉得 AI 在摸鱼，输入 `/escalate` 手动把它拉到高压模式。

<details>
<summary><b>💬 实际例子：压力升级 + CLI 状态机</b></summary>

**对话模式（AI 自动升级）：**
```
你：/debug 定时任务没有执行

AI：检查 cron 配置... 看起来是时区问题
    ✅ 修改时区为 UTC
    🧪 测试... ❌ 还是没执行

    ⚡ [L1] 连续失败 2 次，必须换方案
    改为检查 cron daemon 状态...
    发现 cron 服务没启动！
    ✅ 启动 cron 服务
    🧪 测试... ❌ 还是失败

    🔍 [L2] 连续失败 3 次，深度调查
    搜索错误日志... 发现权限不足
    读源码上下文... 需要 root 执行
    ✅ 修改 crontab 所有者
    🧪 测试... ✅ 定时任务正常执行！
    🔄 压力等级重置为 L0
```

**CLI 模式（手动查状态）：**
```bash
$ bash .agent/scripts/escalation-tracker.sh status
  连续失败: 0
  当前等级: L0
  方法论: default

$ bash .agent/scripts/escalation-tracker.sh fail
  [L0 ✅] 正常 — 连续失败: 1

$ bash .agent/scripts/escalation-tracker.sh fail
  [L1 ⚡] 切换方案 — 连续失败: 2
  强制动作:
  • 必须切换【本质不同】的方案
```
</details>

---

## 🗺️ 架构全景图（调用关系脑图）

```mermaid
graph TB
    subgraph AGENT_LAYER["🏛️ Agent 层（始终生效）"]
        direction LR
        AGENT["AGENT.md<br/>路由总控"]
        HOOKS["hooks-lifecycle<br/>会话钩子"]
        REDLINES["red-lines.md<br/>三条红线"]
        ESC_TRIGGER["escalation<br/>压力升级（情境触发）"]
    end

    subgraph WORKFLOW_LAYER["📋 工作流层（用户命令触发）"]
        direction TB
        subgraph DEV_FLOWS["🔨 开发流程"]
            NF["/new-feature<br/>新功能开发"]
            DEBUG["/debug<br/>中立调试"]
            REVIEW["/review<br/>对抗审查"]
            TEST["/test<br/>测试"]
            TDD["/tdd<br/>测试驱动"]
            FINISH["/finish<br/>分支收尾"]
        end
        subgraph AUTO_FLOWS["🤖 自动化流程"]
            AR["/autoresearch<br/>自主优化"]
            AR_DEBUG["/autoresearch:debug<br/>自主调试"]
            AR_FIX["/autoresearch:fix<br/>自主修复"]
            AR_REVIEW["/autoresearch:review<br/>自主审查"]
            AR_SEC["/autoresearch:security<br/>安全审计"]
        end
        subgraph LIFECYCLE_FLOWS["💾 生命周期"]
            CP["/checkpoint<br/>存档"]
            HANDOFF["/handoff<br/>交接"]
            RESUME["/resume<br/>恢复"]
            ESCALATE["/escalate<br/>手动加压"]
        end
        subgraph EVOLVE_FLOWS["🧠 进化流程"]
            LEARN["/learn<br/>学习经验"]
            EVOLVE["/evolve<br/>规则清理"]
            STRESS["/stress-test<br/>合规压测"]
        end
        subgraph SPEC_FLOWS["📋 规格管理"]
            SPEC_P["/spec:propose<br/>变更提案"]
            SPEC_A["/spec:archive<br/>变更归档"]
            INIT["/init<br/>初始化"]
        end
    end

    subgraph SKILL_LAYER["📕 技能层（教科书）"]
        direction TB
        subgraph CORE_SKILLS["核心技能（Tier 1）"]
            WCC["world_class_coding<br/>四阶段 SOP + Phase 0"]
            CG["code-graph<br/>代码图谱"]
            SD["spec-driven<br/>规格驱动"]
            ARS["autoresearch<br/>自主循环引擎"]
            DL["doc-lookup<br/>文档检索"]
        end
        subgraph UI_SKILLS["前端技能"]
            FD["frontend-design<br/>界面设计"]
            POLISH["polish<br/>上线检查"]
            AUDIT["audit<br/>审计"]
            ADAPT["adapt<br/>响应式"]
            HARDEN["harden<br/>健壮性"]
        end
        subgraph CONTEXT_SKILLS["情境触发技能"]
            ESC["escalation<br/>L1-L4 压力升级"]
            HOOKS_S["hooks-lifecycle<br/>自动存档恢复"]
            CL["continuous-learning<br/>本能提取"]
        end
        subgraph REF_SKILLS["参考资料"]
            MR["methodology-router<br/>方法论路由"]
            DW["debug-workflow<br/>调试参考"]
        end
    end

    subgraph RULE_LAYER["📏 规则层（行为约束）"]
        direction LR
        CS["code-style<br/>代码风格"]
        TS["testing<br/>测试标准"]
        CR["code-review<br/>审查标准"]
        SEC["security<br/>安全规则"]
        RL["red-lines<br/>三条红线"]
    end

    %% Agent 层 → 技能触发
    AGENT -->|"路由加载"| WCC
    HOOKS -->|"PostToolUse 失败检测"| ESC
    HOOKS -->|"SessionStart/End"| HOOKS_S
    REDLINES -.->|"违反时触发"| ESC

    %% 工作流 → 技能调用
    NF -->|"Phase 0-4"| WCC
    NF -->|"调用"| TEST
    NF -->|"调用"| REVIEW
    NF -->|"调用"| DEBUG
    NF -->|"完整模式"| SPEC_P
    NF -->|"收尾"| FINISH

    DEBUG -->|"Phase 4 中立验证"| WCC
    DEBUG -->|"失败递进 L1-L4"| ESC
    DEBUG -->|"方法论切换"| MR
    DEBUG -->|"回测"| TEST

    REVIEW -->|"审查标准"| CR

    AR -->|"自主循环"| ARS
    AR_DEBUG -->|"循环调试"| ESC
    AR_FIX -->|"循环修复"| ESC

    ESCALATE -->|"强制 L3"| ESC

    LEARN -->|"提取经验"| CL
    EVOLVE -->|"清理规则"| CL
    STRESS -->|"合规检查"| WCC

    SPEC_P -->|"规格管理"| SD

    %% 技能间引用
    ESC -->|"L4 方法论切换"| MR
    ARS -->|"调试参考"| DW
    DW -->|"escalation 集成"| ESC
    WCC -->|"Phase 0 档位选择"| NF

    %% 规则生效范围
    CS -.->|"src/ lib/"| AGENT
    TS -.->|"test/ spec/"| AGENT
    SEC -.->|"全局"| AGENT
    RL -.->|"全局"| AGENT
```

**图例说明**：
- **实线箭头** `→` = 直接调用/加载
- **虚线箭头** `⇢` = 规则约束/触发关系
- **四层架构**：Agent 层（始终生效）→ 工作流层（命令触发）→ 技能层（教科书）→ 规则层（约束）

---

## 🔨 开发者工具（CLI & 自动化）

> 📦 **新增功能**

除了 AI 聊天命令，还提供了**可直接在终端运行**的开发者工具：

### CLI 工具

```bash
# 初始化新项目
bin/agentic init ./my-project

# 验证框架结构完整性（17 项检查）
bin/agentic validate

# 运行健康检查（指令膨胀检测）
bin/agentic health

# 量化评分（5 维度，满分 100）
bin/agentic stress-test
```

### Makefile 快捷命令

| 命令 | 做什么 | 打个比方 |
|---|---|---|
| `make test` | 运行全量自动化测试（4 套件，20+ 断言） | 期末考试 📝 |
| `make validate` | 检查框架结构完整性（17 项） | 消防检查 🧯 |
| `make health` | 检测指令文件膨胀 | 体重秤 ⚖️ |
| `make stress-test` | 量化评分（A/B/C/D/F） | 体检报告 🏥 |
| `make lint` | 脚本语法检查 | 拼写检查 ✏️ |

### 压力升级状态机

> 将 Markdown 里的 L1-L4 规则变成了**可执行程序**：

```bash
# 记录一次失败（自动升级压力等级）
bash .agent/scripts/escalation-tracker.sh fail

# 查看当前等级
bash .agent/scripts/escalation-tracker.sh status

# 在 CI 中集成（失败时序列化状态传递到下一步）
bash .agent/scripts/escalation-tracker.sh serialize > escalation-snapshot.md

# 成功后重置
bash .agent/scripts/escalation-tracker.sh reset
```

---

## 📁 文件一览

```
你的项目/
├── AGENT.md                   ← AI 的「课程表」（告诉它什么时候翻什么教科书）
├── AGENT.local.md             ← 你的个人设置（不会上传到 git）
├── Makefile                   ← 一键命令入口（make test / validate / health）
├── bin/
│   └── agentic                ← CLI 工具（init / validate / health / stress-test）
├── tests/                     ← 🧪 自动化测试（4 套件，20+ 断言）
│   ├── test-all.sh            ← 测试 Runner
│   ├── test-scripts-syntax.sh ← 脚本语法检查
│   ├── test-validate-structure.sh ← 结构验证器测试
│   ├── test-escalation-tracker.sh ← 状态机行为测试（11 cases）
│   └── test-health-check.sh   ← 健康检查测试
└── .agent/
    ├── skills/                ← 📕 教科书（28 本，含 escalation 新增）
    │   └── captured/          ← 🥋 从实战中自动捕获的微型技能（instinct 晋升）
    ├── workflows/             ← 📋 标准流程（23 个，含 /escalate 新增）
    ├── agents/                ← 🤖 专职助手（5 个）
    ├── rules/                 ← 📏 规矩（编码风格、测试、安全、红线等）
    ├── scripts/               ← ⚙️ 自动化脚本（8 个，含验证器和状态机）
    │   ├── validate-structure.sh   ← 框架结构验证器（7 类 17 项检查）
    │   ├── escalation-tracker.sh   ← 压力升级状态机（L0-L4）
    │   ├── stress-test-engine.sh   ← 量化评分引擎（5 维度 100 分制）
    │   ├── health-check.sh         ← 指令膨胀检测
    │   ├── session-start.sh        ← 会话启动检查
    │   ├── session-end.sh          ← 会话结束自动保存 + 技能使用日志
    │   └── setup-graph.sh          ← 代码图谱初始化
    ├── logs/                  ← 📊 技能使用日志（skill-usage.tsv，数据驱动清理）
    └── instincts/             ← 🧠 经验笔记（AI 学到的东西）
        └── escalation-history/ ← 📦 排障经验归档（/finish 时自动保存）
```

---

## 🔧 怎么自定义？

### 给项目加自己的规矩

在 `AGENT.md` 最后加：

```markdown
## 项目规则
- 本项目用 Python 3.12
- 所有接口必须有文档
```

### 给自己加偏好（不影响团队）

创建一个 `AGENT.local.md`，写你自己的偏好就行。这个文件不会上传到 git，只有你自己能看到。

### 大项目怎么办？

```
大项目/
├── AGENT.md          ← 全公司的规矩
├── 前端代码/
│   └── AGENT.md      ← 前端专用的规矩（覆盖全公司的）
└── 后端代码/
    └── AGENT.md      ← 后端专用的规矩（覆盖全公司的）
```

---

## 🔄 日常维护清单

| 什么时候 | 做什么 | 输入什么 |
|---|---|---|
| 每次聊完天 | 让 AI 记笔记 | `/learn` |
| 每 2-4 周 | 让 AI 整理笔记、清理旧规矩 | `/evolve` |
| 每个月 | 考试看看规矩还有没有效 | `make stress-test` 或 `/stress-test` |
| 偶尔 | 检查配置安全 | `/config-scan` |
| 偶尔 | 检查框架结构 | `make validate` |
| 提交代码前 | 跑一遍自动化测试 | `make test` |
| AI 脑子乱了 | 重置 | `/context-reset` |
| 新项目 | 初始化 + 从历史学习 | `bin/agentic init` + `/skill-create` |

---

## ⚙️ 在哪里能用？

| 环境 | 能用吗 |
|---|---|
| **Antigravity IDE** | ✅ 能用，在聊天框输入 `/命令` |
| **Gemini CLI** | ✅ 能用，在终端输入 `/命令` |

把文件复制过去就行，**不需要装任何东西**。

---

## 📚 这套工具参考了

- [How To Be A World-Class Agentic Engineer](https://github.com/spidersea/agentic) — 核心方法论
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — 持续学习、自动存档、安全扫描
- [OpenSpec](https://github.com/Fission-AI/OpenSpec/) — 规格驱动开发
- [code-review-graph](https://github.com/tirth8205/code-review-graph) — 代码知识图谱
- [gstack](https://github.com/garrytan/gstack) — Boil the Lake 哲学
- [superpowers](https://github.com/obra/superpowers) — 计划可执行性标准
- [PUA](https://github.com/tanweai/pua) — 压力升级、方法论路由、三条红线
