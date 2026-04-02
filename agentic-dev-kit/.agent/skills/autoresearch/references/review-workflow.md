# Review Workflow — /autoresearch:review

Autonomous continuous code review loop. It eliminates the manual "review → human approval → fix → re-review" cycle by integrating review and fix into a cohesive, self-driving iterative loop.

**Core idea:** Scope → Review → Classify → Auto-Fix → Re-Review → Repeat until convergence (zero issues).

## Trigger

- User invokes `/autoresearch:review`
- User says "continually review and fix this", "run an autoresearch review loop", "review and fix all issues"
- Autoresearch fix triggers it automatically if chained (`--from-fix`)

## Loop Support

```
# Unlimited — keep reviewing and fixing until zero issues are found
/autoresearch:review

# Bounded — exactly N review/fix iterations
/autoresearch:review
Iterations: 10

# Focused scope
/autoresearch:review
Scope: src/api/**/*.ts
```

## Interactive Setup (when invoked without flags)

If `/autoresearch:review` is invoked without explicit `--scope`, use `AskUserQuestion` to gather full context in ONE batched call before investigating.

**Single batched call — all 4 questions at once:**

Use ONE `AskUserQuestion` call with all 4 questions:

| # | Header | Question | Options |
|---|--------|----------|---------|
| 1 | `Scope` | "Which files should I review and fix?" | Suggested globs from project structure + "Recent changes (git diff)" + "Entire codebase" |
| 2 | `Mode` | "What review depth should I use?" | "Standard (6 dimensions)", "Quick (Risk scan only)", "Deep (Component by component)" |
| 3 | `Strategy`| "How should I handle fixes?" | "Auto-fix all issues (recommended)", "Report only (do not fix)" |
| 4 | `Launch`| "Ready to start the review loop?" | "Loop until zero issues", "Loop with iteration limit", "Edit config", "Cancel" |

**IMPORTANT:** Always ask all 4 questions in a single call.

If `--scope`, `--auto-fix`, or `--report-only` flags are provided, skip the interactive setup and proceed directly to Phase 1.

## Architecture

```
/autoresearch:review
  ├── Phase 1: Scope (what files are we reviewing?)
  ├── Phase 2: Review (run adversarial A/B/C review)
  ├── Phase 3: Classify & Log (extract confirmed issues)
  ├── Phase 4: Decide (if 0 issues → STOP)
  ├── Phase 5: Auto-Fix (fix ALL confirmed issues)
  ├── Phase 6: Verify (re-review the fixes)
  └── Phase 7: Repeat (next iteration)
```

## Phase 1: Scope — Target Selection

Determine which files to review.
- If `--scope` is provided: Expand globs.
- If `--diff` is provided: Only review files modified in `git diff` against `HEAD` or target branch.
- If chained from fix (`--from-fix`): Target files that were fixed in the previous session.

**Output:** `✓ Phase 1: Scoped — [N] files targeted for review`

## Phase 2: Review — Adversarial Scanning

Execute the standard review process.
It leverages the 6 dimensions defined in `.agent/rules/code-review.md`.

*   **1. Security**
*   **2. Correctness**
*   **3. Maintainability**
*   **4. Backward Compatibility**
*   **5. Test Coverage**
*   **6. Impact Analysis**

> 📋 Uses the Expert A / Opponent B / Referee C adversarial synthesis model to ensure high-fidelity, evidence-backed findings.

**Output:** A structured `VERDICT` report.

## Phase 3: Classify & Log

Extract all confirmed issues from the `VERDICT`.

- **Issues found**: Assigned a severity (CRITICAL, HIGH, MEDIUM, LOW).
- **Anti-patterns**: Logged as issues to fix.
- **Excluded**: False positives are recorded to prevent regression in future review loops (Anti-Oscillation).

**Log to `review-results.tsv`:**
```tsv
iteration	status	issues_found	issues_fixed	verdict	escalation_level
1	reviewed	4	0	FAIL	L0
```

## Phase 4: Decide (Convergence Check)

```
IF VERDICT == PASS AND issues_found == 0:
    continuous_pass_count += 1
    IF continuous_pass_count >= 2:
        PRINT "=== Convergence Reached — Zero Issues ==="
        STOP
ELSE:
    continuous_pass_count = 0
```
*Note: Requiring 2 continuous passes ensures no subtle regressions were introduced during the final fix verification.*

**Anti-Oscillation check:** If an identical issue is found, fixed, and found again in the next loop, mark it as `blocked` and do not attempt to auto-fix it again to prevent an infinite loop.

## Phase 5: Auto-Fix (All Severities)

> [!IMPORTANT]
> The `autoresearch:review` loop embraces full autonomy. **ALL issues (Critical, High, Medium, Low) are automatically targeted for fixing** without human gating.

Sequence for fixing:
1. Prioritize Critical/High first.
2. Apply ONE fix at a time (atomic change).
3. Commit the fix (`git commit -m "fix(review): resolve [issue]"`).
4. Run guard condition if defined (e.g., `npm test`).
5. **If guard fails**: Revert and rework (up to 2 attempts, adhering to normal fix escalation).

## Phase 6: Verify

After all issues in the current batch are "fixed" (or skipped), the loop continues to the next iteration, which naturally re-runs the adversarial review (Phase 2) on the updated state.
This ensures the fix actually satisfied the Referee C criteria.

## Output Directory

Creates `review/{YYMMDD}-{HHMM}-{review-slug}/` with:
- `review-results.tsv` — Iteration log
- `escalation-log.tsv` — Escalation events
- `findings.md` — All discovered issues, with their resolution status (fixed/blocked/ignored).
- `summary.md` — Executive summary, score, and Escalation Stats.
- `blocked.md` — Issues that caused oscillation or exceeded rework limits and require human analysis.

## Composite Metric

For bounded loops, the review loop's effectiveness metric:

```
review_score = (issues_resolved / max(issues_found, 1)) * 60 
             + (dimensions_passed / 6) * 30 
             + (no_oscillations ? 10 : 0)
```
Higher is better. 100 indicates all issues found were resolved and passed a final clean review.

## Escalation & Methodology Router Integration

Like other `autoresearch` subcommands, the review loop triggers escalation when fixes repeatedly fail to satisfy the reviewer constraints.

| Trigger | Escalation Behavior |
|---------|---------------------|
| Fix for same issue fails guard 2x | **L1**: Switch fixing approach. |
| Issue oscillating (review → fix → re-review finds it again) | **L2**: Gather context, 3 new hypotheses for why fix failed. |
| 4 continuous loops without reducing total issues | **L3**: 7-point checklist required before continuing. |
| 5+ deadlocked loops | **L4**: Log to `blocked.md`, skip issue. |

## Chaining Patterns (Bidirectional)

```bash
# Debug → Fix → Review
/autoresearch:debug
/autoresearch:fix --from-debug
/autoresearch:review --from-fix

# Review → internal fix → Review is automatic
/autoresearch:review

# Review only (augmented standard review)
/autoresearch:review --report-only

# Review specific dimensions
/autoresearch:review --dimensions security,correctness
```
