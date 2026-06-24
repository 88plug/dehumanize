#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS="${HOME}/.claude/settings.json"

mkdir -p "$(dirname "$SETTINGS")"
if [[ ! -f "$SETTINGS" ]]; then
  printf '{}' > "$SETTINGS"
fi

PLUGIN_ROOT="$PLUGIN_ROOT" SETTINGS="$SETTINGS" python3 <<'PY'
import json
import os

settings_path = os.environ["SETTINGS"]
plugin_root = os.environ["PLUGIN_ROOT"]

with open(settings_path) as f:
    settings = json.load(f)

status_line = settings.get("statusLine")
if not isinstance(status_line, dict):
    status_line = {}
status_line["type"] = "command"
status_line["command"] = 'bash "%s/scripts/statusline.sh"' % plugin_root
settings["statusLine"] = status_line

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PY

echo "Dehumanize statusline installed. Reload Claude Code to activate."
