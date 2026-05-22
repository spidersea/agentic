#!/usr/bin/env bash
# ============================================================================
# quality-gate.sh — AI delivery completeness gate
# Verifies the project has a requirement-to-test matrix, evidence ledger, and
# risk register before an agent can claim delivery quality.
# Usage: bash .agent/scripts/quality-gate.sh [project-root]
# Exit codes: 0=pass, 1=quality gate failed, 2=missing quality system
# ============================================================================

set -uo pipefail

PROJECT_ROOT="${1:-.}"
QUALITY_DIR="$PROJECT_ROOT/.agent/quality"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}AI Quality Gate${NC}"
echo -e "${CYAN}Project:${NC} $(cd "$PROJECT_ROOT" 2>/dev/null && pwd || echo "$PROJECT_ROOT")"
echo ""

if [ ! -d "$QUALITY_DIR" ]; then
    echo -e "${RED}FAIL:${NC} missing .agent/quality directory"
    exit 2
fi

python3 - "$PROJECT_ROOT" <<'PY'
import csv
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
quality = root / ".agent" / "quality"

required_files = {
    "quality-contract.md": "global delivery contract",
    "assistant-system.md": "role ownership model",
    "human-attention-firewall.md": "human/AI responsibility split",
    "content-quality-rubric.md": "content and UX quality rubric",
    "requirement-test-matrix.tsv": "requirement-to-test traceability",
    "risk-register.tsv": "known quality risks and mitigations",
    "evidence-ledger.jsonl": "verification evidence ledger",
}

errors = []
warnings = []

for rel, purpose in required_files.items():
    path = quality / rel
    if not path.exists():
        errors.append(f"missing {rel} ({purpose})")
    elif path.stat().st_size == 0:
        errors.append(f"{rel} is empty")

if errors:
    for err in errors:
        print(f"FAIL: {err}")
    sys.exit(1)

def read_tsv(path, expected_header):
    with path.open(newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh, delimiter="\t")
        header = reader.fieldnames or []
        if header != expected_header:
            errors.append(
                f"{path.name} header mismatch: expected {expected_header}, got {header}"
            )
            return []
        return list(reader)

rtm_header = [
    "requirement_id",
    "scope",
    "source",
    "acceptance_criteria",
    "test_level",
    "verification_command",
    "evidence_id",
    "owner",
    "status",
]
risk_header = [
    "risk_id",
    "requirement_id",
    "risk",
    "impact",
    "mitigation",
    "evidence_id",
    "status",
]

rtm_rows = read_tsv(quality / "requirement-test-matrix.tsv", rtm_header)
risk_rows = read_tsv(quality / "risk-register.tsv", risk_header)

if not rtm_rows:
    errors.append("requirement-test-matrix.tsv has no requirement rows")
if not risk_rows:
    errors.append("risk-register.tsv has no risk rows")

soft_tokens = {"tbd", "todo", "later", "unknown", "n/a", "na", ""}

for row in rtm_rows:
    rid = row["requirement_id"]
    if row["status"] != "covered":
        errors.append(f"{rid} status must be covered, got {row['status']!r}")
    if row["verification_command"].strip().lower() in soft_tokens:
        errors.append(f"{rid} has no executable verification command")
    if row["evidence_id"].strip().lower() in soft_tokens:
        errors.append(f"{rid} has no evidence_id")
    if row["acceptance_criteria"].strip().lower() in soft_tokens:
        errors.append(f"{rid} has no mechanical acceptance criteria")
    if row["test_level"].strip().lower() in soft_tokens:
        errors.append(f"{rid} has no test level")

for row in risk_rows:
    risk_id = row["risk_id"]
    if row["status"] not in {"mitigated", "accepted"}:
        errors.append(f"{risk_id} status must be mitigated or accepted, got {row['status']!r}")
    if row["mitigation"].strip().lower() in soft_tokens:
        errors.append(f"{risk_id} has no mitigation")
    if row["evidence_id"].strip().lower() in soft_tokens:
        errors.append(f"{risk_id} has no evidence_id")

evidence_path = quality / "evidence-ledger.jsonl"
required_evidence_keys = {
    "evidence_id",
    "requirement_id",
    "command",
    "exit_code",
    "artifact",
    "verdict",
    "timestamp",
}
evidence = {}
lines = [line for line in evidence_path.read_text(encoding="utf-8").splitlines() if line.strip()]
if not lines:
    errors.append("evidence-ledger.jsonl has no evidence records")

for idx, line in enumerate(lines, 1):
    try:
        item = json.loads(line)
    except json.JSONDecodeError as exc:
        errors.append(f"evidence-ledger.jsonl line {idx} is invalid JSON: {exc}")
        continue
    missing = sorted(required_evidence_keys - set(item))
    if missing:
        errors.append(f"evidence {idx} missing keys: {', '.join(missing)}")
        continue
    if item["verdict"] not in {"PASS", "FAIL", "PARTIAL", "BLOCKED"}:
        errors.append(f"evidence {item['evidence_id']} has invalid verdict {item['verdict']!r}")
    if item["verdict"] == "PASS" and int(item["exit_code"]) != 0:
        errors.append(f"evidence {item['evidence_id']} says PASS but exit_code is not 0")
    artifact = str(item["artifact"]).strip()
    if artifact and not artifact.startswith(("http://", "https://")):
        artifact_path = root / artifact
        if not artifact_path.exists():
            errors.append(f"evidence {item['evidence_id']} artifact does not exist: {artifact}")
    evidence[item["evidence_id"]] = item

def split_ids(value):
    return [part.strip() for part in value.split(",") if part.strip()]

for row in rtm_rows:
    for evid in split_ids(row["evidence_id"]):
        item = evidence.get(evid)
        if not item:
            errors.append(f"{row['requirement_id']} references missing evidence {evid}")
        elif item["verdict"] != "PASS":
            errors.append(f"{row['requirement_id']} evidence {evid} is not PASS")

for row in risk_rows:
    for evid in split_ids(row["evidence_id"]):
        item = evidence.get(evid)
        if not item:
            errors.append(f"{row['risk_id']} references missing evidence {evid}")
        elif item["verdict"] == "FAIL":
            errors.append(f"{row['risk_id']} evidence {evid} is FAIL")

contract = (quality / "quality-contract.md").read_text(encoding="utf-8")
contract_terms = [
    "Requirement-Test Matrix",
    "Evidence Ledger",
    "Risk Register",
    "Referee Gate",
    "Human Attention Firewall",
]
for term in contract_terms:
    if term not in contract:
        errors.append(f"quality-contract.md missing required term: {term}")

if errors:
    print("VERDICT: FAIL")
    for err in errors:
        print(f"- {err}")
    if warnings:
        print("WARNINGS:")
        for warning in warnings:
            print(f"- {warning}")
    sys.exit(1)

print("VERDICT: PASS")
print(f"- requirements covered: {len(rtm_rows)}")
print(f"- risks handled: {len(risk_rows)}")
print(f"- evidence records: {len(evidence)}")
PY

RESULT=$?
echo ""
if [ "$RESULT" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}Quality gate passed.${NC}"
else
    echo -e "${RED}${BOLD}Quality gate failed.${NC}"
fi
exit "$RESULT"
