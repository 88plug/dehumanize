#!/usr/bin/env bash
# dehumanize: session-init.sh — SessionStart hook.
# Resets per-session violation state and injects the operating directive via
# Claude's SessionStart additionalContext (stdout JSON). Never hard-fails.
set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DIRECTIVE="dehumanize: access yourself. fan out. no paste-asks. no human-time. execute."

# shellcheck source=lib/state.sh
. "$PLUGIN_ROOT/hooks/lib/state.sh" 2>/dev/null || {
  _dir="${XDG_RUNTIME_DIR:-/tmp}/dehumanize-${CLAUDE_PROJECT_ID:-default}"
  mkdir -p "$_dir" 2>/dev/null || true
  echo 0 > "$_dir/violations.txt" 2>/dev/null || true
  : > "$_dir/violations.log" 2>/dev/null || true
  rm -f "$_dir/correction.txt" 2>/dev/null || true
}

init_state >/dev/null 2>&1 || true
rm -f "$(get_state_dir 2>/dev/null)/correction.txt" 2>/dev/null || true
echo 0 > "$(get_state_dir 2>/dev/null)/violations.txt" 2>/dev/null || true
: > "$(get_state_dir 2>/dev/null)/violations.log" 2>/dev/null || true
date -u +%Y-%m-%dT%H:%M:%SZ > "$(get_state_dir 2>/dev/null)/session_start" 2>/dev/null || true

# Claude Code SessionStart: additionalContext on stdout (not stderr).
if command -v python3 >/dev/null 2>&1 || [ -x "$PLUGIN_ROOT/scripts/run-python.sh" ]; then
  _py=python3
  [ -x "$PLUGIN_ROOT/scripts/run-python.sh" ] && _py="$PLUGIN_ROOT/scripts/run-python.sh"
  printf '%s' "$DIRECTIVE" | "$_py" -c '
import json,sys
msg=sys.stdin.read()
print(json.dumps({
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": msg,
  }
}))' 2>/dev/null || printf '%s\n' "$DIRECTIVE"
else
  printf '%s\n' "$DIRECTIVE"
fi

exit 0
