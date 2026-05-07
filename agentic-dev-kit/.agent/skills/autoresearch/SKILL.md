---
name: autoresearch
description: Autonomous Goal-directed Iteration. Apply Karpathy's autoresearch principles to ANY task. Loops autonomously — modify, verify, keep/discard, repeat. Supports bounded iteration via Iterations: N inline config.
version: 1.4.0
---

# Claude Autoresearch — Autonomous Goal-directed Iteration

Inspired by [Karpathy's autoresearch](https://github.com/karpathy/autoresearch). Applies constraint-driven autonomous iteration to ANY work — not just ML research.

**Core idea:** You are an autonomous agent. Modify → Verify → Keep/Discard → Repeat.

## Subcommands

| Subcommand | Purpose |
|------------|---------|
| `/autoresearch` | Run the autonomous loop (default) |
| `/autoresearch:plan` | Interactive wizard to build Scope, Metric, Direction & Verify from a Goal |
| `/autoresearch:security` | Autonomous security audit: STRIDE threat model + OWASP Top 10 + red-team (4 adversarial personas) |
| `/autoresearch:ship` | Universal shipping workflow: ship code, content, marketing, sales, research, or anything |
| `/autoresearch:debug` | Autonomous bug-hunting loop: scientific method + iterative investigation until codebase is clean |
| `/autoresearch:fix` | Autonomous fix loop: iteratively repair errors (tests, types, lint, build) until zero remain |
| `/autoresearch:review` | Autonomous continuous code review loop: adversarial finding + automatic fix until convergence |

## Reference Map

| Area | Source of Truth |
|------|-----------------|
| Main loop protocol | `.agent/skills/autoresearch/references/autonomous-loop-protocol.md` |
| General principles | `.agent/skills/autoresearch/references/core-principles.md` |
| Planning wizard | `.agent/skills/autoresearch/references/plan-workflow.md` |
| Debug loop | `.agent/skills/autoresearch/references/debug-workflow.md` |
| Fix loop | `.agent/skills/autoresearch/references/fix-workflow.md` |
| Review loop | `.agent/skills/autoresearch/references/review-workflow.md` |
| Security loop | `.agent/skills/autoresearch/references/security-workflow.md` |
| Shipping loop | `.agent/skills/autoresearch/references/ship-workflow.md` |
| Results logging | `.agent/skills/autoresearch/references/results-logging.md` |
| Methodology switching | `.agent/skills/autoresearch/references/methodology-router.md` |
| Polanyi epistemology | `.agent/skills/autoresearch/references/polanyi-protocol.md` + `.agent/skills/polanyi/SKILL.md` |


### /autoresearch:review — Autonomous Code Review Loop (v1.0.0)

Adversarial review-fix loop. It scopes target files, scans against `.agent/rules/code-review.md`, logs confirmed issues, auto-fixes, then re-reviews until two consecutive PASS verdicts or bounded limits.

Load: [`references/review-workflow.md`](./references/review-workflow.md) for full protocol.

Usage: `/autoresearch:review`, `--report-only`, `--from-fix`

### /autoresearch:security — Autonomous Security Audit (v1.0.3)

STRIDE threat model + OWASP Top 10 + red-team (4 adversarial personas). Load: [`references/security-workflow.md`](./references/security-workflow.md).

Flow: Reconnaissance → Asset ID → Trust Boundaries → STRIDE → Attack Surface → Autonomous Loop → Final Report.
Key rule: every finding needs code evidence (`file:line` + attack scenario). Composite metric: `(owasp/10)*50 + (stride/6)*30 + min(findings,20)`.

| Flag | Purpose |
|------|---------|
| `--diff` | Delta mode — only changed files |
| `--fix` | Auto-fix Critical/High after audit |
| `--fail-on {sev}` | CI/CD gate (exit non-zero) |

Usage: `/autoresearch:security`, `--diff --fix --fail-on critical`, `Scope: src/api/**`

### /autoresearch:ship — Universal Shipping Workflow (v1.1.0)

Ship anything through a structured 8-phase workflow. Load: [`references/ship-workflow.md`](./references/ship-workflow.md).

**Flow:** Identify → Inventory → Checklist → Prepare (loop) → Dry-run → Ship → Verify → Log

Supported types: `code-pr`, `code-release`, `deployment`, `content`, `marketing-email`, `marketing-campaign`, `sales`, `research`, `design`.

| Flag | Purpose |
|------|---------|
| `--dry-run` | Stop at Phase 5 |
| `--auto` | Auto-approve dry-run gate |
| `--force` | Skip non-critical items |
| `--rollback` | Undo last ship |
| `--monitor N` | Post-ship monitoring N mins |
| `--checklist-only` | Stop at Phase 3 |

Metric: `ship_score = (passing/total)*80 + (dry_run?15:0) + (no_blockers?5:0)`. Score `>=80` = shippable.

Usage: `/autoresearch:ship`, `--auto`, `--type deployment --dry-run`, `--monitor 10`

### /autoresearch:plan — Goal → Configuration Wizard

Converts a plain-language goal into a validated, ready-to-execute autoresearch configuration.

Load: [`references/plan-workflow.md`](./references/plan-workflow.md) for full protocol.

Quick summary:
1. Capture goal
2. Analyze local tooling and scripts
3. Define real scope globs
4. Define a mechanical metric
5. Define direction and verify command
6. Safety-scan and dry-run verify
7. Confirm and optionally launch

Critical gates:
- Metric must output a parseable number
- Verify command must pass a dry run
- Scope must resolve to at least one file

Usage: `/autoresearch:plan`, `/autoresearch:plan Increase test coverage to 95%`

After the wizard completes, the user gets a ready-to-paste `/autoresearch` invocation — or can launch it directly.

## When to Activate
- `/autoresearch` or "work autonomously" → main loop
- `/autoresearch:plan` or "plan an autoresearch run" → planning wizard
- `/autoresearch:security` or "security audit"/"STRIDE"/"OWASP" → security audit
- `/autoresearch:ship` or "ship it"/"deploy this" → ship workflow
- `/autoresearch:debug` or "find all bugs"/"debug this" → debug loop
- `/autoresearch:fix` or "fix all errors"/"make tests pass" → fix loop
- `/autoresearch:review` or "review and fix all issues" → review loop

## Bounded Iterations

Default: loop **forever**. Add `Iterations: N` for bounded runs. After N iterations, print summary (baseline → best). Early exit if goal achieved.

Typical guidance: overnight runs can stay unbounded; targeted fixes usually use `Iterations: 5`; short sessions often use `Iterations: 10`; CI/CD should stay bounded.

## Setup Phase

**If Goal/Scope/Metric/Verify inline** → extract and proceed to step 5.

**If missing** → batch 2 rounds of `AskUserQuestion`: Batch 1 (Goal/Scope/Metric/Direction) + Batch 2 (Verify/Guard/Launch). Always batch — never ask one at a time. Dry-run verify command before accepting.

### Setup Steps (after config is complete)

> ⛔ **防衰减迭代记录 (Loop Contract)**
> 决定开启 Autoresearch 循环后，必须在第一秒钟于磁盘创建 `autoresearch-tracker.md` 追踪器文件（或整合入 `task.md`）。
> 无论执行了多少次 Modify-Verify，每次决定退出循环前，必须扫描该文件确认“所有前置验证任务”是否打满 `[x]`，强行唤醒你的循环终点意识。

1. **Read all in-scope files** for full context before any modification
2. **⚡ Polanyi Excavation (强制前置步骤，非可选修饰符)** — 在任何修改前必须完成：
   - 构建/更新 Tacit Tradition Map：识别命名约定、隐式依赖、历史决策痕迹
   - 做意图-实现 Gap 分析，识别设计目标与当前实现的裂缝
   - 持久化到 `.agent/state/tacit-tradition-map.md`；至少沉淀 3 条隐性规则后再继续
   - 详见 [`references/polanyi-protocol.md`](./references/polanyi-protocol.md) + [`../polanyi/SKILL.md`](../polanyi/SKILL.md)
3. **Define the goal** — extracted from user input or inline config
4. **Define scope constraints** — validated file globs
5. **Define guard (optional)** — regression prevention command
6. **Create a results log** — Track every iteration (see `.agent/skills/autoresearch/references/results-logging.md`)
7. **Establish baseline** — Run verification on current state AND guard (if set). Record as iteration #0
8. **Confirm and go** — Show user the setup, get confirmation, then BEGIN THE LOOP

## The Loop

Read [`references/autonomous-loop-protocol.md`](./references/autonomous-loop-protocol.md) for full protocol details.

1. **Review** — Re-read frozen Goal/Scope/Metric/Exit, current state, history, and logs; if drift is obvious, roll back to the last keep point and realign.
2. **Ideate** — Pick the next change from prior results and remaining hypotheses.
3. **Modify** — Make one focused in-scope change.
4. **Commit** — Commit before verification.
5. **Verify** — Run the metric with a timeout wrapper such as `timeout 120 <cmd>`.
6. **Guard** — Run guard if configured.
7. **Decide** — Keep only if improved and guard passes; otherwise revert. Guard-fail rework is capped at 2 attempts; crash recovery is capped at 3.
8. **Log** — Write the iteration result.
9. **Repeat** — Unbounded mode never pauses for user confirmation; bounded mode stops at N and summarizes. Every 10 iterations or under high context pressure, persist tracker, compact, restore, and continue.
10. **Post-loop learning** — Extract useful patterns and anti-patterns from the results log, route high-value lessons into `/learn`, and output summary + next-start suggestions.

## ACT 自适应停机 (Adaptive Computation Time)

> 灵感来源：OpenMythos 的 ACT halting。简单子任务早停，复杂子任务深挖，目标是减少无效迭代。

Decide 阶段同步维护子任务级收敛置信度：
- `PASS (keep)` → `confidence += 0.4`
- `PASS_WITH_WARNINGS` → `confidence += 0.2`
- `FAIL` / `CRASH` → `confidence = 0.0`
- `confidence >= 0.99` 时标记 `CONVERGED`，并在 results TSV 记录 `status="converged"` 与 `convergence_iter=N`

### 效果

| 子任务复杂度 | 典型收敛轮次 | 说明 |
|------------|------------|------|
| 简单 (添加注释、格式化) | 2-3 轮 | 连续 3 次 PASS → confidence=1.2 ≥ 0.99 |
| 中等 (Bug 修复、小重构) | 4-6 轮 | 偶尔 FAIL 重置，需多次 PASS 累积 |
| 复杂 (架构变更、安全修复) | 8+ 轮 | 频繁 FAIL，需深度迭代 |

### 约束

1. ACT 仅适用于子任务级别；全局退出条件不变
2. 可通过 `Convergence: 0.8` 降低阈值
3. `--effort max` 时自动禁用 ACT

## Critical Rules

1. **Loop until done** — Unbounded: loop until interrupted. Bounded: loop N times then summarize.
2. **Read before write** — Always understand full context before modifying
3. **One change per iteration** — Atomic changes. If it breaks, you know exactly why
4. **Mechanical verification only** — No subjective "looks good". Use metrics
5. **Automatic rollback** — Failed changes revert instantly. No debates
6. **Simplicity wins** — Equal results + less code = KEEP. Tiny improvement + ugly complexity = DISCARD
7. **Git is memory** — Every kept change committed. Agent reads history to learn patterns
8. **When stuck, think harder** — Re-read files, re-read goal, combine near-misses, try radical changes. Don't ask for help unless truly blocked by missing access/permissions

## Principles Reference

See [`references/core-principles.md`](./references/core-principles.md) for the 7 generalizable principles from autoresearch.

## Adapting to Different Domains

| Domain | Metric | Verify | Guard |
|--------|--------|--------|-------|
| Backend / refactor | Tests pass, coverage, LOC, benchmark | `npm test`, `npm run bench`, `wc -l` | `npm run typecheck` or regression tests |
| Frontend | Lighthouse / bundle / interaction metrics | `npx lighthouse` | `npm test` |
| ML / data | Loss, val metric, runtime | project runner | domain-specific |
| Content / research | mechanical readability, length, checklist pass rate | custom script or `/autoresearch:ship` | optional review gate |
| Debug / fix / review / security | issue count, error count, findings score | matching autoresearch subcommand | regression tests if available |

Adapt the loop to your domain. The PRINCIPLES are universal; the METRICS are domain-specific.

## Integration with 4-Phase SOP

`autoresearch` 是与 4 阶段 SOP 并行的**自主执行模式**，而非替代品。以下是两者的整合点：

| autoresearch 子命令 | 在 SOP 中的位置 | 说明 |
|---|---|---|
| `/autoresearch:plan` | Phase 1 之前 | 将目标转化为可执行的 autoresearch 配置 |
| `/autoresearch:security` | Phase 4 之后（或独立） | 安全审计补充 Phase 4 对抗验证 |
| `/autoresearch:fix` | Phase 3 内部 | 自动修复编码阶段产生的测试/类型/lint 错误 |
| `/autoresearch:debug` | Phase 3 受阻时 | 自主 bug 猎手，配合 /debug 手动根因分析。参见 [`references/methodology-router.md`](./references/methodology-router.md) 获取方法论切换链 |
| `/autoresearch:review` | Phase 4 | 自动化闭环审查，替代单次的 `/review`，自动修复审查发现的问题直至收敛 |
| `/autoresearch:ship` | Phase 4 完成后 | 发布流程，复杂场景替代 `/finish` |

## Escalation 深度集成协议

### 压力升级闭环（所有 autoresearch 子命令通用）

| 环节 | 执行者 | 产出 |
|------|--------|------|
| **监控** | PostToolUse 钩子（`hooks-lifecycle`） | 检测命令失败，更新连续失败计数 |
| **检测** | Loop Protocol Phase 6 (Decide) | 根据失败计数判定压力等级 L0-L4 |
| **升级** | `escalation/SKILL.md` L1-L4 规则 | 执行等级对应的强制动作 |
| **验证** | 可验证输出要求（`escalation/SKILL.md`） | TSV 记录 `esc_level` + escalation-log.tsv |
| **记录** | Loop Protocol Phase 7 (Log) | results TSV、escalation-log.tsv、summary.md 三处同步 |
| **反馈** | Phase 7.5 Review Gate | 高频 keep 或 CRITICAL bug 后触发 `/review` 快速审查 |

### 必须产出的 Escalation 文件

| 文件 | 写入时机 | 格式 |
|------|---------|------|
| `.agent/.escalation-state` | 每次压力等级变化时 | dotenv 风格键值（FAIL_COUNT, LEVEL, METHODOLOGY, METHOD_SWITCHES, LAST_FAIL_TIME, ATTEMPTS_LOG） |
| `escalation-log.tsv` | 每次 L1+ 事件发生时 | TSV（iteration, level, trigger, checklist, methodology, outcome） |
| results TSV `esc_level` 列 | 每次迭代 | L0-L4 值 |
| results TSV `methodology` 列 | 每次迭代 | 当前方法论名称 |
| summary.md Escalation Stats | 循环结束时 | peak level, switches, checklists, review gates |

### Review Gate 触发条件

| 条件 | 审查类型 | 记录 |
|------|---------|------|
| bug severity == CRITICAL/HIGH | `/review` 快速模式 | TSV status = "review" |
| cumulative keeps ≥ 10（每 10 次一检） | `/review` 快速模式 | TSV status = "review_gate" |
| escalation level ≥ L3 | 七项清单记录到 log | TSV status = "escalation_L3" |

### Handoff 状态传递（跨子命令链接）

当 `--fix` 链接 debug→fix 时，传递 `handoff_state`（见 `references/debug-workflow.md` Handoff 协议章节），避免 fix 从零重建压力上下文。

> 💡 **连续失败时**：debug/fix 循环在连续失败时自动触发 `escalation` 压力升级（参见 [`../escalation/SKILL.md`](../escalation/SKILL.md)），按 L1-L4 递进响应，通过 [`references/methodology-router.md`](./references/methodology-router.md) 的方法论路由切换解决思路。所有升级事件**必须**记录到 escalation-log.tsv。

**检查点整合**: autoresearch 产出的 `security/`, `debug/`, `fix/`, `review/`, `ship/` 目录内容（含 `escalation-log.tsv`）应在 `/checkpoint` 状态文件中引用，确保跨会话可追踪。

**关键约束保留**: autoresearch 在 SOP 框架下运行时，以下规则始终生效，autoresearch 不覆盖：
- 修改测试前必须人类确认
- 禁止引入未授权第三方依赖
- 禁止修改 Guard/测试文件



## 自动化合规与护城河兜底验证
> 为了支撑 Autoresearch 闭环结构，当前技能库被强制挂载以下底层扫描探针。
可以使用如下命令验证当前技能在环境中的被干扰盲区：
```bash
bash .agent/scripts/health-check.sh .
bash .agent/scripts/validate-structure.sh .
```
