---
name: deep-rules
version: 0.1.0
description: Extract non-obvious deep rules (hidden invariants, traps, boundary behaviors) from mature specs into compact .skills/*-knowledge/ files. Use after a feature cycle or when specs contain pitfalls that future agents cannot infer from code. Do not use for ordinary summaries.
x-source: aone-open
---

# Deep Rules

Design docs are temporary. Domain knowledge skills are runtime hints for future agents.

**Only persist knowledge that prevents future mistakes and is not easily recovered by grep.**

> ❌ 禁止把普通代码注释或显而易见的 API 用法当作 Deep Rule；禁止在未经验证的情况下写入规则。

## Quick Checklist

0. **Pre-flight** — scan existing `*-knowledge` skills; missing or >60d `last-verified` = stale
1. **Locate** — find mature spec/design/plan docs from user paths or known doc roots
2. **Group** — group by bounded domain, lifecycle, and trigger scenario
3. **Filter** — apply Searchability Gate; reject obvious or grepable facts
4. **Extract** — keep architecture constraints, rules, integrations, external facts, pitfalls
5. **Verify** — compare spec claims against real code; code wins over spec
6. **Write** — update `.skills/<prefix>-<module>-knowledge/SKILL.md`; hard cap 100 lines
7. **Report** — always output Verification Report and Spec Drift
8. **Gate** — final quality check: no grepable facts, all facts have evidence, ≤100 lines

## When to Use

Use after a feature cycle, before archiving mature specs, when no matching knowledge skill exists, or when the user asks to distill/persist reusable engineering knowledge into skills.

Do not use for ordinary summaries, brainstorming notes, abandoned plans, schedules, estimates, one-time debug logs, project-wide conventions, or facts obvious from code, names, paths, APIs, tables, or config keys.

## Step 0: Pre-flight

Scan current knowledge skills:

```bash
for f in .skills/*-knowledge/SKILL.md; do
  name=$(basename "$(dirname "$f")")
  date=$(grep "^last-verified:" "$f" | awk '{print $2}')
  lines=$(wc -l < "$f")
  echo "$name last-verified=${date:-MISSING} lines=$lines"
done
```

Rules:

* missing `last-verified` → stale
* `last-verified` older than 60 days → stale
* only fully verify stale skills, touched skills, or user-specified skills
* provisional skills older than 60 days must be promoted, rewritten, or removed

## Step 1: Locate Sources

Use user-provided paths first. Otherwise scan:

```text
docs/tech/
docs/superpowers/specs/
docs/superpowers/plans/
.aone_copilot/plans/
docs/design/
.claude/plans/
```

Only use mature docs: accepted designs, implementation plans, post-review specs, completed feature docs, or production-reviewed notes.

Ignore brainstorming, abandoned alternatives, estimates, schedules, and one-off debugging logs.

`source-specs` must list concrete file paths. Do not write vague values like `"3 specs from docs/"`.

## Step 2: Group Domain

Group by bounded context, not just keywords.

Signals:

* same module path
* same lifecycle/state machine
* same owner/service/entity group
* same failure boundary or release boundary
* same trigger scenario for future development

Shared ≥3 core classes may merge only when lifecycle and trigger scenario also match.

For 1–2 isolated specs, do not create a skill by default. Create `provisional: true` only if the docs contain high-risk external protocol facts, hidden state machines, migration traps, or rules that future agents cannot infer from code.

Cross-domain specs:

* main domain = module with most code impact
* main domain gets full knowledge
* secondary domain gets at most one cross-reference
* never duplicate the same fact in two skills

## Step 3: Searchability Gate

Before writing any candidate fact, ask:

```text
Can a future agent find this by simple grep and understand it from code?
```

Reject if true.

Reject examples:

* class names, method names, table names, API paths with no hidden rule
* obvious controller/service/mapper layering
* config keys whose meaning is clear from name
* file lists that can be found by search
* implementation steps already reflected in code

Keep only if it answers one of:

* **WHY** this design exists
* **WHEN / WHEN NOT** to use a path
* **MUST / MUST NOT** invariant
* hidden lifecycle or state transition
* cross-module integration contract
* external platform behavior
* historical trap or migration risk not visible in code

Evidence may contain grepable files or symbols. The persisted fact itself must not be merely grepable.

## Step 4: Extract Categories

Use only these default categories:

```yaml
architecture: system boundaries, ownership, non-obvious design constraints
rules: state machines, invariants, lifecycle, permissions, idempotency
integration: cross-module contracts, protocols, call chains, data ownership
external: third-party/platform facts verified by PoC, docs, vendor, or production
pitfalls: traps, failure modes, migration risks, rollback constraints
```

`code_patterns` is not a default category. Add it only if the convention is non-obvious and violations cause real bugs.

## Step 5: Verify Spec Against Code

Spec is not truth. Code is truth unless the item is explicitly marked `designing`.

Verification rules:

* Java class/interface/enum → grep Java declarations
* method/API path → grep Java/controllers/routes
* DB table/column → grep SQL/XML/Java constants/entities
* config key → grep YAML/properties/Java
* state/rule → verify enum, transition code, validator, test, or DB constraint
* external fact → cite source spec and verification method

Status:

* `verified` = confirmed in code
* `external` = external fact with source and verification method
* `designing` = recent spec <30d, no code yet
* `rejected` = contradicted by code, too old without implementation, or failed Searchability Gate

If spec and code disagree:

* code wins
* do not persist the spec claim as fact
* include the conflict in Verification Report as `Spec Drift`

## Step 6: Write Knowledge Skill

Create or update:

```text
.skills/<prefix>-<module>-knowledge/SKILL.md
```

Naming:

* `<project-prefix>-<module>-knowledge`
* examples: `fb-alert-knowledge`, `qa-agent-openapi-knowledge`, `uarp-runtime-knowledge`

Hard constraints:

* total file length ≤100 lines, no exceptions
* max 25 items per skill
* each item ≤3 lines where practical
* if still too long: delete low-value items, split domain, or replace detail with source evidence
* prefer removing grepable code patterns before removing pitfalls/rules/external facts

Required format:

````markdown
---
name: <prefix>-<module>-knowledge
description: Use when developing or modifying <module> in <path>; triggers: <3-5 scenarios>
last-verified: YYYY-MM-DD
source-specs:
  - <concrete/path/to/spec.md>
provisional: false
---

# <Module> Knowledge

```yaml
architecture:
  - id: A1
    fact: "<non-obvious design constraint>"
    evidence: ["<class/path/test/spec>"]

rules:
  - id: R1
    fact: "<must/must-not invariant>"
    evidence: ["<enum/validator/test/db constraint>"]

integration:
  - id: I1
    fact: "<cross-module contract>"
    evidence: ["<caller>", "<callee>", "<table/topic/api>"]

external:
  - id: E1
    fact: "<platform behavior>"
    source: "<spec/doc/poc>"
    verified_by: "<official-doc|poc|production|vendor>"
    stale_risk: "<low|medium|high>"

pitfalls:
  - id: P1
    fact: "<trap and safe behavior>"
    evidence: ["<code/spec/test>"]
```
````

## Boundary Rule

```text
Only this module's future developer will suffer if missing → knowledge skill
Everyone in the repo may suffer if missing → AGENTS.md / CLAUDE.md
Easy to grep and understand from code → do not persist
External or historical trap not visible in code → persist
```

## Incremental Update Rules

* new verified fact → append
* duplicate or grepable fact → skip
* contradicted by code → replace with implementation truth
* old spec-only fact → remove
* recent unimplemented spec fact → mark `designing`
* touched skill → update `last-verified`
* stale provisional skill → promote, rewrite, or delete
* vague `source-specs` → replace with concrete paths

## Mandatory Verification Report

Always output after writing:

```markdown
## Verification Report — <skill-name>
- Skill lines: <N>/100
- Items kept: <N>; rejected by Searchability Gate: <N>
- Verified: <N>; External: <N>; Designing: <N>; Removed: <N>
- Spec Drift: <list code-vs-spec conflicts, or none>
- Missing evidence: <list, or none>
- Action: <created|updated|split|removed stale facts>
- Verified at: YYYY-MM-DD
```

No Verification Report means the distillation is incomplete.

## Final Quality Gate

Before finishing, confirm:

* no obvious or grepable facts were persisted
* every kept fact prevents a realistic future mistake
* every kept fact has evidence, source, or verified method
* every `source-specs` entry is a concrete path
* file length is ≤100 lines
* provisional status is justified or removed
* Verification Report includes Spec Drift, even when none
