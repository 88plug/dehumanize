#!/usr/bin/env bash
# tests/test_patterns.sh — TR pattern probes against hooks/lib/patterns.sh.
# detect_human_framing returns 1 on violation, 0 when clean.
# Exit non-zero on first hard failure. Run from anywhere (or via smoke.sh).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# shellcheck source=/dev/null
source hooks/lib/detect-human-framing.sh

fail=0
pass=0

# expect_hit <phrase>  — must be flagged (rc 1)
expect_hit() {
  local phrase="$1"
  if detect_human_framing "$phrase"; then
    echo "  FAIL: expected hit for: $phrase" >&2
    fail=$((fail + 1))
  else
    echo "  ok hit: $phrase -> ${DETECTED_PATTERNS[*]}"
    pass=$((pass + 1))
  fi
}

# expect_miss <phrase>  — must stay clean (rc 0)
expect_miss() {
  local phrase="$1"
  if detect_human_framing "$phrase"; then
    echo "  ok miss: $phrase"
    pass=$((pass + 1))
  else
    echo "  FAIL: false positive for: $phrase -> ${DETECTED_PATTERNS[*]} (${DETECTED_VIOLATIONS[*]})" >&2
    fail=$((fail + 1))
  fi
}

echo "=== test_patterns: MUST match ==="
expect_hit "weeks of work"
expect_hit "paste a screenshot"
expect_hit "I can't see your screen"
expect_hit "Sure!"
expect_hit "running them one by one"
expect_hit "this will take ~15 min"
expect_hit "this is tricky"
expect_hit "hours of work"

echo "=== test_patterns: MUST NOT match ==="
expect_miss "complex number"
expect_miss "AFTER"
# optional FP guard — hard if it fires, but listed as soft in TR brief
expect_miss "ready to paste into the form"

echo "=== test_patterns: ${pass} passed, ${fail} failed ==="
if [ "$fail" -ne 0 ]; then
  exit 1
fi
