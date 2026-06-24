#!/usr/bin/env bash
# loop-health.sh -- health report for the local loop-engineering stack.
# Usage: bash ~/.codex/scripts/loop-health.sh [--record] [project_root ...]

set -uo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
RECORD=0
PROJECTS=()
for arg in "$@"; do
    case "$arg" in
        --record) RECORD=1 ;;
        *) PROJECTS+=("$arg") ;;
    esac
done
if [ "${#PROJECTS[@]}" -eq 0 ]; then
    PROJECTS=("$PWD")
fi

WARNINGS=0
CRITICALS=0
MUTATING_AUTOMATIONS=""

CODEX_HOME_ABS="$CODEX_HOME"
if [ -d "$CODEX_HOME" ]; then
    CODEX_HOME_ABS=$(cd "$CODEX_HOME" 2>/dev/null && pwd)
fi
LOCAL_AGENT_MODE=0
if [ "$(basename "$CODEX_HOME_ABS")" = ".agent" ] && [ -d "$CODEX_HOME_ABS/skills" ]; then
    LOCAL_AGENT_MODE=1
fi

mark_warn() { WARNINGS=$((WARNINGS + 1)); }
mark_crit() { CRITICALS=$((CRITICALS + 1)); }

status_line() {
    local level="$1" label="$2" detail="$3"
    case "$level" in
        ok)   printf "OK    %-34s %s\n" "$label" "$detail" ;;
        info) printf "INFO  %-34s %s\n" "$label" "$detail" ;;
        warn) printf "WARN  %-34s %s\n" "$label" "$detail"; mark_warn ;;
        crit) printf "CRIT  %-34s %s\n" "$label" "$detail"; mark_crit ;;
    esac
}

count_toml_status() {
    local status="$1"
    [ -d "$CODEX_HOME/automations" ] || { echo 0; return; }
    local count
    count=$(find "$CODEX_HOME/automations" -name automation.toml -type f 2>/dev/null \
        -exec awk -v s="$status" '
            $1 == "status" && $3 == "\"" s "\"" { c++ }
            END { print c + 0 }
        ' {} + 2>/dev/null)
    echo "${count:-0}"
}

automation_field() {
    local file="$1" field="$2"
    awk -v key="$field" '
        $1 == key && $2 == "=" {
            sub(/^[^=]*= "/, "")
            sub(/"$/, "")
            print
            exit
        }
    ' "$file" 2>/dev/null
}

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

file_age_hours() {
    local file="$1"
    [ -f "$file" ] || { echo ""; return; }
    local now mtime
    now=$(date +%s)
    mtime=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null || echo "")
    [ -n "$mtime" ] || { echo ""; return; }
    echo $(( (now - mtime) / 3600 ))
}

echo "Loop Engineering Health"
echo "checked_at: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "codex_home: $CODEX_HOME"
if [ "$LOCAL_AGENT_MODE" -eq 1 ]; then
    echo "mode: project-local .agent"
fi
echo

echo "== Core Paths =="
if [ -d "$CODEX_HOME" ]; then
    status_line ok "CODEX_HOME exists" "$CODEX_HOME"
else
    status_line crit "CODEX_HOME missing" "$CODEX_HOME"
fi

if [ -d "$CODEX_HOME/memories" ]; then
    status_line ok "global memories path" "$CODEX_HOME/memories"
elif [ "$LOCAL_AGENT_MODE" -eq 1 ] && [ -d "$CODEX_HOME/memory" ]; then
    status_line ok "memory path" "project-local .agent/memory"
else
    status_line warn "global memories path missing" "$CODEX_HOME/memories"
fi

if [ "$LOCAL_AGENT_MODE" -eq 1 ] && [ -d "$CODEX_HOME/memory" ]; then
    status_line ok "legacy memory path absent" "project-local .agent/memory is expected"
elif [ -d "$CODEX_HOME/memory" ]; then
    status_line warn "legacy memory path present" "$CODEX_HOME/memory"
else
    status_line ok "legacy memory path absent" "no conflicting ~/.codex/memory"
fi

if [ -f "$CODEX_HOME/AGENTS.md" ]; then
    if grep -q "~/.codex/memory/.dreaming-log.md" "$CODEX_HOME/AGENTS.md"; then
        status_line warn "AGENTS memory path" "mentions legacy ~/.codex/memory"
    else
        status_line ok "AGENTS memory path" "does not hard-code legacy path"
    fi
elif [ "$LOCAL_AGENT_MODE" -eq 1 ] && [ -f "$(dirname "$CODEX_HOME_ABS")/AGENTS.md" ]; then
    status_line ok "AGENTS.md" "$(dirname "$CODEX_HOME_ABS")/AGENTS.md"
else
    status_line crit "AGENTS.md missing" "$CODEX_HOME/AGENTS.md"
fi

echo
echo "== Automations =="
if [ -d "$CODEX_HOME/automations" ]; then
    total=$(find "$CODEX_HOME/automations" -name automation.toml -type f 2>/dev/null | wc -l | tr -d ' ')
    active=$(count_toml_status ACTIVE)
    paused=$(count_toml_status PAUSED)
    status_line ok "automation definitions" "total=$total active=$active paused=$paused"
    if [ "$active" -eq 0 ] && [ "$LOCAL_AGENT_MODE" -eq 1 ]; then
        status_line ok "automation heartbeat" "template/local mode; no ACTIVE automation required"
    elif [ "$active" -eq 0 ]; then
        status_line warn "automation heartbeat" "no ACTIVE automation"
    else
        status_line ok "automation heartbeat" "at least one ACTIVE automation"
    fi
    if [ -f "$CODEX_HOME/automations/loop-health-daily/automation.toml" ]; then
        status_line ok "loop-health automation" "defined"
    elif [ "$LOCAL_AGENT_MODE" -eq 1 ] && [ -f "$CODEX_HOME/automations/loop-health-daily/risk-acceptance.md" ]; then
        status_line ok "loop-health automation" "risk template present"
    else
        status_line warn "loop-health automation" "not defined"
    fi
    while IFS= read -r automation_file; do
        grep -q '^status = "ACTIVE"' "$automation_file" 2>/dev/null || continue
        prompt=$(automation_field "$automation_file" prompt)
        name=$(automation_field "$automation_file" name)
        id=$(automation_field "$automation_file" id)
        case "$prompt" in
            *"Do not modify files"*|*"read-only"*|*"Read-only"*)
                ;;
            *"continue"*|*"Continue"*|*"run "*|*"Run "*|*"start "*|*"Start "*|*"resume"*|*"Resume"*|*"download"*|*"Download"*|*"modify"*|*"Modify"*|*"fix"*|*"Fix"*)
                status_line info "active mutating automation" "${id:-$name}"
                risk_file="$CODEX_HOME/automations/${id:-}/risk-acceptance.md"
                if [ -f "$risk_file" ]; then
                    status_line ok "automation risk acceptance" "${id:-$name}"
                else
                    status_line warn "automation risk acceptance" "${id:-$name} missing risk-acceptance.md"
                fi
                if [ -n "$MUTATING_AUTOMATIONS" ]; then
                    MUTATING_AUTOMATIONS="$MUTATING_AUTOMATIONS,${id:-$name}"
                else
                    MUTATING_AUTOMATIONS="${id:-$name}"
                fi
                ;;
        esac
    done < <(find "$CODEX_HOME/automations" -name automation.toml -type f 2>/dev/null)
else
    if [ "$LOCAL_AGENT_MODE" -eq 1 ]; then
        status_line ok "automations directory" "template/local mode; optional"
    else
        status_line warn "automations directory" "missing"
    fi
fi

echo
echo "== Hooks =="
hook_dir="$CODEX_HOME/hooks/post-tool"
required_hooks="guard-enforcer.sh memory-update.sh overconfidence-detector.sh polanyi-persist.sh reasoning-relay-check.sh"
if [ -d "$hook_dir" ]; then
    for hook in $required_hooks; do
        path="$hook_dir/$hook"
        if [ -x "$path" ]; then
            status_line ok "hook executable" "$hook"
        elif [ -f "$path" ]; then
            status_line warn "hook not executable" "$hook"
        else
            status_line warn "hook missing" "$hook"
        fi
    done
    if grep -q "exec_command" "$hook_dir"/guard-enforcer.sh "$hook_dir"/memory-update.sh "$hook_dir"/overconfidence-detector.sh 2>/dev/null; then
        status_line ok "Codex tool compatibility" "exec_command recognized by post-tool hooks"
    else
        status_line warn "Codex tool compatibility" "post-tool hooks may only recognize legacy tool names"
    fi
else
    status_line warn "post-tool hook dir" "missing"
fi

echo
echo "== Skills And Protocols =="
for skill in autoresearch agent-dsl memory-protocol dreaming hooks-lifecycle quality-operating-system escalation multi-agent; do
    if [ -f "$CODEX_HOME/skills/$skill/SKILL.md" ]; then
        status_line ok "skill present" "$skill"
    else
        status_line warn "skill missing" "$skill"
    fi
done

if grep -q "agent-owned worktree" "$CODEX_HOME/skills/autoresearch/references/autonomous-loop-protocol.md" 2>/dev/null; then
    status_line ok "destructive rollback guard" "documented"
else
    status_line crit "destructive rollback guard" "not documented"
fi

if [ -x "$CODEX_HOME/scripts/safe-rollback.sh" ]; then
    status_line ok "safe rollback entrypoint" "$CODEX_HOME/scripts/safe-rollback.sh"
else
    status_line warn "safe rollback entrypoint" "missing or not executable"
fi

if [ -x "$CODEX_HOME/scripts/loop-terminal-verdict.sh" ]; then
    status_line ok "terminal verdict script" "$CODEX_HOME/scripts/loop-terminal-verdict.sh"
else
    status_line warn "terminal verdict script" "missing or not executable"
fi

if [ -x "$CODEX_HOME/scripts/hook-self-test.sh" ]; then
    status_line ok "hook self-test script" "$CODEX_HOME/scripts/hook-self-test.sh"
else
    status_line warn "hook self-test script" "missing or not executable"
fi

echo
echo "== Project State =="
for project in "${PROJECTS[@]}"; do
    [ -d "$project" ] || { status_line warn "project missing" "$project"; continue; }
    abs_project=$(cd "$project" 2>/dev/null && pwd)
    echo "-- $abs_project"
    if [ -d "$abs_project/.agent/memory" ]; then
        status_line ok "project memory" ".agent/memory exists"
        log="$abs_project/.agent/memory/.dreaming-log.md"
        age=$(file_age_hours "$log")
        if [ -n "$age" ]; then
            if [ "$age" -gt 24 ]; then
                status_line warn "dreaming log freshness" "${age}h old"
            else
                status_line ok "dreaming log freshness" "${age}h old"
            fi
        else
            status_line warn "dreaming log" "missing"
        fi
    elif [[ "$abs_project" == "$HOME/Documents/Codex/"* ]]; then
        status_line ok "project memory" "projectless/transient Codex workspace; no .agent required"
    else
        status_line warn "project memory" "no .agent/memory"
    fi

    trackers=$(find "$abs_project/.agent/state" -maxdepth 1 \( -name '*tracker.md' -o -name '*results.tsv' \) 2>/dev/null | wc -l | tr -d ' ')
    if [ "$trackers" -gt 0 ]; then
        status_line ok "loop state artifacts" "$trackers tracker/result files"
    elif [[ "$abs_project" == "$HOME/Documents/Codex/"* ]]; then
        status_line ok "loop state artifacts" "projectless/transient workspace; no tracker required"
    else
        status_line info "loop state artifacts" "none found; no active loop evidence yet"
    fi
done

echo
echo "== Verdict =="
VERDICT="PASS"
if [ "$CRITICALS" -gt 0 ]; then
    VERDICT="CRITICAL"
    echo "verdict: CRITICAL"
    echo "criticals: $CRITICALS"
    echo "warnings: $WARNINGS"
    EXIT_CODE=2
elif [ "$WARNINGS" -gt 0 ]; then
    VERDICT="WARN"
    echo "verdict: WARN"
    echo "warnings: $WARNINGS"
    EXIT_CODE=1
else
    echo "verdict: PASS"
    EXIT_CODE=0
fi

if [ "$RECORD" -eq 1 ]; then
    LEDGER_DIR="$CODEX_HOME/state/loop-health"
    LEDGER="$LEDGER_DIR/evidence.jsonl"
    mkdir -p "$LEDGER_DIR"
    TS=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    MUTATING_ESCAPED=$(json_escape "$MUTATING_AUTOMATIONS")
    printf '{"ts":"%s","verdict":"%s","warnings":%d,"criticals":%d,"active_automations":%d,"paused_automations":%d,"mutating_automations":"%s"}\n' \
        "$TS" "$VERDICT" "$WARNINGS" "$CRITICALS" "${active:-0}" "${paused:-0}" "$MUTATING_ESCAPED" >> "$LEDGER"
    echo "recorded: $LEDGER"
fi

exit "$EXIT_CODE"
