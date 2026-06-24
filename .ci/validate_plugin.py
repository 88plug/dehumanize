#!/usr/bin/env python3
"""CI validator for the dehumanize Claude Code plugin.

Asserts manifest hygiene and required wiring. Exits non-zero on any failure
and prints a PASS/FAIL line per check.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / ".claude-plugin" / "plugin.json"

failures = []


def check(name, ok, detail=""):
    status = "PASS" if ok else "FAIL"
    line = f"[{status}] {name}"
    if detail:
        line += f" -- {detail}"
    print(line)
    if not ok:
        failures.append(name)


# Load manifest once (check 1 also covers validity).
manifest = None
try:
    manifest = json.loads(MANIFEST.read_text())
    manifest_ok = True
    manifest_detail = ""
except FileNotFoundError:
    manifest_ok = False
    manifest_detail = f"missing {MANIFEST}"
except json.JSONDecodeError as e:
    manifest_ok = False
    manifest_detail = f"invalid JSON: {e}"

# 1. plugin.json valid JSON
check("plugin.json valid JSON", manifest_ok, manifest_detail)

if manifest is None:
    # Nothing else is checkable without a manifest.
    print(f"\nResult: {len(failures)} check(s) failed")
    sys.exit(1)

# 2. keywords count == 20
kw = manifest.get("keywords", [])
check("keywords count == 20", len(kw) == 20, f"found {len(kw)}")

# 3. no version field
check("no version field", "version" not in manifest,
      "version field present" if "version" in manifest else "")

# 4. license == FSL-1.1-ALv2
lic = manifest.get("license")
check("license == FSL-1.1-ALv2", lic == "FSL-1.1-ALv2", f"found {lic!r}")

# 5. hook commands contain ${CLAUDE_PLUGIN_ROOT}
hook_cmds = []
for _event, groups in manifest.get("hooks", {}).items():
    for group in groups:
        for hook in group.get("hooks", []):
            cmd = hook.get("command", "")
            if cmd:
                hook_cmds.append(cmd)
all_rooted = bool(hook_cmds) and all(
    "${CLAUDE_PLUGIN_ROOT}" in c for c in hook_cmds
)
bad = [c for c in hook_cmds if "${CLAUDE_PLUGIN_ROOT}" not in c]
check("hook commands contain ${CLAUDE_PLUGIN_ROOT}", all_rooted,
      "no hook commands found" if not hook_cmds else
      (f"missing in: {bad}" if bad else ""))

# 6. no root plugin.json (manifest must live under .claude-plugin/)
root_manifest = ROOT / "plugin.json"
check("no root plugin.json", not root_manifest.exists(),
      f"{root_manifest} exists" if root_manifest.exists() else "")

# 7. commands/ has .md files
cmd_files = list((ROOT / "commands").glob("*.md")) if (ROOT / "commands").is_dir() else []
check("commands/ has .md files", len(cmd_files) > 0, f"found {len(cmd_files)}")

# 8. skills/ has SKILL.md
skill_files = list((ROOT / "skills").rglob("SKILL.md")) if (ROOT / "skills").is_dir() else []
check("skills/ has SKILL.md", len(skill_files) > 0, f"found {len(skill_files)}")

print(f"\nResult: {len(failures)} check(s) failed")
sys.exit(1 if failures else 0)
