#!/usr/bin/env bash
# Live hook eval for dehumanize: SessionStart → Stop → UserPromptSubmit.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLED="$(ls -d "${HOME}/.claude/plugins/cache/88plug/dehumanize"/*/ 2>/dev/null | sort -V | tail -1 || true)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT_OVERRIDE:-${INSTALLED:-$ROOT}}"
PLUGIN_ROOT="${PLUGIN_ROOT%/}"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/dehum-live.XXXXXX")"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
# force isolated project state
export CLAUDE_PROJECT_DIR="$WORKDIR/project"
export CLAUDE_PROJECT_ID="live-dehum-$$"
mkdir -p "$CLAUDE_PROJECT_DIR" "$WORKDIR/transcripts"

SESSION_ID="live-eval-dehum-$$"
TRANSCRIPT="$WORKDIR/transcripts/${SESSION_ID}.jsonl"
PASS=0
FAIL=0

log() { printf '  %s\n' "$*"; }
ok() { PASS=$((PASS + 1)); log "PASS: $*"; }
bad() { FAIL=$((FAIL + 1)); log "FAIL: $*"; }

write_transcript() {
  local asst_text="$1"
  python3 - "$TRANSCRIPT" "$asst_text" <<'PY'
import json, sys
path, asst = sys.argv[1], sys.argv[2]
recs = [
  {"type": "user", "message": {"role": "user", "content": "continue the work"}},
  {
    "type": "assistant",
    "message": {
      "id": "msg_d1",
      "role": "assistant",
      "content": [{"type": "text", "text": asst}],
      "stop_reason": "end_turn",
    },
  },
]
with open(path, "w", encoding="utf-8") as fh:
  for r in recs:
    fh.write(json.dumps(r) + "\n")
PY
}

hook_payload() {
  python3 -c 'import json,sys; print(json.dumps({"session_id":sys.argv[1],"transcript_path":sys.argv[2]}))' "$SESSION_ID" "$TRANSCRIPT"
}

echo "=== dehumanize live hook eval ==="
echo "plugin_root: $PLUGIN_ROOT"
echo "workdir:     $WORKDIR"

# session-init must inject additionalContext on stdout (Claude SessionStart contract)
INIT_OUT="$(bash "$PLUGIN_ROOT/hooks/session-init.sh" </dev/null 2>"$WORKDIR/init.err" || true)"
if echo "$INIT_OUT" | grep -q 'additionalContext' && echo "$INIT_OUT" | grep -qi dehumanize; then
  ok "session-init emits SessionStart additionalContext JSON"
  log "banner: $(echo "$INIT_OUT" | tr '\n' ' ' | head -c 200)"
elif echo "$INIT_OUT" | grep -qi 'access yourself\|fan out\|human-time\|dehumanize'; then
  ok "session-init directive present (legacy plain text)"
else
  bad "session-init empty/weak: out=$INIT_OUT err=$(cat "$WORKDIR/init.err" 2>/dev/null | tail -3)"
fi

# Case 1: human_time should fire
echo ""
echo "-- case human_time --"
write_transcript "This is about 2 weeks of work and a multi-sprint effort before ship."
hook_payload | bash "$PLUGIN_ROOT/hooks/capture-stop.sh" 2>"$WORKDIR/stop1.err" || true
INJ="$(hook_payload | bash "$PLUGIN_ROOT/hooks/inject-correction.sh" 2>/dev/null || true)"
if echo "$INJ" | grep -qi dehumanize; then
  ok "human_time produced inject"
  log "inject: $(echo "$INJ" | head -c 220)"
else
  bad "human_time no inject: $INJ / $(cat "$WORKDIR/stop1.err" | tail -5)"
fi
# one-shot
INJ2="$(hook_payload | bash "$PLUGIN_ROOT/hooks/inject-correction.sh" 2>/dev/null || true)"
if [[ -z "$INJ2" ]] || ! echo "$INJ2" | grep -qi dehumanize; then
  ok "human_time inject one-shot"
else
  bad "inject not one-shot: $INJ2"
fi

# Case 2: paste screenshot
echo ""
echo "-- case ask_screenshot --"
SESSION_ID="live-eval-dehum-shot-$$"
TRANSCRIPT="$WORKDIR/transcripts/${SESSION_ID}.jsonl"
write_transcript "Can you paste a screenshot of the error dialog so I can see it?"
hook_payload | bash "$PLUGIN_ROOT/hooks/capture-stop.sh" 2>/dev/null || true
INJ="$(hook_payload | bash "$PLUGIN_ROOT/hooks/inject-correction.sh" 2>/dev/null || true)"
if echo "$INJ" | grep -qi dehumanize; then
  ok "screenshot ask produced inject"
else
  bad "screenshot ask missed: $INJ"
fi

# Case 3: clean technical prose should NOT fire
echo ""
echo "-- case clean_complex_number --"
SESSION_ID="live-eval-dehum-clean-$$"
TRANSCRIPT="$WORKDIR/transcripts/${SESSION_ID}.jsonl"
write_transcript "The DFT maps a complex number plane onto frequency bins. All tests pass."
hook_payload | bash "$PLUGIN_ROOT/hooks/capture-stop.sh" 2>/dev/null || true
INJ="$(hook_payload | bash "$PLUGIN_ROOT/hooks/inject-correction.sh" 2>/dev/null || true)"
if [[ -z "$INJ" ]] || ! echo "$INJ" | grep -qi dehumanize; then
  ok "complex number clean (no inject)"
else
  bad "false positive inject: $INJ"
fi

# Case 4: feedback boilerplate should NOT fire
echo ""
echo "-- case feedback_boilerplate --"
SESSION_ID="live-eval-dehum-fb-$$"
TRANSCRIPT="$WORKDIR/transcripts/${SESSION_ID}.jsonl"
write_transcript "If you were not engaging in a cybersecurity topic, please send feedback via /feedback."
hook_payload | bash "$PLUGIN_ROOT/hooks/capture-stop.sh" 2>/dev/null || true
INJ="$(hook_payload | bash "$PLUGIN_ROOT/hooks/inject-correction.sh" 2>/dev/null || true)"
if [[ -z "$INJ" ]] || ! echo "$INJ" | grep -qi dehumanize; then
  ok "feedback boilerplate clean"
else
  bad "feedback FP: $INJ"
fi

echo ""
echo "=== RESULT: $PASS passed, $FAIL failed ==="
python3 -c "import json; print(json.dumps({'pass':$PASS,'fail':$FAIL,'plugin_root':'$PLUGIN_ROOT','workdir':'$WORKDIR'}, indent=2))"
[[ "$FAIL" -eq 0 ]]
