# Autonomous Loop Protocol

Detailed protocol for the autoresearch iteration loop. SKILL.md has the summary; this file has the full rules.

## Loop Modes

Autoresearch supports two loop modes:

- **Unbounded (default):** Loop forever until manually interrupted (`Ctrl+C`)
- **Bounded:** Loop exactly N times when `Iterations: N` is set in the inline config (or `--iterations N` flag for CLI/CI)

When bounded, track `current_iteration` against `max_iterations`. After the final iteration, print a summary and stop.

## Phase 1: Review (30 seconds)

Before each iteration, build situational awareness:

```
1. Read `.agent/state/tacit-tradition-map.md` (See `polanyi-protocol.md`)
2. Read current state of in-scope files (Focal Context)
3. Read last 10-20 entries from results log
4. Read git log --oneline -20 to see recent changes
5. Identify: what worked, what failed, what's untried
6. If bounded: check current_iteration vs max_iterations
```

**Why read every time?** After rollbacks, state may differ from what you expect. Never assume — always verify.

## Phase 2: Ideate (Strategic)

Pick the NEXT change. Priority order:

1. **Fix crashes/failures** from previous iteration first
2. **Exploit successes** — if last change improved metric, try variants in same direction
3. **Explore new approaches** — try something the results log shows hasn't been attempted
4. **Combine near-misses** — two changes that individually didn't help might work together
5. **Simplify** — remove code while maintaining metric. Simpler = better
6. **Radical experiments** — when incremental changes stall, try something dramatically different

**Anti-patterns:**
- Don't repeat exact same change that was already discarded
- Don't make multiple unrelated changes at once (can't attribute improvement)
- Don't chase marginal gains with ugly complexity

**Bounded mode consideration:** If remaining iterations are limited (<3 left), prioritize exploiting successes over exploration.

## Phase 3: Modify (One Atomic Change)

- Make ONE focused change to in-scope files
- The change should be explainable in one sentence
- Write the description BEFORE making the change (forces clarity)

## Phase 4: Commit (Before Verification)

```bash
git add <changed-files>
git commit -m "experiment: <one-sentence description>"
```

Commit BEFORE running verification so rollback is clean: `git reset --hard HEAD~1`

## Phase 5: Verify (Mechanical Only)

Run the agreed-upon verification command. Capture output.

**Timeout rule:** If verification exceeds 2x normal time, kill and treat as crash.

**Extract metric:** Parse the verification output for the specific metric number.

## Phase 5.5: Guard (Regression Check)

If a **guard** command was defined during setup, run it after verification.

The guard is a command that must ALWAYS pass — it protects existing functionality while the main metric is being optimized. Common guards: `npm test`, `npm run typecheck`, `pytest`, `cargo test`.

**Key distinction:**
- **Verify** answers: "Did the metric improve?" (the goal)
- **Guard** answers: "Did anything else break?" (the safety net)

**Guard rules:**
- Only run if a guard was defined (it's optional)
- Run AFTER verify — no point checking guard if the metric didn't improve
- Guard is pass/fail only (exit code 0 = pass). No metric extraction needed
- If guard fails, revert the optimization and try to rework it (max 2 attempts)
- NEVER modify guard/test files — always adapt the implementation instead
- Log guard failures distinctly so the agent can learn what kinds of changes cause regressions

**Guard failure recovery (max 2 rework attempts):**

When the guard fails but the metric improved, the optimization idea may still be viable — it just needs a different implementation that doesn't break behavior:

1. Revert the change (`git reset --hard HEAD~1`)
2. Read the guard output to understand WHAT broke (which tests, which assertions)
3. Rework the optimization to avoid the regression — e.g.:
   - If inlining a function broke callers → try a different optimization angle
   - If changing a data structure broke serialization → preserve the interface
   - If reordering logic broke edge cases → add the optimization more surgically
4. Commit the reworked version, re-run verify + guard
5. If both pass → keep. If guard fails again → one more attempt, then give up

**Critical:** Guard/test files are read-only. The optimization must adapt to the tests, never the other way around. If after 2 rework attempts the optimization can't pass the guard, discard it and move on to a different idea.

## Phase 6: Decide (No Ambiguity)

```
IF metric_improved AND (no guard OR guard_passed):
    STATUS = "keep"
    # Do nothing — commit stays
ELIF metric_improved AND guard_failed:
    IF optimization_is_revolutionary (massive metric gain but breaks existing guard):
        # Polanyi: Rebellion Against the Guard (See references/polanyi-protocol.md)
        STATUS = "meta-investigating guard"
        IF guard_is_obsolete:
            Rewrite the Guard / tests to align with the new, superior architecture.
            git add + commit reworked code AND new Guard.
            STATUS = "keep (guard rebelled and rewritten)"
            BREAK
    
    # Standard flow:
    git reset --hard HEAD~1
    # Rework the optimization (max 2 attempts)
    FOR attempt IN 1..2:
        Analyze guard output → rework implementation (NOT tests)
        git add + commit reworked version
        Re-run verify
        IF metric_improved:
            Re-run guard
            IF guard_passed:
                STATUS = "keep (reworked)"
                BREAK
        git reset --hard HEAD~1
    IF still failing after 2 attempts:
        STATUS = "discard"
        REASON = "guard failed, could not rework optimization"
ELIF metric_same_or_worse:
    STATUS = "discard"
    git reset --hard HEAD~1
ELIF crashed:
    # Attempt fix (max 3 tries)
    IF fixable:
        Fix → re-commit → re-verify → re-guard
    ELSE:
        STATUS = "crash"
        git reset --hard HEAD~1
```

**Simplicity override:** If metric barely improved (+<0.1%) but change adds significant complexity, treat as "discard". If metric unchanged but code is simpler, treat as "keep".

## Phase 7: Log Results

Append to results log (TSV format):

```
iteration  commit   metric   status   description                          esc_level  methodology        methodology_switch
42         a1b2c3d  0.9821   keep     increase attention heads from 8 to 12  L0         RCA根因分析         -
43         -        0.9845   discard  switch optimizer to SGD                L1         RCA根因分析         -
44         -        0.0000   crash    double batch size (OOM)                L2         搜索优先            RCA→搜索优先
```

**Escalation 状态追踪（每次迭代必须记录）**：
- `esc_level`：当前压力等级（L0-L4），基于连续 discard/crash 计数
- `methodology`：当前使用的方法论
- `methodology_switch`：如果本轮发生方法论切换，记录 `from→to`；否则 `-`
- 连续 keep 重置压力等级为 L0
- 压力等级判定规则详见 `../../escalation/SKILL.md`

## Phase 7.5: Review Gate (条件触发)

在 Log 之后、Repeat 之前，检查是否需要触发审查：

```
IF bug_severity == CRITICAL OR bug_severity == HIGH:
    触发 /review 快速模式（仅 Expert A 风险扫描）
    将审查结论记录到 results log（status = "review"）
    IF review 发现新问题 → 添加到修复队列

IF metric_improved_significantly AND complexity_increased:
    触发 Aesthetic Review Gate (审美审查层 - See references/polanyi-protocol.md)
    # 呼叫独立第三方 Agent 评估。若破坏隐性代码传统，赋予一票否决权并触发 Revert。

IF cumulative_keeps >= 10 AND last_review_iteration + 10 <= current_iteration:
    触发 /review 快速模式
    评估 keep 质量：是否有潜在回归、是否引入了不必要的复杂度
    记录到 results log（status = "review_gate"）

IF escalation_level >= L3:
    在 results log 中记录七项清单执行结果
    格式：status = "escalation_L3", description = "清单: 7/7 完成"
```

> ⚠️ Review Gate 不中断循环节奏 — 审查在本轮内完成后立即继续。其目的是确保高频 keep 不会积累隐性债务。

## Phase 8: Repeat

### Unbounded Mode (default)

Go to Phase 1. **NEVER STOP. NEVER ASK IF YOU SHOULD CONTINUE.**

### Bounded Mode (with Iterations: N)

```
IF current_iteration < max_iterations:
    Go to Phase 1
ELIF goal_achieved:
    Print: "Goal achieved at iteration {N}! Final metric: {value}"
    Print final summary
    STOP
ELSE:
    Print final summary
    STOP
```

**Final summary format:**
```
=== Autoresearch Complete (N/N iterations) ===
Baseline: {baseline} → Final: {current} ({delta})
Keeps: X | Discards: Y | Crashes: Z
Best iteration: #{n} — {description}

--- Escalation Stats ---
Peak escalation level: L{max}
Methodology switches: {count} ({list})
L3 checklists completed: {count}
Review gates triggered: {count}
Consecutive failure peak: {max_consecutive}
```

### When Stuck (>5 consecutive discards)

Applies to both modes.**Escalation 自动生效** — 参见 `../../escalation/SKILL.md`：

| 连续失败 | Escalation 等级 | 强制动作 |
|---------|----------------|----------|
| 2 | L1 ⚡ | 切换本质不同的方案 |
| 3 | L2 🔍 | 搜索 + 源码上下文 50 行 + 列 3 假设 |
| 4 | L3 📋 | 完成七项检查清单（每项记录到 log）|
| 5+ | L4 🚨 | 强制方法论切换（参见 `methodology-router.md`）|

**L3+ 恢复步骤**（在清单/切换之后）：
1. Re-read ALL in-scope files from scratch
2. Re-read the original goal/direction
3. Review entire results log for patterns
4. Try combining 2-3 previously successful changes
5. Try the OPPOSITE of what hasn't been working
6. Try a radical architectural change

> ⚠️ 首次 keep 后，压力等级重置为 L0，连续失败计数归零。

## Crash Recovery

- Syntax error → fix immediately, don't count as separate iteration
- Runtime error / Crash / Timeout → attempt mechanical fix (max 3 tries). 
  - IF STILL FAILING: Initiate **Epistemological Escalation (环境级断裂)** (See `references/polanyi-protocol.md`).
  - Enter Tool Alignment mode to investigate deep environment drifts or broken conceptual premises.
- Resource exhaustion (OOM) → revert, try smaller variant
- Infinite loop/hang → kill after timeout, revert, avoid that approach
- External dependency failure → skip, log, try different approach

## Communication

- **DO NOT** ask "should I keep going?" — in unbounded mode, YES. ALWAYS. In bounded mode, continue until N is reached.
- **DO NOT** summarize after each iteration — just log and continue
- **DO** print a brief one-line status every ~5 iterations (e.g., "Iteration 25: metric at 0.95, 8 keeps / 17 discards")
- **DO** alert if you discover something surprising or game-changing
- **DO** print a final summary when bounded loop completes
