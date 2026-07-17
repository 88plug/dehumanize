#!/usr/bin/env bash
# dehumanize: inject-correction.sh
# UserPromptSubmit: inject a one-shot correction if Stop queued one.
# STDOUT is appended to context. Consumes the pending file so it fires once.
# No set -e: this hook must never break a session.
set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# shellcheck source=lib/state.sh
if ! . "$PLUGIN_ROOT/hooks/lib/state.sh" 2>/dev/null; then
  # Fallback one-shot without the library.
  STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/dehumanize-${CLAUDE_PROJECT_ID:-default}"
  if [ -f "$STATE_DIR/correction.txt" ]; then
    cat "$STATE_DIR/correction.txt" 2>/dev/null || true
    rm -f "$STATE_DIR/correction.txt" 2>/dev/null || true
  fi
  exit 0
fi

# One-shot: emit pending correction (if any) and delete it.
if get_pending_correction 2>/dev/null; then
  # Always end cleanly after a one-shot inject.
  exit 0
fi

exit 0
