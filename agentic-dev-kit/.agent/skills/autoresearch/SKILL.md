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


### /autoresearch:review — Autonomous Code Review Loop (v1.0.0)

Autonomous loop that eliminates manual code review-fix cycles. It runs an adversarial review (Expert A / Opponent B / Referee C), automatically extracts confirmed issues across all severity levels, auto-fixes them, and then re-reviews until it reaches zero issues convergence or hits bounded limits.

Load: `references/review-workflow.md` for full protocol.

**What it does:**
1. **Scope Selection** — Targets specified files, recent diffs, or hands off from `fix`.
2. **Adversarial Review** — Scans 6 dimensions (`.agent/rules/code-review.md`).
3. **Classify & Log** — Extracts issues and logs them (filters false positives to prevent oscillation).
4. **Convergence Check** — If VERDICT=PASS 2 times continuously → done.
5. **Auto-Fix** — Automatically prioritizes and fixes ALL issues (no human gating by default).
6. **Verify** — Re-runs adversarial loop automatically.

**Usage:**
```
# Continually review and fix until clean
/autoresearch:review

# Review specific scope and only verify (equivalent to standard /review)
/autoresearch:review --report-only
Scope: src/components/**

# Chain from fix
/autoresearch:fix
/autoresearch:review --from-fix
```

### /autoresearch:security — Autonomous Security Audit (v1.0.3)

STRIDE threat model + OWASP Top 10 + red-team (4 adversarial personas). Load: `references/security-workflow.md`.

**Flow:** Reconnaissance → Asset ID → Trust Boundaries → STRIDE → Attack Surface → Autonomous Loop → Final Report

**Key rules:** Every finding needs **code evidence** (file:line + attack scenario). Composite metric: `(owasp/10)*50 + (stride/6)*30 + min(findings,20)`.

| Flag | Purpose |
|------|---------|
| `--diff` | Delta mode — only changed files |
| `--fix` | Auto-fix Critical/High after audit |
| `--fail-on {sev}` | CI/CD gate (exit non-zero) |

Usage: `/autoresearch:security`, `--diff --fix --fail-on critical`, `Scope: src/api/**`

### /autoresearch:ship — Universal Shipping Workflow (v1.1.0)

Ship anything through a structured 8-phase workflow. Load: `references/ship-workflow.md`.

**Flow:** Identify → Inventory → Checklist → Prepare (loop) → Dry-run → Ship → Verify → Log

**Supported types:** `code-pr` · `code-release` · `deployment` · `content` · `marketing-email` · `marketing-campaign` · `sales` · `research` · `design`

| Flag | Purpose |
|------|---------|
| `--dry-run` | Stop at Phase 5 |
| `--auto` | Auto-approve dry-run gate |
| `--force` | Skip non-critical items |
| `--rollback` | Undo last ship |
| `--monitor N` | Post-ship monitoring N mins |
| `--checklist-only` | Stop at Phase 3 |

Metric: `ship_score = (passing/total)*80 + (dry_run?15:0) + (no_blockers?5:0)`. Score ≥80 = shippable.

Usage: `/autoresearch:ship`, `--auto`, `--type deployment --dry-run`, `--monitor 10`

### /autoresearch:plan — Goal → Configuration Wizard

Converts a plain-language goal into a validated, ready-to-execute autoresearch configuration.

Load: `references/plan-workflow.md` for full protocol.

**Quick summary:**

1. **Capture Goal** — ask what the user wants to improve (or accept inline text)
2. **Analyze Context** — scan codebase for tooling, test runners, build scripts
3. **Define Scope** — suggest file globs, validate they resolve to real files
4. **Define Metric** — suggest mechanical metrics, validate they output a number
5. **Define Direction** — higher or lower is better
6. **Define Verify** — construct the shell command. 🛡️ **Safety Check FIRST**: Scan against `.agent/workflows/hooks.md` Layer 1 dangerous patterns (e.g. `rm -rf`). Only if safe, **dry-run it** to confirm it works.
7. **Confirm & Launch** — present the complete config, offer to launch immediately

**Critical gates:**
- Metric MUST be mechanical (outputs a parseable number, not subjective)
- Verify command MUST pass a dry run on the current codebase before accepting
- Scope MUST resolve to ≥1 file

**Usage:**
```
/autoresearch:plan
Goal: Make the API respond faster

/autoresearch:plan Increase test coverage to 95%

/autoresearch:plan Reduce bundle size below 200KB
```

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

| Scenario | Recommendation |
|----------|---------------|
| Overnight | Unlimited |
| Quick session | `Iterations: 10` |
| Targeted fix | `Iterations: 5` |
| CI/CD | `--iterations N` |

## Setup Phase

**If Goal/Scope/Metric/Verify inline** → extract and proceed to step 5.

**If missing** → batch 2 rounds of `AskUserQuestion`: Batch 1 (Goal/Scope/Metric/Direction) + Batch 2 (Verify/Guard/Launch). Always batch — never ask one at a time. Dry-run verify command before accepting.

### Setup Steps (after config is complete)

> ⛔ **防衰减迭代记录 (Loop Contract)**
> 决定开启 Autoresearch 循环后，必须在第一秒钟于磁盘创建 `autoresearch-tracker.md` 追踪器文件（或整合入 `task.md`）。
> 无论执行了多少次 Modify-Verify，每次决定退出循环前，必须扫描该文件确认“所有前置验证任务”是否打满 `[x]`，强行唤醒你的循环终点意识。

1. **Read all in-scope files** for full context before any modification
2. **⚡ Polanyi Excavation (强制前置步骤，非可选修饰符)** — 在任何修改前必须完成：
   - **2a. Tacit Tradition Map 构建/更新** — 扫描代码库的"不成文规则"：
     - 命名约定（为什么这个变量叫 `_legacy_handler`？）
     - 隐式依赖（这个文件假设 Redis 已初始化但从未检查）
     - 历史决策痕迹（`git blame` 找到关键决策的 commit message）
   - **2b. 意图-实现 Gap 分析** — 识别代码的**意图**与**实现**之间的裂缝（这是 Mythos 发现零日漏洞的核心能力）
   - **2c. 持久化** — 写入 `.agent/state/tacit-tradition-map.md`（如已存在则增量更新）
   - **退出条件**：tacit-tradition-map.md 至少包含 3 条隐性规则才可进入下一步
   - 详见 `references/polanyi-protocol.md` + `../polanyi/SKILL.md`
3. **Define the goal** — extracted from user input or inline config
4. **Define scope constraints** — validated file globs
5. **Define guard (optional)** — regression prevention command
6. **Create a results log** — Track every iteration (see `references/results-logging.md`)
7. **Establish baseline** — Run verification on current state AND guard (if set). Record as iteration #0
8. **Confirm and go** — Show user the setup, get confirmation, then BEGIN THE LOOP

## The Loop

Read `references/autonomous-loop-protocol.md` for full protocol details.

```
LOOP (FOREVER or N times):
  1. Review: Read current state + git history + results log
     🔒 **Frozen Input Injection (Anti-Drift)**:
     在每次迭代开始时，重新读取 FROZEN 目标（Goal + Scope + Metric + Exit）。
     如果当前工作方向与 FROZEN 目标偏差明显（如目标是"提高覆盖率"
     但当前在"重构代码结构"），强制 rollback 到上次 keep 点并重新对齐。
     灵感来源：OpenMythos `e = x` — 编码后的输入在每次循环中作为不变锚点注入。
  2. Ideate: Pick next change based on goal, past results, what hasn't been tried
  3. Modify: Make ONE focused change to in-scope files
  4. Commit: Git commit the change (before verification)
  5. Verify: Run the mechanical metric. 🛡️ **Timeout Protection**: MUST use a timeout wrapper (e.g. `timeout 120 <cmd>`) to prevent process hanging.
  6. Guard: If guard is set, run the guard command
  7. Decide:
     - IMPROVED + guard passed (or no guard) → Keep commit, log "keep", advance
     - IMPROVED + guard FAILED → Revert, then try to rework the optimization
       (max 2 attempts) so it improves the metric WITHOUT breaking the guard.
       Never modify guard/test files — adapt the implementation instead.
       If still failing → log "discard (guard failed)" and move on
     - SAME/WORSE → Git revert, log "discard"
     - CRASHED → Try to fix (max 3 attempts), else log "crash" and move on
  8. Log: Record result in results log
  9. Repeat: Go to step 1.
     - If unbounded: NEVER STOP. NEVER ASK "should I continue?"
     - If bounded (N): Stop after N iterations, print final summary
     - 🛡️ **OOM Protection (弹性恢复)**: Every 10 iterations, or if context usage
       is very high, automatically persist tracker → compress context → restore
       execution position → seamlessly continue. 用户无感知，无需人工介入。
       灵感来源：OpenMythos `except StopIteration: data_iter = iter(loader)` 模式。

POST-LOOP (loop 结束或被中断后执行):
  10. Learning: 从 results log 提取经验并沉淀
      - 从 keep 记录中提取有效 Pattern（如"拆分大函数 → 覆盖率提升"）
      - 从 discard 记录中提取无效 Anti-pattern（如"批量重命名 → 无覆盖率提升"）
      - 如果 keep 率 < 30%，反思策略方向是否正确
      - 将高价值经验调用 /learn 写入 continuous-learning 本能存储
      - 输出：summary + 经验提取 + 建议下次起点
```

## ACT 自适应停机 (Adaptive Computation Time)

> 灵感来源：OpenMythos Recurrent-Depth Transformer 的 ACT Halting 机制。
> 核心理念：简单子任务快速收敛退出，复杂子任务深度迭代直到稳定。节省 30-50% token。

### 置信度累积规则

在每次迭代的 Decide 阶段（步骤 7），除了 keep/discard 判定外，同步更新 **收敛置信度**：

```
confidence = 0.0  # 每个子任务/文件的独立置信度

每次迭代后：
  PASS (keep)              → confidence += 0.4
  PASS_WITH_WARNINGS       → confidence += 0.2
  FAIL (discard)           → confidence = 0.0  # 重置
  CRASH                    → confidence = 0.0  # 重置

  if confidence ≥ ACT_THRESHOLD (默认 0.99):
      → 子任务收敛，标记为 CONVERGED，跳过后续迭代
      → 在 results TSV 中记录 status="converged" + convergence_iter=N
```

### 效果

| 子任务复杂度 | 典型收敛轮次 | 说明 |
|------------|------------|------|
| 简单 (添加注释、格式化) | 2-3 轮 | 连续 3 次 PASS → confidence=1.2 ≥ 0.99 |
| 中等 (Bug 修复、小重构) | 4-6 轮 | 偶尔 FAIL 重置，需多次 PASS 累积 |
| 复杂 (架构变更、安全修复) | 8+ 轮 | 频繁 FAIL，需深度迭代 |

### 约束

1. ACT 停机仅适用于**子任务级别**。全局 `until` 退出条件仍然是硬死锁，不受 ACT 影响
2. ACT 阈值可通过 `Convergence: 0.8` 内联配置降低（适用于快速验证场景）
3. 当使用 `--effort max` 时，ACT 自动禁用 — 强制跑满所有迭代

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

See `references/core-principles.md` for the 7 generalizable principles from autoresearch.

## Adapting to Different Domains

| Domain | Metric | Scope | Verify Command | Guard |
|--------|--------|-------|----------------|-------|
| Backend code | Tests pass + coverage % | `src/**/*.ts` | `npm test` | — |
| Frontend UI | Lighthouse score | `src/components/**` | `npx lighthouse` | `npm test` |
| ML training | val_bpb / loss | `train.py` | `uv run train.py` | — |
| Blog/content | Word count + readability | `content/*.md` | Custom script | — |
| Performance | Benchmark time (ms) | Target files | `npm run bench` | `npm test` |
| Refactoring | Tests pass + LOC reduced | Target module | `npm test && wc -l` | `npm run typecheck` |
| Security | OWASP + STRIDE coverage + findings | API/auth/middleware | `/autoresearch:security` | — |
| Shipping | Checklist pass rate (%) | Any artifact | `/autoresearch:ship` | Domain-specific |
| Debugging | Bugs found + coverage | Target files | `/autoresearch:debug` | — |
| Fixing | Error count (lower) | Target files | `/autoresearch:fix` | `npm test` |
| Review | Issues resolved -> 0 | Target files | `/autoresearch:review` | `npm test` |

Adapt the loop to your domain. The PRINCIPLES are universal; the METRICS are domain-specific.

## Integration with 4-Phase SOP

`autoresearch` 是与 4 阶段 SOP 并行的**自主执行模式**，而非替代品。以下是两者的整合点：

| autoresearch 子命令 | 在 SOP 中的位置 | 说明 |
|---|---|---|
| `/autoresearch:plan` | Phase 1 之前 | 将目标转化为可执行的 autoresearch 配置 |
| `/autoresearch:security` | Phase 4 之后（或独立） | 安全审计补充 Phase 4 对抗验证 |
| `/autoresearch:fix` | Phase 3 内部 | 自动修复编码阶段产生的测试/类型/lint 错误 |
| `/autoresearch:debug` | Phase 3 受阻时 | 自主 bug 猎手，配合 /debug 手动根因分析。参见 `references/methodology-router.md` 获取方法论切换链 |
| `/autoresearch:review` | Phase 4 | 自动化闭环审查，替代单次的 `/review`，自动修复审查发现的问题直至收敛 |
| `/autoresearch:ship` | Phase 4 完成后 | 发布流程，复杂场景替代 `/finish` |

## Escalation 深度集成协议

### 压力升级闭环（所有 autoresearch 子命令通用）

```
监控 → 检测 → 升级 → 验证 → 记录 → 反馈
  ↑                                      ↓
  ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
```

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
| `.escalation-state.json` | 每次压力等级变化时 | JSON（level, failures, methodology, exhausted） |
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

> 💡 **连续失败时**：debug/fix 循环在连续失败时自动触发 `escalation` 压力升级（参见 `../escalation/SKILL.md`），按 L1-L4 递进响应，通过 `references/methodology-router.md` 的方法论路由切换解决思路。所有升级事件**必须**记录到 escalation-log.tsv。

**检查点整合**: autoresearch 产出的 `security/`, `debug/`, `fix/`, `review/`, `ship/` 目录内容（含 `escalation-log.tsv`）应在 `/checkpoint` 状态文件中引用，确保跨会话可追踪。

**关键约束保留**: autoresearch 在 SOP 框架下运行时，以下全规范规则**始终生效**，autoresearch 不覆盖：
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
