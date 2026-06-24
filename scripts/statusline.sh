#!/usr/bin/env bash
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/dehumanize-${CLAUDE_PROJECT_ID:-default}"
COUNT=$(cat "$STATE_DIR/violations.txt" 2>/dev/null || echo "0")
if [[ "$COUNT" == "0" ]]; then
  echo "[DEHUMANIZE: OK]"
else
  echo "[DEHUMANIZE: ${COUNT}!]"
fi
