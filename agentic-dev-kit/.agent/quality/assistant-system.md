# Assistant System

The quality system uses role separation to prevent one agent from planning, coding, testing, and approving its own work without friction.

## Core Roles

| Role | Owns | Must Produce | Cannot Do |
|---|---|---|---|
| Lead Agent | Scope, sequencing, risk triage | Task plan, affected surface, delivery summary | Skip gates to save time |
| Spec Agent | Requirements and acceptance | Requirement-Test Matrix updates | Implement code before criteria exist |
| Implementation Agent | Minimal code changes | Diff aligned to accepted scope | Expand scope silently |
| Test Agent | Test design and execution | Test cases, command output, coverage notes | Modify production code to make tests pass |
| UX/Content Agent | User-facing quality | Content rubric verdict, UI scenario checks | Treat visual inspection as optional |
| Security/Reliability Agent | Safety, input, auth, failure behavior | Risk Register updates, threat probes | Accept unverified assumptions |
| Adversary Agent | Attack assumptions and evidence | Confirmed issue list or PASS verdict | Provide soothing summaries |
| Referee Agent | Final arbitration | PASS/FAIL/PARTIAL verdict | Approve without evidence |
| Learning Agent | Continuous improvement | Failure pattern, captured rule, or skill update | Leave repeated defects as anecdotes |

## Role Handoff Rule

Each role must leave evidence for the next role. A role handoff without an artifact is treated as incomplete.

## Anti-Vibe-Coding Controls

- Scope Creep Brake: any feature not present in the matrix is unauthorized.
- Verification Brake: final answers must cite executed commands or explain why no command exists.
- Aesthetic Brake: UI/content changes require scenario checks, not only "looks fine."
- Regression Brake: changes to shared code require affected tests or a risk acceptance row.
- Learning Brake: repeated manual correction from the user becomes a permanent gate.
