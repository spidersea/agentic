---
name: quality-operating-system
description: End-to-end AI development quality system that binds requirements, tests, evidence, risk, content quality, adversarial review, and continuous learning before delivery.
version: 1.0.0
---

# Quality Operating System

Use this skill whenever the user asks for higher AI coding reliability, complete delivery, strict testing, content quality, review quality, or reduced human QA labor.

## Core Principle

Confidence is not an exit condition. Only evidence closes work.

Every delivery must connect:

```
Requirement -> Acceptance Criteria -> Test/Probe -> Command/Artifact -> Evidence -> Referee Verdict -> Learning Update
```

## Required Load Order

1. Read `.agent/quality/quality-contract.md`.
2. Update `.agent/quality/requirement-test-matrix.tsv` before implementation.
3. Update `.agent/quality/risk-register.tsv` for any uncertainty or high-impact surface.
4. Execute the relevant project tests, checks, browser probes, content review, security probes, or regression checks.
5. Append evidence to `.agent/quality/evidence-ledger.jsonl`.
6. Run `bash .agent/scripts/quality-gate.sh .`.
7. Run `/review` or a Referee Gate before final delivery.

## Gates

- Intake Gate: no coding until requirements have acceptance criteria.
- Test Gate: no behavior change without a test/probe mapping.
- Content Gate: no user-facing text change without content rubric evidence.
- UX Gate: no UI change without browser-level evidence when a runnable UI exists.
- Regression Gate: no shared-code change without affected-surface testing or accepted risk.
- Referee Gate: no final response while high/critical findings remain.
- Learning Gate: no repeated defect without a new rule, captured pattern, or quality row.

## Assistant Roles

Load `.agent/quality/assistant-system.md` for role ownership. The key control is separation: the same reasoning pass should not implement and approve a change without adversarial pressure.

## Human Attention Firewall

Load `.agent/quality/human-attention-firewall.md`. Ask humans for product decisions, not runnable verification.

## Mechanical Exit

Final delivery is allowed only when:

- Requirement-Test Matrix has no uncovered rows.
- Evidence Ledger has PASS evidence for every required row.
- Risk Register has no unmitigated row.
- `bash .agent/scripts/quality-gate.sh .` exits 0.
- Review/Referee verdict is PASS or explicitly risk-accepted by the human.
