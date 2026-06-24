#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/dehumanize-${CLAUDE_PROJECT_ID:-default}"

mkdir -p "$STATE_DIR"
echo "0" > "$STATE_DIR/violations.txt"
touch "$STATE_DIR/violations.log"
date -u +%Y-%m-%dT%H:%M:%SZ > "$STATE_DIR/session_start"

cat >&2 <<'BANNER'
dehumanize active: work like AI, not a human.
- Read/run/grep directly. Never ask for files or output you can access yourself.
- Fan out independent work in parallel. No serial "first I'll, then I'll" checklists.
- No man-hours/sprints/FTEs, no excitement or apologies, no "this is complex/will take time." Just execute.
BANNER
