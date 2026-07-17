#!/usr/bin/env bash
# tests/smoke.sh — fleet smoke bar + dehumanize wiring. Zero third-party deps.
# Exit non-zero on first hard failure. Run from anywhere.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Prefer fleet T1 resolver when present (thin Claude PATH / Homebrew-safe)
if [ -f scripts/run-python.sh ]; then
  PY=(bash scripts/run-python.sh)
else
  PY=("${PYTHON:-python3}")
fi

echo "=== smoke: .claude-plugin/plugin.json exists, no root plugin.json ==="
test -f .claude-plugin/plugin.json
if [ -f plugin.json ]; then
  echo "  FAIL: root plugin.json must not exist (single-manifest layout)" >&2
  exit 1
fi
echo "  ok: single manifest at .claude-plugin/plugin.json"

echo "=== smoke: keywords=20, no version ==="
"${PY[@]}" - <<'PY'
import json
from pathlib import Path
m = json.loads(Path(".claude-plugin/plugin.json").read_text())
assert "version" not in m, "version field must be absent (rolling regime)"
kws = m.get("keywords") or []
assert len(kws) == 20, f"expected 20 keywords, got {len(kws)}"
assert m.get("name"), "plugin.json missing name"
print(f"  ok: name={m['name']} keywords={len(kws)}")
PY

echo "=== smoke: no bare command python3/python/uv/uvx/npx in manifests ==="
for f in .claude-plugin/plugin.json hooks/hooks.json .mcp.json; do
  [ -f "$f" ] || continue
  if grep -qE '"command"[[:space:]]*:[[:space:]]*"(python3?|uvx?|npx)"' "$f"; then
    echo "  FAIL: bare interpreter command in $f" >&2
    exit 1
  fi
  echo "  ok: $f"
done

echo "=== smoke: hooks + scripts bash -n ==="
while read -r f; do
  [ -n "$f" ] || continue
  bash -n "$f" && echo "  ok: $f"
done < <(find hooks scripts -name "*.sh" 2>/dev/null | sort)

echo "=== smoke: run-python.sh thin PATH (if present) ==="
if [ -f scripts/run-python.sh ]; then
  bash -n scripts/run-python.sh
  bash scripts/run-python.sh -c 'import sys; assert sys.version_info >= (3, 10)'
  # Simulate Claude GUI spawn (minimal PATH)
  out="$(env -i HOME="$HOME" PATH="/usr/bin:/bin" bash scripts/run-python.sh -c 'import sys; print(sys.version_info[0])')"
  echo "$out" | grep -q '^3$'
  echo "  ok: run-python resolves Python 3 on thin PATH"
else
  echo "  skip: scripts/run-python.sh not present"
fi

echo "=== smoke: hub install string in README ==="
grep -qE '88plug/claude-code-plugins' README.md
grep -qE 'dehumanize@88plug|/plugin install dehumanize' README.md
echo "  ok: hub marketplace + dehumanize@88plug install"

echo "=== smoke: marketplace-entry url source ==="
"${PY[@]}" - <<'PY'
import json
from pathlib import Path
me = json.loads(Path("marketplace-entry.json").read_text())
src = me.get("source") or {}
assert isinstance(src, dict), "marketplace-entry source must be object"
assert src.get("source") == "url", f"expected source=url, got {src.get('source')!r}"
url = src.get("url") or ""
assert url.startswith("https://github.com/88plug/"), f"unexpected url: {url}"
print(f"  ok: source=url url={url}")
PY

echo "=== smoke: validate_plugin.py (if present) ==="
if [ -f .ci/validate_plugin.py ]; then
  "${PY[@]}" .ci/validate_plugin.py .
  echo "  ok: validate_plugin.py"
else
  echo "  skip: .ci/validate_plugin.py not present"
fi

echo "=== smoke: hook executables + skill surface ==="
test -x hooks/session-init.sh
test -x hooks/inject-correction.sh
test -x hooks/capture-stop.sh
test -f hooks/lib/detect-human-framing.sh
test -f skills/dehumanize/SKILL.md
test "$(find commands -maxdepth 1 -name '*.md' 2>/dev/null | wc -l)" -ge 4
echo "  ok: hooks executable + skill + commands"

echo "=== smoke: detect_human_framing returns 1 on violation ==="
# shellcheck source=/dev/null
source hooks/lib/detect-human-framing.sh
if detect_human_framing 'this will save 40 man-hours'; then
  echo "  FAIL: expected violation (rc 1) for man-hours phrase" >&2
  exit 1
fi
echo "  ok: detector flags human-time phrase"

echo "=== smoke: TR pattern probes (tests/test_patterns.sh) ==="
bash tests/test_patterns.sh
echo "  ok: TR pattern probes"

echo "=== smoke: all good ==="
