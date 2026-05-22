# AI Quality Operating System

This guide explains how Agentic Dev Kit prevents AI delivery from degrading into vibe coding.

## Problem It Solves

AI coding often fails after the code is written: missing edge cases, weak tests, broken UI states, vague content, hidden regressions, and overconfident final answers. The quality operating system moves those checks into the agent workflow so humans can spend attention on product design instead of routine QA.

## Core Loop

```
User Goal
  -> Requirement-Test Matrix
  -> Acceptance Criteria
  -> Implementation
  -> Tests / Probes / Content Review / Risk Review
  -> Evidence Ledger
  -> Quality Gate
  -> Referee Review
  -> Learning Update
```

## Files

- `.agent/quality/quality-contract.md`: delivery rules and exit conditions.
- `.agent/quality/assistant-system.md`: role ownership and anti-vibe-coding controls.
- `.agent/quality/human-attention-firewall.md`: what AI must verify without asking the human.
- `.agent/quality/content-quality-rubric.md`: content and UX copy review criteria.
- `.agent/quality/requirement-test-matrix.tsv`: maps each requirement to test/probe evidence.
- `.agent/quality/risk-register.tsv`: tracks delivery risks and mitigations.
- `.agent/quality/evidence-ledger.jsonl`: append-only verification evidence.
- `.agent/scripts/quality-gate.sh`: mechanical validator for the system.

## How To Use

Before coding, add rows to the Requirement-Test Matrix. After coding, run the actual verification commands and append Evidence Ledger entries. Before final response, run:

```bash
make quality-gate
```

If the gate fails, do not deliver. Fix the missing traceability, evidence, or risk handling first.

## What Humans Still Decide

Humans decide product direction, business facts, subjective taste, and explicit risk acceptance. AI owns tests, regression checks, content-state checks, browser/CLI probes, evidence collection, and review preparation.
