#!/usr/bin/env bash
# loop-terminal-verdict.sh -- decides whether loop engineering has earned terminal status.
# Usage: loop-terminal-verdict.sh [required_days]

set -uo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
REQUIRED_DAYS="${1:-7}"
LEDGER="$CODEX_HOME/state/loop-health/evidence.jsonl"

if [ ! -f "$LEDGER" ]; then
    echo "PENDING no loop-health evidence ledger: $LEDGER"
    exit 1
fi

PASS_DAYS=$(awk -v cutoff="$(date -u -v-"$REQUIRED_DAYS"d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d "$REQUIRED_DAYS days ago" '+%Y-%m-%dT%H:%M:%SZ')" '
    /"verdict":"PASS"/ {
        match($0, /"ts":"[^"]+"/)
        ts=substr($0, RSTART+6, RLENGTH-7)
        day=substr(ts, 1, 10)
        if (ts >= cutoff) days[day]=1
    }
    END { for (d in days) c++; print c+0 }
' "$LEDGER")

RECENT_BAD=$(awk -v cutoff="$(date -u -v-"$REQUIRED_DAYS"d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d "$REQUIRED_DAYS days ago" '+%Y-%m-%dT%H:%M:%SZ')" '
    /"verdict":"(WARN|CRITICAL)"/ {
        match($0, /"ts":"[^"]+"/)
        ts=substr($0, RSTART+6, RLENGTH-7)
        day=substr(ts, 1, 10)
        if (ts >= cutoff) bad[day]=$0
    }
    END { for (d in bad) print bad[d] }
' "$LEDGER")

echo "evidence_ledger=$LEDGER"
echo "required_days=$REQUIRED_DAYS"
echo "pass_days=$PASS_DAYS"

if [ "$PASS_DAYS" -lt "$REQUIRED_DAYS" ]; then
    echo "PENDING need $REQUIRED_DAYS distinct PASS days"
    if [ -n "$RECENT_BAD" ]; then
        echo "recent_warn_or_critical_days:"
        echo "$RECENT_BAD" | tail -5
    fi
    exit 1
fi

if [ -n "$RECENT_BAD" ]; then
    echo "PENDING recent WARN/CRITICAL evidence exists"
    echo "$RECENT_BAD" | tail -5
    exit 1
fi

echo "TERMINAL loop engineering status earned"
exit 0
