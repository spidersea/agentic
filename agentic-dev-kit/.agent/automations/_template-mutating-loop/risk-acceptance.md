# Risk Acceptance: template-mutating-loop

## Scope

- Workspace: `<absolute-project-root>`
- Automation id: `<automation-id>`
- Purpose: bounded progress monitoring and continuation for one explicitly named loop.

## Accepted Actions

- Run the project evaluator or health check and report blockers.
- If no relevant process is running, perform at most one bounded recovery or progress action.
- Write only expected artifacts under the existing project output paths.
- Record loop-health evidence when configured.

## Hard Limits

- Never start a second simultaneous research, backtest, downloader, deployment, or long-running worker process.
- Never claim production readiness unless the project evaluator reports ready and independent readiness checks pass.
- Never mutate Codex skills, hooks, automations, or global memory from this automation.
- Never run destructive rollback commands unless `.agent/scripts/safe-rollback.sh` reports that the worktree is agent-owned and clean of unrelated user edits.

## Review Trigger

Pause or review this automation if any of the following occur:

- Duplicate long-running process is detected.
- `.agent/scripts/loop-health.sh` reports WARN or CRITICAL.
- Expected artifacts stop advancing while automation remains ACTIVE.
- The automation needs to write outside the declared project paths.
- The user asks to pause, stop, or switch direction.
