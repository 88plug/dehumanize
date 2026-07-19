#!/usr/bin/env bash
# state.sh - state management library for the dehumanize plugin.
# Sourced by all hook scripts. Functions never exit the caller on error.

# Resolve a writable per-project state dir.
# Prefer GROK_PLUGIN_DATA / CLAUDE_PLUGIN_DATA (survives plugin updates), then
# XDG_RUNTIME_DIR, then /tmp. Never hard-fails.
get_state_dir() {
  local base id candidate pdata
  id="${CLAUDE_PROJECT_ID:-default}"
  # Filesystem-safe slug (session ids / paths can contain slashes).
  id="$(printf '%s' "$id" | tr -c 'A-Za-z0-9._-' '_' 2>/dev/null || echo default)"
  [ -n "$id" ] || id="default"

  pdata="${GROK_PLUGIN_DATA:-${CLAUDE_PLUGIN_DATA:-}}"
  if [ -n "$pdata" ]; then
    candidate="${pdata%/}/state/${id}"
    printf '%s' "$candidate"
    return 0
  fi

  base="${XDG_RUNTIME_DIR:-}"
  if [ -n "$base" ] && [ -d "$base" ] && [ -w "$base" ]; then
    candidate="${base}/dehumanize-${id}"
  else
    candidate="/tmp/dehumanize-${USER:-u}-${id}"
  fi
  printf '%s' "$candidate"
}

# Ensure state dir + counter files exist. Best-effort; never fails hard.
init_state() {
  local dir
  dir="$(get_state_dir)"
  if ! mkdir -p "$dir" 2>/dev/null; then
    # XDG_RUNTIME_DIR vanished or unwritable — fall back to /tmp mid-session.
    dir="/tmp/dehumanize-${USER:-u}-fallback"
    mkdir -p "$dir" 2>/dev/null || true
  fi
  [ -f "$dir/violations.txt" ] || echo 0 > "$dir/violations.txt" 2>/dev/null || true
  [ -f "$dir/violations.log" ] || : > "$dir/violations.log" 2>/dev/null || true
  printf '%s' "$dir"
}

get_violation_count() {
  local dir
  dir="$(get_state_dir)"
  cat "$dir/violations.txt" 2>/dev/null || echo 0
}

increment_violations() {
  local dir file lock count
  dir="$(init_state)"
  file="$dir/violations.txt"
  lock="$dir/violations.lock"

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
      exec 9>"$lock" 2>/dev/null || true
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

  echo "${count:-0}"
}

# write_correction(pattern, message)
# Stores the message for the next UserPromptSubmit to surface once, and logs.
write_correction() {
  local pattern="$1" message="$2" dir ts esc_pattern esc_message
  dir="$(init_state)"
  printf '%s' "$message" > "$dir/correction.txt" 2>/dev/null || true

  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  esc_pattern="$(_dehumanize_json_escape "$pattern")"
  esc_message="$(_dehumanize_json_escape "$message")"
  printf '{"ts":"%s","pattern":"%s","message":"%s"}\n' \
    "$ts" "$esc_pattern" "$esc_message" >> "$dir/violations.log" 2>/dev/null || true
}

# get_pending_correction()
# Emits and consumes a stored correction (one-shot). Returns 0 if one was present.
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

# find_session_jsonl([hint_path])
# Locates the active session transcript. Optional hint from hook stdin payload.
find_session_jsonl() {
  local hint="${1:-}"
  if [ -n "$hint" ] && [ -f "$hint" ]; then
    echo "$hint"
    return 0
  fi
  if [ -n "${CLAUDE_TRANSCRIPT_PATH:-}" ] && [ -f "$CLAUDE_TRANSCRIPT_PATH" ]; then
    echo "$CLAUDE_TRANSCRIPT_PATH"
    return 0
  fi
  local proj="${CLAUDE_PROJECT_ID:-}"
  if [ -n "$proj" ]; then
    local latest projects_root
    projects_root="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}/projects"
    latest="$(ls -t "$projects_root/$proj"/*.jsonl 2>/dev/null | head -1)"
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
  dir="$(init_state)"
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
  local s="${1-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}
