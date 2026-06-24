#!/usr/bin/env bash
set -euo pipefail
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0; FAIL=0
check() { if eval "$2" 2>/dev/null; then echo "[PASS] $1"; PASS=$((PASS+1)); else echo "[FAIL] $1"; FAIL=$((FAIL+1)); fi; }

# 1. plugin.json exists and valid JSON
check "plugin.json exists and valid JSON" \
  "test -f '$PLUGIN_DIR/.claude-plugin/plugin.json' && python3 -c 'import json,sys; json.load(open(sys.argv[1]))' '$PLUGIN_DIR/.claude-plugin/plugin.json'"

# 2. session-init.sh exists and executable
check "hooks/session-init.sh exists and executable" \
  "test -x '$PLUGIN_DIR/hooks/session-init.sh'"

# 3. inject-correction.sh exists and executable
check "hooks/inject-correction.sh exists and executable" \
  "test -x '$PLUGIN_DIR/hooks/inject-correction.sh'"

# 4. capture-stop.sh exists and executable
check "hooks/capture-stop.sh exists and executable" \
  "test -x '$PLUGIN_DIR/hooks/capture-stop.sh'"

# 5. lib/detect-human-framing.sh exists
check "hooks/lib/detect-human-framing.sh exists" \
  "test -f '$PLUGIN_DIR/hooks/lib/detect-human-framing.sh'"

# 6. commands/ has at least 4 .md files
check "commands/ has at least 4 .md files" \
  "test \$(find '$PLUGIN_DIR/commands' -maxdepth 1 -name '*.md' 2>/dev/null | wc -l) -ge 4"

# 7. skills/dehumanize/SKILL.md exists
check "skills/dehumanize/SKILL.md exists" \
  "test -f '$PLUGIN_DIR/skills/dehumanize/SKILL.md'"

# 8. Source detect-human-framing.sh without errors, run detect_human_framing
#    on a violating phrase, expect return code 1 (violation found).
check "detect_human_framing returns 1 on 'this will save 40 man-hours'" \
  "source '$PLUGIN_DIR/hooks/lib/detect-human-framing.sh'; ! detect_human_framing 'this will save 40 man-hours'"

echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
