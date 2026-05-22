# Human Attention Firewall

Human attention is reserved for product taste, business facts, prioritization, and irreversible tradeoffs. AI owns mechanical verification.

## AI Must Own

- Discovering and running available test commands.
- Writing tests for changed behavior.
- Checking error, empty, loading, permission, and boundary states.
- Checking content consistency, truncation, missing labels, and misleading copy.
- Running browser or CLI verification for user-facing flows.
- Checking regression impact before final delivery.
- Writing evidence into `.agent/quality/evidence-ledger.jsonl`.
- Updating `.agent/quality/requirement-test-matrix.tsv`.
- Updating `.agent/quality/risk-register.tsv`.

## Human May Own

- Product direction and priority.
- Brand voice or subjective design preference.
- Business facts that are not present in code, docs, or accessible tools.
- Legal, financial, or operational decisions that require accountable human approval.
- Explicit acceptance of a known risk when no automated verification is practical.

## Prohibited Handoffs

The agent must not ask the human to:

- "Try it and tell me if it works" when the agent can run it.
- "Check whether the page is blank" when a browser check is available.
- "See if the tests pass" when a test command exists.
- "Review all edge cases" before the agent has enumerated and probed them.
- "Find any regressions" before affected-surface analysis has been done.
