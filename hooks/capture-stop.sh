#!/usr/bin/env bash
# dehumanize: capture-stop.sh
# Runs on the Stop event. Scans the last assistant turn for human-shaped framing
# and, if found, stores a correction for the next UserPromptSubmit to surface.
# No set -e: this hook must never break a session.

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# shellcheck source=lib/state.sh
. "$PLUGIN_ROOT/hooks/lib/state.sh" 2>/dev/null || exit 0
# shellcheck source=lib/detect-human-framing.sh
. "$PLUGIN_ROOT/hooks/lib/detect-human-framing.sh" 2>/dev/null || exit 0

transcript="$(find_session_jsonl 2>/dev/null)"
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

# Extract text from the most recent assistant message in the transcript.
last_text=""
if command -v jq >/dev/null 2>&1; then
  last_text="$(jq -rs '
    map(select(.type=="assistant" or .role=="assistant")) | last // empty
    | .message.content // .content // empty
    | if type=="array" then map(.text // empty) | join("\n")
      elif type=="string" then .
      else "" end
  ' "$transcript" 2>/dev/null)"
fi
[ -n "$last_text" ] || exit 0

if detect_human_framing "$last_text"; then
  exit 0
fi

count="$(increment_violations)"
patterns="${DETECTED_PATTERNS[*]:-}"
msg="dehumanize: previous turn used human framing (${patterns}). You are AI: access data directly, fan out in parallel, no human time units or emotional filler, no \"this is complex.\" Act now."
write_correction "$patterns" "$msg"

exit 0
