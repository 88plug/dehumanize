#!/usr/bin/env bash
# state.sh - state management library for the dehumanize plugin.
# Sourced by all hook scripts. Functions never exit on error.

get_state_dir() {
  echo "${XDG_RUNTIME_DIR:-/tmp}/dehumanize-${CLAUDE_PROJECT_ID:-default}"
}

init_state() {
  local dir
  dir="$(get_state_dir)"
  mkdir -p "$dir" 2>/dev/null || true
  [ -f "$dir/violations.txt" ] || echo 0 > "$dir/violations.txt" 2>/dev/null || true
  [ -f "$dir/violations.log" ] || : > "$dir/violations.log" 2>/dev/null || true
}

get_violation_count() {
  local dir
  dir="$(get_state_dir)"
  cat "$dir/violations.txt" 2>/dev/null || echo 0
}

increment_violations() {
  local dir file lock count
  dir="$(get_state_dir)"
  file="$dir/violations.txt"
  lock="$dir/violations.lock"
  mkdir -p "$dir" 2>/dev/null || true

  _dehumanize_bump() {
    local c
    c="$(cat "$file" 2>/dev/null || echo 0)"
    case "$c" in
      ''|*[!0-9]*) c=0 ;;
    esac
    c=$((c + 1))
    echo "$c" > "$file" 2>/dev/null || true
    echo "$c"
  }

  # Serialize the read-increment-write so concurrent hooks don't clobber it.
  if command -v flock >/dev/null 2>&1; then
    count="$(
      exec 9>"$lock" 2>/dev/null
      flock 9 2>/dev/null || true
      _dehumanize_bump
    )"
  else
    # Fallback: bounded mkdir-based spinlock.
    local tries=0
    while ! mkdir "$lock.d" 2>/dev/null; do
      tries=$((tries + 1))
      [ "$tries" -ge 50 ] && break
      sleep 0.01 2>/dev/null || true
    done
    count="$(_dehumanize_bump)"
    rmdir "$lock.d" 2>/dev/null || true
  fi

  echo "$count"
}

# write_correction(pattern, message)
# Stores the message for the next hook to surface, and logs the event.
write_correction() {
  local pattern="$1" message="$2" dir ts esc_pattern esc_message
  dir="$(get_state_dir)"
  mkdir -p "$dir" 2>/dev/null || true
  printf '%s' "$message" > "$dir/correction.txt" 2>/dev/null || true

  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  esc_pattern="$(_dehumanize_json_escape "$pattern")"
  esc_message="$(_dehumanize_json_escape "$message")"
  printf '{"ts":"%s","pattern":"%s","message":"%s"}\n' \
    "$ts" "$esc_pattern" "$esc_message" >> "$dir/violations.log" 2>/dev/null || true
}

# get_pending_correction()
# Emits and consumes a stored correction. Returns 0 if one was present.
get_pending_correction() {
  local dir file
  dir="$(get_state_dir)"
  file="$dir/correction.txt"
  if [ -f "$file" ]; then
    cat "$file" 2>/dev/null || true
    rm -f "$file" 2>/dev/null || true
    return 0
  fi
  return 1
}

# find_session_jsonl()
# Locates the active session transcript. Echoes the path if found.
find_session_jsonl() {
  if [ -n "${CLAUDE_TRANSCRIPT_PATH:-}" ] && [ -f "$CLAUDE_TRANSCRIPT_PATH" ]; then
    echo "$CLAUDE_TRANSCRIPT_PATH"
    return 0
  fi
  local proj="${CLAUDE_PROJECT_ID:-}"
  if [ -n "$proj" ]; then
    local latest
    latest="$(ls -t "$HOME/.claude/projects/$proj"/*.jsonl 2>/dev/null | head -1)"
    if [ -n "$latest" ] && [ -f "$latest" ]; then
      echo "$latest"
      return 0
    fi
  fi
  return 1
}

# log_violation(pattern, match, context)
# Appends a timestamped JSON record to violations.log.
log_violation() {
  local pattern="$1" match="$2" context="$3" dir ts
  dir="$(get_state_dir)"
  mkdir -p "$dir" 2>/dev/null || true
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  printf '{"ts":"%s","pattern":"%s","match":"%s","context":"%s"}\n' \
    "$ts" \
    "$(_dehumanize_json_escape "$pattern")" \
    "$(_dehumanize_json_escape "$match")" \
    "$(_dehumanize_json_escape "$context")" \
    >> "$dir/violations.log" 2>/dev/null || true
}

# _dehumanize_json_escape(string)
# Minimal JSON string escaping for log values. Internal helper.
_dehumanize_json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}
