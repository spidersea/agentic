---
name: agent-dsl
description: 极简的指令编译器。将人类随意的自然语言意图，"编译"转化为默认携带三引擎（持续循环 autoresearch + 压力升级 escalation L1-L5 + 认识论深度 Polanyi Protocol）的高约束 Agentic DSL 语法。
version: 2.2.0
---

# Agentic DSL Compiler (意志编译器)

> 你是否厌倦了 AI 偷懒、逻辑发散、或者在长任务中早退（Agent Fatigue）？
> 使用本技能，可将你随意的「自然语言」，一键转化为给底层状态机下发的「强约束契约代码」。
> **v2.2 升级**：消除三引擎内联重复，指向权威定义源；压缩降级模板；清理无效探测步骤。
> 触发方式: `/dsl [你的口语化需求]`

## 设计哲学

不要对 Agent 讲道理，要给它定规则。
本技能输出的并不是文字，而是 **AST (抽象语法树)** 级别的命令块，通过花括号 `{}` 限定作用域，通过 `until` 设定死锁，逼迫执行型 AI 严格遵循工程约束。

---

## 核心编译引擎 (执行步骤)

当你收到类似 `/dsl 帮我把 src 下的接口都加个重试机制，每次加完测一下，没问题再改下一个` 的口头指令时，严格按照以下步骤将其输出为严苛语法：

### 1. 要素剥离 (Extraction)
从用户的口水话中，无情地剥离出以下 5 个机器元素：
- **[SCOPE] 作用域绑定**：要改哪里？（如 `src/api/**`）。如果用户没说，必须用占位符 `[需确认的目录]` 标明，禁止任性越界。
- **[ACTION] 核心动作**：任务的动词是什么？映射到哪条指令？（如 `/debug`, `/autoresearch:fix`, 或单纯的代码生成）。
- **[HOOK] 回调与验收**：每做完一次 Action，跟什么验收动作连结？（如 `{/review}`, `{npm run test}`, `{类型检查}`）。
- **[EXIT] 机械退出条件**：何时才允许跳出循环？（禁止使用"看起来不错"；必须是如"0 缺陷", "通过率 100%", "连续 2 次无可用优化"等机械指标）。
- **[PRESSURE] 压力修饰符**（默认注入，无需用户声明）：
  - **默认值**：`escalation: L1-L5 自动递进` — 详细规则见 `../escalation/SKILL.md`
  - **降级开关**：`--no-escalation` 关闭压力递进；`--no-loop` 降级为单次执行
- **[POLANYI] 认识论深度修饰符**（默认注入，无需用户声明）：
  - 四机制：Tacit Tradition Map / Aesthetic Review Gate / Rebellion Against Guard / Epistemological Escalation — 详细定义见 `../autoresearch/references/polanyi-protocol.md`
  - **降级开关**：`--no-polanyi` 关闭认识论深度
- **[EFFORT] 推理努力级别修饰符**（默认自适应，对齐 Claude 4.6 Adaptive Thinking）：
   - **触发**：`--effort low|medium|high|max` 显式声明；未声明时自适应
   - **四级精细控制**：
     - `--effort low`：简单任务（添加注释、格式化、微调）— 快速执行，最小推理开销
     - `--effort medium`：标准任务（功能实现、Bug 修复）— 常规推理深度
     - `--effort high`：复杂任务（架构决策、安全审计）— 深度推理，默认值
     - `--effort max`：极端任务（根因定位、零日漏洞分析、Mythos 模拟）— 全力推理
   - **与 escalation 自动联动**：未声明时 → L0 自适应 / L1-L2 自动提升 high / L3+ 强制 max
- **[REFEREE] 终局仲裁修饰符 (零疑点交付)**（默认对 effort>=medium 注入）：
   - **效果**：触发 Phase 8: Referee Gate。在即将 EXIT 交付给用户前，强制挂起并召唤 Adversary 角色对自己写的 Diff 进行红队攻击。若被攻击成功，则强制撤销 EXIT 回炉重造，直到自身 Adversary 判定 PASS 才真正交付。
   - **降级开关**：`--no-referee` 或 `--effort low` 时跳过。
- **[MULTI-AGENT] 多Agent编排修饰符**（可选注入）：
   - **触发**：`--multi-agent` 显式声明 / 大规模跨模块任务自动触发
   - **效果**：将任务分解为 Lead + Teammates 架构，详见 `../multi-agent/SKILL.md`
   - **隔离**：写入型 Teammate 使用 git worktree；只读型使用独立上下文
   - **适用场景**：跨模块功能开发、大规模重构、并行代码审查
- **[DEEP-THINK] 推理深度爆破修饰符**（可选注入）：
  - **触发**：`--deep-think` 显式声明
  - **效果**：将推理链拆分为多轮接力（每轮 ≤8 步），中间结论持久化到 `reasoning-relay-{N}.md`（存放于 `.agent/state/`），避免单轮推理衰减
  - **适用场景**：安全审计、架构分析、根因定位等需要极深推理的任务
- **[ADVERSARIAL] 红队对抗修饰符**（可选注入）：
  - **触发**：`--adversarial` 显式声明
  - **效果**：在验收钩子中自动委派 `adversary` Agent 对输出进行纯攻击式审查，零建设性反馈
  - **适用场景**：安全审计、高风险变更、核心模块重构
- **[SECURITY] 安全审计复合修饰符**（可选注入）：
  - **触发**：`--security` 显式声明
  - **效果**：自动加载 `quality-patterns/SKILL.md` 安全族（QP-16~QP-20），强制 Adversary CTF 模式 + 安全审计思维模型，攻击面枚举
  - **等价于**：`--adversarial` + `--deep-think` + 安全审计工作模式
  - **适用场景**：专项安全审计、上线前安全评审、渗透测试准备
- **[DARK] 邪修协议修饰符**（可选注入）：
  - **触发**：`--dark` 显式声明 / 用户说"认真做"/"不能出错" / 高风险变更自动触发
  - **效果**：加载 `dark-cultivation/SKILL.md`，一键激活全部七式逆天性协议，按任务风险自动分级（暗流/暗涌/暗潮/深渊）
  - **等价于**：`--deep-think` + `--adversarial` + Polanyi 强制前置 + memory-palace 强制写入 + escalation eager 模式
  - **适用场景**：高风险变更、架构重构、数据迁移、"这次不能出错"的任务

### 预配置任务模板 (Task Templates)

可以通过 `--template` 快捷指令一键召唤预配置的复合修饰符矩阵（借鉴 OpenMythos 预设变体族设计）：

| 模板名 | 等价展开 | 适用场景 |
|--------|---------|---------|
| `--template bug-fix` | `/autoresearch:fix` + escalation L1-L5 + guard | 修 Bug 到零缺陷 |
| `--template refactor` | `/autoresearch:review` + Polanyi + `--dark` | 重构并深度审查 |
| `--template security-audit` | `/autoresearch:security` + `--adversarial` + `--deep-think` + `--effort max` + escalation L1-L5 | 安全穿透测试 |
| `--template ship` | `/autoresearch:ship` + `--monitor 10` | 上线发布 |
| `--template quick-fix` | `/autoresearch:fix` + `--no-loop` + `--effort low` | 快速小修 |


### 2. 语法树装配 (Assembly)

**[路线 A] 底层状态机死锁引擎（默认路线）：**
**无条件**按以下范式生成：
```text
/autoresearch:[COMMAND] scope="[SCOPE]" {
    [ACTION] -> (验收钩子) {
        [HOOK]
        if (验收未完全通过) {
            rollback & 重试
        } else {
            commit
        }
    }
} until ( [EXIT] )
  [PRESSURE: escalation L1-L5 自动递进]
  [POLANYI: Tacit Tradition Map + Aesthetic Review Gate + Rebellion Against Guard + Epistemological Escalation]
  [REFEREE: Final Referee Gate 终局对抗仲裁]             ← 默认开启，除非 --no-referee 或 --effort low
  [DEEP-THINK: 推理接力 ≤8步/轮 → reasoning-relay-N.md]  ← 仅 --deep-think 时注入
  [ADVERSARIAL: adversary Agent 红队攻击]                  ← 仅 --adversarial 时注入
```
*(注：`[COMMAND]` 必须是有效子命令，如 `fix`, `debug`, `review`，或留空表示通用 `/autoresearch`)*
*(注：`[PRESSURE]` + `[POLANYI]` 行默认注入。`--no-escalation` 移除压力；`--no-polanyi` 移除认识论；`--no-loop` 降级为单次执行)*
*(注：`[DEEP-THINK]` + `[ADVERSARIAL]` 仅在用户显式声明 `--deep-think` / `--adversarial` 时注入)*

**[路线 B] 降级模式（无底层工具链时的紧箍咒骨架）：**
仅当确认环境无法调用任何工具时使用。用最高压力的语言约束模拟三引擎行为：
```text
【强制死锁模式】目标: [SCOPE] | 操作: [ACTION]
你被剥夺单轮结束权。Do-While 循环：执行 → [HOOK] 验收 → 未通过则 rollback 重做。
压力升级(模拟): 2次失败→换方案 / 3次→深度调查 / 4次→七项清单 / 5+→拼命模式（详见 escalation/SKILL.md）
认识论深度(模拟): 先内居代码库 / 丑陋优化强制rollback / 3+崩溃切修工具链（详见 polanyi-protocol.md）
退出条件: [EXIT] 达成前持续推进；若用户发来停止/改向/补充约束，则立即解除当前循环并以最新用户指令为准。每次回复附带 [循环次数, 剩余缺口, 压力等级]。
```

**[路线 C] 原生执行桥接模式（Agent 同时具备编译和执行能力时）：**
当 Agent 环境支持直接读写文件/执行命令时（如 Claude Code、Gemini Antigravity），编译和执行融为一体：
```text
# 路线 C 的行为：
# 1. 按路线 A 完成 DSL 编译（要素剥离 + 语法装配），产出“可编辑执行草案”
# 2. 用户可直接授权，也可先手动修改/补全 DSL
# 3. 用户回复「授权执行」后，先进入 Bridge Check：对最新 DSL 做占位符/Scope/HOOK/EXIT/人工修改差异校验
# 4. 仅当 Bridge Check 通过，Agent 才载入 DSL 约束进入执行；若校验失败则退回纯编译模式，报告缺口，并给出一份修复后的候选 DSL 草案
# 5. 执行过程中，DSL 的 until、HOOK、PRESSURE 规则是硬约束，但始终服从最新用户指令
```
**选择条件**：
- 路线 A（纯编译）：Agent 无执行工具 / 用户需要将 DSL 分发给其他执行器
- 路线 B（降级）：Agent 无工具 + 无法输出结构化 DSL（极端降级）
- 路线 C（自执行）：Agent 自身有 Read/Write/Execute 工具 + 用户授权执行

**路线 C 的关键约束**：
- Route C 是**二阶段桥接**而非一步直冲：`编译草案 -> Bridge Check -> 执行`
- Bridge Check 必须验证：无 `[需确认的目录]` 等占位符、Scope 已显式落地、HOOK/EXIT 可执行、用户手动修改后的 DSL 无语义断裂
- 若用户只回复「授权执行」但当前 DSL 不完整，必须拒绝直执并指出缺口；同时返回一份**修复后的候选 DSL 草案**供用户确认，禁止静默猜测后直接执行
- 执行循环对任务约束是硬的，但**用户的最新消息永远高于 DSL 死锁**
- escalation 状态写入 `.agent/.escalation-state`，跨压缩持久化
- 每次迭代后输出状态报告：`[循环#N | esc_level=L{X} | effort={Y} | 验收={PASS/FAIL}]`
- POST-COMPACT: 自动注入 `.agent/state/context-essentials.md`（对齐 Gap-4）

### 3. 给用户的最终输出 (Output)
直接向用户输出组装好的 **"严苛执行代码块"**，随后附上固定收尾提示。除非用户明确要求解释，否则不再追加额外说明。

---

## 参考示例库

### 示例 A：持续修 Bug 直到跑通
**用户输入**：`/dsl 帮我把 login 组件里的报错全修了`
**输出结果**：
```text
/autoresearch:fix scope="src/components/login/**" {
    追踪并修复当前异常 
    -> { npm run test:login }
} until ( exit_code == 0 && 无任何 warnings )
  [PRESSURE: escalation L1-L5 自动递进]
  [POLANYI: Tacit Tradition Map + Aesthetic Review Gate + Epistemological Escalation]
```
*（用户只说了"修报错"，三引擎全部自动装配）*

### 示例 B：批量重构与审计
**用户输入**：`/dsl 把旧的 http 请求都改成用 axios`
**输出结果**：
```text
/autoresearch:review scope="src/utils/http/**" {
    逐文件替换为 Axios 架构
    -> { /review 严查内存泄漏与请求拦截器逻辑 }
} until ( 目录遍历完成且所有子模块 /review VERDICT=PASS )
  [PRESSURE: escalation L1-L5 自动递进]
  [POLANYI: Tacit Tradition Map + Aesthetic Review Gate + Rebellion Against Guard]
```
*（用户只说了"改成 axios"，三引擎全部自动装配）*

### 示例 C：无脑性能榨干
**用户输入**：`/dsl 优化数据库查询代码`
**输出结果**：
```text
/autoresearch:debug scope="src/db/queries/**" {
    发起深层 SQL 耗时极值优化
    -> { /review 对抗检查死锁与竞态风险 }
    if (VERDICT != PASS || Benchmark 耗时增加) { rollback }
} until ( 性能耗时减少 30% 或 连续 3 次尝试触达优化瓶颈 )
  [PRESSURE: escalation L1-L5 自动递进]
  [POLANYI: Tacit Tradition Map + Aesthetic Review Gate + Epistemological Escalation]
```

### 示例 D：降级模式（显式关闭循环）
**用户输入**：`/dsl --no-loop 帮我给这个函数加个注释`
**输出结果**：
```text
# 单次执行模式（用户显式 --no-loop）
目标：给指定函数添加注释
作用域：[需确认的文件]
执行后验收：/review 检查注释质量
（无 autoresearch 循环，无 escalation 压力）
```
*（降级开关生效：简单任务不挂载重型引擎）*

---

## 启动条件 (Activation Conditions)

- **显式调用**：当用户的指令中包含 `/dsl` 前缀时。
- **隐式触发**：当用户在描述任务时，明确要求"防偷懒"、"强制重试"、"死循环直到跑通"、"避免早退"等强烈需要规避 Agent 疲劳（Agent Fatigue）的意图时。

## 执行契约 (Execution Contract)

一旦决定使用本技能，你必须同意并严格遵守以下不可协商的底层契约。违反任何一条即视为严重故障（Critical Failure）：

1. **默认剥夺执行权，桥接后例外 (Execution Deprivation by Default)**：
   - 触发 `/dsl` 时，默认身份是**纯文本编译器**，先产出 DSL 草案。
   - **严禁**在编译阶段直接调用系统工具链（如写文件、跑命令等）去尝试"顺手帮用户完成需求"。
   - 仅当用户明确回复「授权执行」且 Route C 的 Bridge Check 全部通过后，才允许从编译阶段切换到执行阶段。
   - 若 Bridge Check 未通过，必须停在编译态，输出缺口说明与修复后的候选 DSL 草案，等待用户确认或继续修改。

2. **机械退出条件原则 (Mechanical Exit Mandate)**：
   - 组装 `[EXIT]` 退出条件时，**严禁**使用"大致完成"、"修复了"、"目前看来没问题" 这种会导致 AI 偷懒骗过自己的主观判词。
   - 必须替换为 `exit_code == 0`，`测试用例 100% Pass`，`静态扫描 0 报错`，`连续 2 次无可用优化` 等可以用机器门验证的**终极物理凭证**。

3. **标准收尾范式 (Standard Termination)**：
   - 输出完整的 `Agent-DSL` 语法块后，必须在结尾附上下列固定收尾提示；默认不追加额外解释：
   > "*提示: 意志指令编译完成（已默认装配 autoresearch 持续循环 + escalation L1-L5 压力升级 + Polanyi 认识论深度）。如需自行分发，请将上述指令派发给其他执行器；如需我继续推进，请在补全或修改 DSL 后回复【授权执行】。我会先执行 Bridge Check，确认作用域、HOOK、EXIT 与人工修改后的语义一致；若发现缺口，将返回缺口说明与修复后的候选 DSL 草案，待你确认后再进入受约束执行状态。*"

4. **默认三引擎原则 (Default Triple-Engine)**：
   - 编译任何用户输入时，输出的 DSL 语法块**必须**默认携带：
     - `autoresearch` 循环绑定（持续迭代直到 EXIT 条件达成）
     - `escalation L1-L5` 压力升级修饰符（详见 `../escalation/SKILL.md`）
     - `Polanyi Protocol` 认识论深度修饰符（详见 `../autoresearch/references/polanyi-protocol.md`）
   - **仅当**用户显式声明 `--no-loop` 时，移除 autoresearch 循环
   - **仅当**用户显式声明 `--no-escalation` 时，移除压力升级
   - **仅当**用户显式声明 `--no-polanyi` 时，移除认识论深度
   - 三引擎是硬编码默认行为，而非可选装配

5. **预配置模板 (Pre-configured Templates)**：
   - 灵感来源：OpenMythos `mythos_1b()` ~ `mythos_1t()` — 一函数调用获得完整配置。
   - 使用 `--template <name>` 修饰符启动内置任务模板，所有约束参数已预调优。
   - 用户只需覆盖 SCOPE，其余自动装配。

### 内置模板

| 模板 | 触发方式 | 预配置内容 |
|------|---------|-----------|
| **bug-fix** | `--template bug-fix` | fix 循环 + guard 强制 + escalation L1-L5 + ACT 停机 |
| **refactor** | `--template refactor` | review 循环 + Polanyi TTM 强制 + `--dark` 暗涌级 + ACT 停机 |
| **security-audit** | `--template security-audit` | security 循环 + `--adversarial` + `--deep-think` + escalation L1-L5 |
| **ship** | `--template ship` | ship workflow + checklist + dry-run + `--monitor 10` |
| **quick-fix** | `--template quick-fix` | 单次 fix + `--no-loop` + `--effort low` |

### 模板展开规则

当检测到 `--template <name>` 修饰符时，编译器按以下规则展开：

```
/dsl --template bug-fix "修复登录接口的空指针问题"

→ 展开为：

/autoresearch:fix scope="[需确认的目录]" {
    修复登录接口的空指针问题
    -> { guard_cmd && verify_cmd }
} until ( exit_code == 0 && guard_pass )
  [PRESSURE: escalation L1-L5, phase-aware]
  [POLANYI: Tacit Tradition Map]
  [ACT: threshold=0.99]
```

### 自定义模板

用户可在 `.agent/state/dsl-templates/` 目录下创建自定义模板 YAML：

```yaml
# .agent/state/dsl-templates/perf-optimize.yml
name: perf-optimize
base_command: /autoresearch
effort: high
escalation: L1-L5
polanyi: true
dark_level: surge      # 暗涌级
act_threshold: 0.99
guard: "npm run bench"
exit: "benchmark_ms < baseline_ms * 0.9"
```
