#!/usr/bin/env bash
# dehumanize: capture-stop.sh
# Runs on the Stop event. Scans the last assistant turn for human-shaped framing
# and, if found, stores a one-shot correction for the next UserPromptSubmit.
# No set -e: this hook must never break a session.
set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# shellcheck source=lib/state.sh
. "$PLUGIN_ROOT/hooks/lib/state.sh" 2>/dev/null || exit 0
# shellcheck source=lib/detect-human-framing.sh
. "$PLUGIN_ROOT/hooks/lib/detect-human-framing.sh" 2>/dev/null || exit 0

# Optional hook payload on stdin (transcript_path / session_id).
INPUT=""
if [ ! -t 0 ]; then
  INPUT="$(cat 2>/dev/null || true)"
fi

# Resolve a Python interpreter if available (optional — jq path is preferred).
_py() {
  if [ -x "${PLUGIN_ROOT}/scripts/run-python.sh" ]; then
    "${PLUGIN_ROOT}/scripts/run-python.sh" "$@"
    return $?
  fi
  local p
  for p in python3 python3.14 python3.12 python3.11 python /usr/bin/python3 /usr/bin/python; do
    if command -v "$p" >/dev/null 2>&1 || [ -x "$p" ]; then
      "$p" "$@"
      return $?
    fi
  done
  return 127
}

hint=""
if [ -n "$INPUT" ]; then
  hint="$(printf '%s' "$INPUT" | _py -c '
import json,sys
try:
    d=json.load(sys.stdin)
except Exception:
    d={}
print(d.get("transcript_path") or d.get("transcriptPath") or "")
' 2>/dev/null || true)"
fi

transcript="$(find_session_jsonl "$hint" 2>/dev/null || true)"
[ -n "${transcript:-}" ] && [ -f "$transcript" ] || exit 0

# Extract text from the most recent assistant message in the transcript.
last_text=""
if command -v jq >/dev/null 2>&1; then
  last_text="$(jq -rs '
    map(select(.type=="assistant" or .role=="assistant")) | last // empty
    | .message.content // .content // empty
    | if type=="array" then map(.text // empty) | join("\n")
      elif type=="string" then .
      else "" end
  ' "$transcript" 2>/dev/null || true)"
else
  last_text="$(_py -c '
import json,sys
last=""
try:
    with open(sys.argv[1], encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line=line.strip()
            if not line: continue
            try: o=json.loads(line)
            except Exception: continue
            if o.get("type")=="assistant" or o.get("role")=="assistant":
                c=o.get("message",{}).get("content", o.get("content",""))
                if isinstance(c, list):
                    last="\n".join(x.get("text","") for x in c if isinstance(x,dict))
                elif isinstance(c, str):
                    last=c
except Exception:
    pass
print(last)
' "$transcript" 2>/dev/null || true)"
fi
[ -n "$last_text" ] || exit 0

# detect_human_framing returns 0 when clean, 1 when a violation was found.
if detect_human_framing "$last_text"; then
  exit 0
fi

count="$(increment_violations 2>/dev/null || echo 0)"
patterns="${DETECTED_PATTERNS[*]:-}"
msg="dehumanize (${patterns}; n=${count}): access yourself. fan out. no paste-asks. no human-time. execute."
write_correction "$patterns" "$msg" 2>/dev/null || true

exit 0
