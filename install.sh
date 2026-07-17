#!/usr/bin/env bash
# install.sh — optional statusLine wire-up for dehumanize.
#
# Hub-first install (preferred):
#   /plugin marketplace add 88plug/claude-code-plugins
#   /plugin install dehumanize
# Hooks, commands, and skills load from the plugin manifest automatically.
# This script only merges the optional statusline badge into settings.json.
#
# Safe to re-run:
#   * If a *different* statusLine already exists, it is preserved (not overwritten).
#   * If our statusLine is already installed, it is a no-op update of the path.
#   * If no statusLine is set, installs ours.
#
# Usage:  ./install.sh
set -u

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
SETTINGS="${CONFIG_DIR}/settings.json"
# Expand CLAUDE_PLUGIN_ROOT at statusline runtime (no machine-local paths baked in).
# Fallback: resolved plugin root for standalone clones where the env var is unset.
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  STATUS_CMD='bash "${CLAUDE_PLUGIN_ROOT}/scripts/statusline.sh"'
else
  STATUS_CMD="bash \"\${CLAUDE_PLUGIN_ROOT:-${PLUGIN_ROOT}}/scripts/statusline.sh\""
fi

mkdir -p "${CONFIG_DIR}" 2>/dev/null || true
if [ ! -f "${SETTINGS}" ]; then
  printf '{}\n' > "${SETTINGS}"
fi

# Prefer plugin run-python resolver (thin PATH / no python3 symlink).
if [ -x "${PLUGIN_ROOT}/scripts/run-python.sh" ]; then
  PY=("${PLUGIN_ROOT}/scripts/run-python.sh")
else
  PY=()
  for p in python3 python3.14 python3.13 python3.12 python3.11 python \
           /usr/bin/python3 /usr/bin/python3.14 /usr/bin/python3.12 \
           /usr/bin/python3.11 /usr/bin/python /usr/local/bin/python3; do
    if command -v "$p" >/dev/null 2>&1 || [ -x "$p" ]; then
      PY=("$p")
      break
    fi
  done
fi
if [ "${#PY[@]}" -eq 0 ]; then
  echo "install.sh: Python >=3.10 is required to edit settings.json safely." >&2
  exit 1
fi

PLUGIN_ROOT="$PLUGIN_ROOT" SETTINGS="$SETTINGS" STATUS_CMD="$STATUS_CMD" "${PY[@]}" <<'PY'
import json
import os
import shutil

settings_path = os.environ["SETTINGS"]
our_cmd = os.environ["STATUS_CMD"]

try:
    with open(settings_path, encoding="utf-8") as fh:
        settings = json.load(fh)
    if not isinstance(settings, dict):
        settings = {}
except (OSError, json.JSONDecodeError):
    settings = {}

current = settings.get("statusLine")
current_cmd = ""
if isinstance(current, dict):
    current_cmd = str(current.get("command") or "")

def is_ours(cmd: str) -> bool:
    return "dehumanize" in cmd and "statusline.sh" in cmd

if current_cmd and not is_ours(current_cmd):
    # Preserve an existing third-party statusLine; do not clobber.
    print("dehumanize: preserving existing statusLine:")
    print("  " + current_cmd[:120])
    print("  (left unchanged; hooks still work without the badge)")
    print("  To use the dehumanize badge, set statusLine.command to:")
    print("  " + our_cmd)
elif is_ours(current_cmd):
    # Already ours — refresh path in case the plugin moved.
    if current_cmd != our_cmd:
        bak = settings_path + ".dehumanize.bak"
        try:
            shutil.copyfile(settings_path, bak)
        except OSError:
            pass
        settings["statusLine"] = {"type": "command", "command": our_cmd, "padding": 0}
        tmp = settings_path + ".dehumanize.tmp"
        with open(tmp, "w", encoding="utf-8") as fh:
            json.dump(settings, fh, indent=2)
            fh.write("\n")
        os.replace(tmp, settings_path)
        print("dehumanize: statusLine path refreshed.")
    else:
        print("dehumanize: statusLine already installed (no change).")
else:
    bak = settings_path + ".dehumanize.bak"
    try:
        shutil.copyfile(settings_path, bak)
    except OSError:
        pass
    settings["statusLine"] = {"type": "command", "command": our_cmd, "padding": 0}
    tmp = settings_path + ".dehumanize.tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(settings, fh, indent=2)
        fh.write("\n")
    os.replace(tmp, settings_path)
    print("dehumanize: statusLine installed. Reload Claude Code to activate.")
    print("  backup: " + bak)
PY
