# AI Quality Operating Contract

This contract turns AI coding from "finish when confident" into "finish only when evidence closes every requirement." It applies to every feature, bug fix, refactor, content change, UI change, automation, and documentation change.

## Non-Negotiable Exit Rule

An agent may not claim completion until all of these artifacts agree:

- Requirement-Test Matrix: every requirement has mechanical acceptance criteria, an owner, a verification command, and passing evidence.
- Evidence Ledger: every verification claim points to a real command, artifact, or review output with a verdict.
- Risk Register: every known delivery risk is mitigated or explicitly accepted with evidence.
- Referee Gate: adversarial review finds zero unresolved high/critical issues and no behavior anti-patterns.
- Human Attention Firewall: humans are asked only for product judgment, business facts, or irreversible decisions, never for routine verification labor.

## Required Artifacts

| Artifact | Path | Purpose |
|---|---|---|
| Quality Contract | `.agent/quality/quality-contract.md` | Defines the delivery bar and exit rights. |
| Assistant System | `.agent/quality/assistant-system.md` | Defines role ownership so one agent does not grade its own homework alone. |
| Human Attention Firewall | `.agent/quality/human-attention-firewall.md` | Moves test, regression, content, and UI checking back to AI. |
| Content Quality Rubric | `.agent/quality/content-quality-rubric.md` | Makes content quality testable instead of subjective. |
| Requirement-Test Matrix | `.agent/quality/requirement-test-matrix.tsv` | Maps every requirement to tests, commands, and evidence. |
| Risk Register | `.agent/quality/risk-register.tsv` | Captures delivery risks before they become user-found bugs. |
| Evidence Ledger | `.agent/quality/evidence-ledger.jsonl` | Records what was verified, how, and with what result. |

## Development Gates

1. Intake Gate: translate the user request into requirement rows before implementation begins.
2. Acceptance Gate: each requirement must have mechanical acceptance criteria and a verification command.
3. Test Gate: changed behavior must have unit/integration/E2E/adversarial coverage appropriate to risk.
4. Content Gate: user-facing text, empty states, errors, labels, and data meaning must pass the content rubric.
5. UX Gate: UI work must include browser-level verification, responsive checks, and visual evidence when applicable.
6. Regression Gate: affected existing behavior must be re-run or explicitly risk-accepted.
7. Referee Gate: adversarial review must attack the diff and the evidence, not just the code.
8. Learning Gate: any failure, missed test, or human-found defect must update memory, captured patterns, or the quality contract.

## Evidence Rules

- A command not run is not evidence.
- A screenshot without the scenario and viewport is not evidence.
- A passing test without requirement mapping is not evidence of completeness.
- A content review without a rubric row is not evidence of content quality.
- A review finding without a file, artifact, command, or reasoned trace is not actionable evidence.

## Iteration Rule

When a new requirement arrives, the agent must update the Requirement-Test Matrix before coding, run the relevant gates after coding, and append new Evidence Ledger records before final delivery. The system must become stricter after every escaped defect.
