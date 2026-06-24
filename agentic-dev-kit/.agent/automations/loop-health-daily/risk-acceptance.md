# Risk Acceptance: loop-health-daily

## Scope

- Automation id: `loop-health-daily`
- Purpose: daily loop-engineering health check and evidence recording.

## Accepted Actions

- Run `.agent/scripts/loop-health.sh --record <project-root>`.
- Append JSONL evidence under `${CODEX_HOME:-$HOME/.codex}/state/loop-health/`.
- Read Codex configuration, automation metadata, hooks, skills, and selected project `.agent` state.

## Hard Limits

- Do not modify project source files.
- Do not start or resume trading, backtest, downloader, research, deployment, or long-running worker processes.
- Do not change automation status.
- Do not mutate Codex skills, hooks, automations, or memory except the loop-health evidence ledger.

## Review Trigger

Pause or review this automation if it writes outside `${CODEX_HOME:-$HOME/.codex}/state/loop-health/`, reports WARN/CRITICAL for two consecutive days, or fails to record evidence.
