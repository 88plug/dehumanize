#!/usr/bin/env bash
# dehumanize statusline badge. Never fails the status line (always exit 0).
set -u

STATE_DIR=""
if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -d "${XDG_RUNTIME_DIR}" ] && [ -w "${XDG_RUNTIME_DIR}" ]; then
  id="${CLAUDE_PROJECT_ID:-default}"
  id="$(printf '%s' "$id" | tr -c 'A-Za-z0-9._-' '_' 2>/dev/null || echo default)"
  STATE_DIR="${XDG_RUNTIME_DIR}/dehumanize-${id}"
else
  id="${CLAUDE_PROJECT_ID:-default}"
  id="$(printf '%s' "$id" | tr -c 'A-Za-z0-9._-' '_' 2>/dev/null || echo default)"
  STATE_DIR="/tmp/dehumanize-${USER:-u}-${id}"
fi

COUNT="$(cat "${STATE_DIR}/violations.txt" 2>/dev/null || echo 0)"
case "$COUNT" in
  ''|*[!0-9]*) COUNT=0 ;;
esac

if [ "$COUNT" = "0" ]; then
  echo "[DEHUMANIZE: OK]"
else
  echo "[DEHUMANIZE: ${COUNT}!]"
fi
exit 0
