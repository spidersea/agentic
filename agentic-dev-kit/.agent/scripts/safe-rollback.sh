#!/usr/bin/env bash
# safe-rollback.sh -- controlled rollback entrypoint for autoresearch loops.
# Usage:
#   safe-rollback.sh status
#   safe-rollback.sh revert-head
#   safe-rollback.sh destructive-head

set -euo pipefail

ACTION="${1:-status}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "CRIT not inside a git worktree"
    exit 2
fi

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "DETACHED")
ROOT=$(git rev-parse --show-toplevel)
MARKER="$ROOT/.agent/state/agent-owned-worktree"
DIRTY=$(git status --porcelain)

is_agent_owned=0
case "$BRANCH" in
    autoresearch/*|agent/*|codex/*) is_agent_owned=1 ;;
esac
[ -f "$MARKER" ] && is_agent_owned=1

case "$ACTION" in
    status)
        echo "branch=$BRANCH"
        echo "root=$ROOT"
        echo "agent_owned=$is_agent_owned"
        if [ -n "$DIRTY" ]; then
            echo "dirty_files:"
            printf '%s\n' "$DIRTY"
        else
            echo "dirty_files=0"
        fi
        ;;
    revert-head)
        git revert HEAD --no-edit
        ;;
    destructive-head)
        if [ "$is_agent_owned" -ne 1 ]; then
            echo "CRIT destructive rollback denied: not an agent-owned worktree"
            exit 2
        fi
        if [ -n "$DIRTY" ]; then
            echo "CRIT destructive rollback denied: worktree has dirty files"
            printf '%s\n' "$DIRTY"
            exit 2
        fi
        if ! find "$ROOT/.agent/state" -maxdepth 1 \( -name '*results.tsv' -o -name '*tracker.md' \) 2>/dev/null | grep -q .; then
            echo "CRIT destructive rollback denied: no loop result/tracker artifact under .agent/state"
            exit 2
        fi
        git reset --hard HEAD~1
        ;;
    *)
        echo "Usage: safe-rollback.sh <status|revert-head|destructive-head>"
        exit 2
        ;;
esac
