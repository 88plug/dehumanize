#!/usr/bin/env bash
# dehumanize: inject-correction.sh
# Runs on every UserPromptSubmit. STDOUT is appended to the user prompt.
# No set -e: this hook must never break a session.

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/dehumanize-${CLAUDE_PROJECT_ID:-default}"

if [ -f "$STATE_DIR/correction.txt" ]; then
  cat "$STATE_DIR/correction.txt"
  rm -f "$STATE_DIR/correction.txt"
fi

echo "You are AI, not a person. Access files directly, never ask for them. Fan out in parallel, never serialize. No human time units, no emotional filler, no \"this is complex.\" Compute and act now."

exit 0
