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

### /autoresearch:security — Autonomous Security Audit (v1.0.3)

Runs a comprehensive security audit using the autoresearch loop pattern. Generates a full STRIDE threat model, maps attack surfaces, then iteratively tests each vulnerability vector — logging findings with severity, OWASP category, and code evidence.

Load: `references/security-workflow.md` for full protocol.

**What it does:**

1. **Codebase Reconnaissance** — scans tech stack, dependencies, configs, API routes
2. **Asset Identification** — catalogs data stores, auth systems, external services, user inputs
3. **Trust Boundary Mapping** — browser↔server, public↔authenticated, user↔admin, CI/CD↔prod
4. **STRIDE Threat Model** — Spoofing, Tampering, Repudiation, Info Disclosure, DoS, Elevation of Privilege
5. **Attack Surface Map** — entry points, data flows, abuse paths
6. **Autonomous Loop** — iteratively tests each vector, validates with code evidence, logs findings
7. **Final Report** — severity-ranked findings with mitigations, coverage matrix, iteration log

**Key behaviors:**
- Follows red-team adversarial mindset (Security Adversary, Supply Chain, Insider Threat, Infra Attacker)
- Every finding requires **code evidence** (file:line + attack scenario) — no theoretical fluff
- Tracks OWASP Top 10 + STRIDE coverage, prints coverage summary every 5 iterations
- Composite metric: `(owasp_tested/10)*50 + (stride_tested/6)*30 + min(findings, 20)` — higher is better
- Creates `security/{YYMMDD}-{HHMM}-{audit-slug}/` folder with structured reports:
  `overview.md`, `threat-model.md`, `attack-surface-map.md`, `findings.md`, `owasp-coverage.md`, `dependency-audit.md`, `recommendations.md`, `security-audit-results.tsv`

**Flags:**

| Flag | Purpose |
|------|---------|
| `--diff` | Delta mode — only audit files changed since last audit |
| `--fix` | After audit, auto-fix confirmed Critical/High findings using autoresearch loop |
| `--fail-on {severity}` | Exit non-zero if findings meet threshold (for CI/CD gating) |

**Usage:**
```
# Unlimited — keep finding vulnerabilities until interrupted
/autoresearch:security

# Bounded — exactly 10 security sweep iterations
/autoresearch:security
Iterations: 10

# With focused scope
/autoresearch:security
Scope: src/api/**/*.ts, src/middleware/**/*.ts
Focus: authentication and authorization flows

# Delta mode — only audit changed files since last audit
/autoresearch:security --diff

# Auto-fix confirmed Critical/High findings after audit
/autoresearch:security --fix
Iterations: 15

# CI/CD gate — fail pipeline if any Critical findings
/autoresearch:security --fail-on critical
Iterations: 10

# Combined — delta audit + fix + gate
/autoresearch:security --diff --fix --fail-on critical
Iterations: 15
```

**Inspired by:**
- [Strix](https://github.com/usestrix/strix) — AI-powered security testing with proof-of-concept validation
- `/plan red-team` — adversarial review with hostile reviewer personas
- OWASP Top 10 (2021) — industry-standard vulnerability taxonomy
- STRIDE — Microsoft's threat modeling framework

### /autoresearch:ship — Universal Shipping Workflow (v1.1.0)

Ship anything — code, content, marketing, sales, research, or design — through a structured 8-phase workflow that applies autoresearch loop principles to the last mile.

Load: `references/ship-workflow.md` for full protocol.

**What it does:**

1. **Identify** — auto-detect what you're shipping (code PR, deployment, blog post, email campaign, sales deck, research paper, design assets)
2. **Inventory** — assess current state and readiness gaps
3. **Checklist** — generate domain-specific pre-ship gates (all mechanically verifiable)
4. **Prepare** — autoresearch loop to fix failing checklist items until 100% pass
5. **Dry-run** — simulate the ship action without side effects
6. **Ship** — execute the actual delivery (merge, deploy, publish, send)
7. **Verify** — post-ship health check confirms it landed
8. **Log** — record shipment to `ship-log.tsv` for traceability

**Supported shipment types:**

| Type | Example Ship Actions |
|------|---------------------|
| `code-pr` | `gh pr create` with full description |
| `code-release` | Git tag + GitHub release |
| `deployment` | CI/CD trigger, `kubectl apply`, push to deploy branch |
| `content` | Publish via CMS, commit to content branch |
| `marketing-email` | Send via ESP (SendGrid, Mailchimp) |
| `marketing-campaign` | Activate ads, launch landing page |
| `sales` | Send proposal, share deck |
| `research` | Upload to repository, submit paper |
| `design` | Export assets, share with stakeholders |

**Flags:**

| Flag | Purpose |
|------|---------|
| `--dry-run` | Validate everything but don't actually ship (stop at Phase 5) |
| `--auto` | Auto-approve dry-run gate if no errors |
| `--force` | Skip non-critical checklist items (blockers still enforced) |
| `--rollback` | Undo the last ship action (if reversible) |
| `--monitor N` | Post-ship monitoring for N minutes |
| `--type <type>` | Override auto-detection with explicit shipment type |
| `--checklist-only` | Only generate and evaluate checklist (stop at Phase 3) |

**Usage:**
```
# Auto-detect and ship (interactive)
/autoresearch:ship

# Ship code PR with auto-approve
/autoresearch:ship --auto

# Dry-run a deployment before going live
/autoresearch:ship --type deployment --dry-run

# Ship with post-deployment monitoring
/autoresearch:ship --monitor 10

# Prepare iteratively then ship
/autoresearch:ship
Iterations: 5

# Just check if something is ready to ship
/autoresearch:ship --checklist-only

# Ship a blog post
/autoresearch:ship
Target: content/blog/my-new-post.md
Type: content

# Ship a sales deck
/autoresearch:ship --type sales
Target: decks/q1-proposal.pdf

# Rollback a bad deployment
/autoresearch:ship --rollback
```

**Composite metric (for bounded loops):**
```
ship_score = (checklist_passing / checklist_total) * 80
           + (dry_run_passed ? 15 : 0)
           + (no_blockers ? 5 : 0)
```
Score of 100 = fully ready. Below 80 = not shippable.

**Output directory:** Creates `ship/{YYMMDD}-{HHMM}-{ship-slug}/` with `checklist.md`, `ship-log.tsv`, `summary.md`.

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

- User invokes `/autoresearch` or `/ug:autoresearch` → run the loop
- User invokes `/autoresearch:plan` → run the planning wizard
- User invokes `/autoresearch:security` → run the security audit
- User says "help me set up autoresearch", "plan an autoresearch run" → run the planning wizard
- User says "security audit", "threat model", "OWASP", "STRIDE", "find vulnerabilities", "red-team" → run the security audit
- User invokes `/autoresearch:ship` → run the ship workflow
- User says "ship it", "deploy this", "publish this", "launch this", "get this out the door" → run the ship workflow
- User invokes `/autoresearch:debug` → run the debug loop
- User says "find all bugs", "hunt bugs", "debug this", "why is this failing", "investigate" → run the debug loop
- User invokes `/autoresearch:fix` → run the fix loop
- User says "fix all errors", "make tests pass", "fix the build", "clean up errors" → run the fix loop
- User says "work autonomously", "iterate until done", "keep improving", "run overnight" → run the loop
- Any task requiring repeated iteration cycles with measurable outcomes → run the loop

## Bounded Iterations

By default, autoresearch loops **forever** until manually interrupted. To run exactly N iterations, add `Iterations: N` to your inline config.

**Unlimited (default):**
```
/autoresearch
Goal: Increase test coverage to 90%
```

**Bounded (N iterations):**
```
/autoresearch
Goal: Increase test coverage to 90%
Iterations: 25
```

After N iterations Claude stops and prints a final summary with baseline → current best, keeps/discards/crashes. If the goal is achieved before N iterations, Claude prints early completion and stops.

### When to Use Bounded Iterations

| Scenario | Recommendation |
|----------|---------------|
| Run overnight, review in morning | Unlimited (default) |
| Quick 30-min improvement session | `Iterations: 10` |
| Targeted fix with known scope | `Iterations: 5` |
| Exploratory — see if approach works | `Iterations: 15` |
| CI/CD pipeline integration | `--iterations N` flag (set N based on time budget) |

## Setup Phase (Do Once)

**If the user provides Goal, Scope, Metric, and Verify inline** → extract them and proceed to step 5.

**If any critical field is missing** → use `AskUserQuestion` to collect them interactively:

### Interactive Setup (when invoked without full config)

Scan the codebase first for smart defaults, then ask ALL questions in batched `AskUserQuestion` calls (max 4 per call). This gives users full clarity upfront.

**Batch 1 — Core config (4 questions in one call):**

Use a SINGLE `AskUserQuestion` call with these 4 questions:

| # | Header | Question | Options (smart defaults from codebase scan) |
|---|--------|----------|----------------------------------------------|
| 1 | `Goal` | "What do you want to improve?" | "Test coverage (higher)", "Bundle size (lower)", "Performance (faster)", "Code quality (fewer errors)" |
| 2 | `Scope` | "Which files can autoresearch modify?" | Suggested globs from project structure (e.g. "src/**/*.ts", "content/**/*.md") |
| 3 | `Metric` | "What number tells you if it got better? (must be a command output, not subjective)" | Detected options: "coverage % (higher)", "bundle size KB (lower)", "error count (lower)", "test pass count (higher)" |
| 4 | `Direction` | "Higher or lower is better?" | "Higher is better", "Lower is better" |

**Batch 2 — Verify + Guard + Launch (3 questions in one call):**

| # | Header | Question | Options |
|---|--------|----------|---------|
| 5 | `Verify` | "What command produces the metric? (I'll dry-run it to confirm)" | Suggested commands from detected tooling |
| 6 | `Guard` | "Any command that must ALWAYS pass? (prevents regressions)" | "npm test", "tsc --noEmit", "npm run build", "Skip — no guard" |
| 7 | `Launch` | "Ready to go?" | "Launch (unlimited)", "Launch with iteration limit", "Edit config", "Cancel" |

**After Batch 2:** Dry-run the verify command. If it fails, ask user to fix or choose a different command. If it passes, proceed with launch choice.

**IMPORTANT:** Always batch questions — never ask one at a time. Users should see all config choices together for full context.

### Setup Steps (after config is complete)

> ⛔ **防衰减迭代记录 (Loop Contract)**
> 决定开启 Autoresearch 循环后，必须在第一秒钟于磁盘创建 `autoresearch-tracker.md` 追踪器文件（或整合入 `task.md`）。
> 无论执行了多少次 Modify-Verify，每次决定退出循环前，必须扫描该文件确认“所有前置验证任务”是否打满 `[x]`，强行唤醒你的循环终点意识。

1. **Read all in-scope files** for full context before any modification
2. **Define the goal** — extracted from user input or inline config
3. **Define scope constraints** — validated file globs
4. **Define guard (optional)** — regression prevention command
5. **Create a results log** — Track every iteration (see `references/results-logging.md`)
6. **Establish baseline** — Run verification on current state AND guard (if set). Record as iteration #0
7. **Confirm and go** — Show user the setup, get confirmation, then BEGIN THE LOOP

## The Loop

Read `references/autonomous-loop-protocol.md` for full protocol details.

```
LOOP (FOREVER or N times):
  1. Review: Read current state + git history + results log
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
     - 🛡️ **OOM Protection**: Every 10 iterations, or if context usage is very high, automatically invoke `/context-reset` and persist tracker before continuing.

POST-LOOP (loop 结束或被中断后执行):
  10. Learning: 从 results log 提取经验并沉淀
      - 从 keep 记录中提取有效 Pattern（如"拆分大函数 → 覆盖率提升"）
      - 从 discard 记录中提取无效 Anti-pattern（如"批量重命名 → 无覆盖率提升"）
      - 如果 keep 率 < 30%，反思策略方向是否正确
      - 将高价值经验调用 /learn 写入 continuous-learning 本能存储
      - 输出：summary + 经验提取 + 建议下次起点
```

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

Adapt the loop to your domain. The PRINCIPLES are universal; the METRICS are domain-specific.

## Integration with 4-Phase SOP

`autoresearch` 是与 4 阶段 SOP 并行的**自主执行模式**，而非替代品。以下是两者的整合点：

| autoresearch 子命令 | 在 SOP 中的位置 | 说明 |
|---|---|---|
| `/autoresearch:plan` | Phase 1 之前 | 将目标转化为可执行的 autoresearch 配置 |
| `/autoresearch:security` | Phase 4 之后（或独立） | 安全审计补充 Phase 4 对抗验证 |
| `/autoresearch:fix` | Phase 3 内部 | 自动修复编码阶段产生的测试/类型/lint 错误 |
| `/autoresearch:debug` | Phase 3 受阻时 | 自主 bug 猎手，配合 /debug 手动根因分析。参见 `references/methodology-router.md` 获取方法论切换链 |
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

**检查点整合**: autoresearch 产出的 `security/`, `debug/`, `fix/`, `ship/` 目录内容（含 `escalation-log.tsv`）应在 `/checkpoint` 状态文件中引用，确保跨会话可追踪。

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
