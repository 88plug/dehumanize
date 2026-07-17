#!/usr/bin/env bash
# dehumanize: session-init.sh — SessionStart hook.
# Resets per-session violation state and prints a one-screen operating reminder.
# Best-effort: never hard-fails a session (no set -e).
set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# shellcheck source=lib/state.sh
. "$PLUGIN_ROOT/hooks/lib/state.sh" 2>/dev/null || {
  # Minimal fallback if state lib is missing.
  _dir="${XDG_RUNTIME_DIR:-/tmp}/dehumanize-${CLAUDE_PROJECT_ID:-default}"
  mkdir -p "$_dir" 2>/dev/null || true
  echo 0 > "$_dir/violations.txt" 2>/dev/null || true
  : > "$_dir/violations.log" 2>/dev/null || true
  rm -f "$_dir/correction.txt" 2>/dev/null || true
  cat >&2 <<'BANNER'
dehumanize: access yourself. fan out. no paste-asks. no human-time. execute.
BANNER
  exit 0
}

init_state >/dev/null 2>&1 || true
# Clear any leftover one-shot correction from a prior session in this state dir.
rm -f "$(get_state_dir)/correction.txt" 2>/dev/null || true
echo 0 > "$(get_state_dir)/violations.txt" 2>/dev/null || true
: > "$(get_state_dir)/violations.log" 2>/dev/null || true
date -u +%Y-%m-%dT%H:%M:%SZ > "$(get_state_dir)/session_start" 2>/dev/null || true

cat >&2 <<'BANNER'
dehumanize: access yourself. fan out. no paste-asks. no human-time. execute.
BANNER

exit 0
