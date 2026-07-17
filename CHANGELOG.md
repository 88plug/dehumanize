# Changelog

## 2026.7.17

- Skill compliance wave: `skills/dehumanize/SKILL.md` description tightened for
  auto-invoke (EOD/COB, drop/attach, "great question" / "hope this helps",
  "one step at a time", "non-trivial effort"); rewrite table kept in lockstep
  with the five detector categories.
- Stronger anti-pattern coverage: `detect-human-framing.sh` sources
  `hooks/lib/patterns.sh` as the single regex source of truth; expanded
  triggers for all five patterns plus FP reduction on technical "complex".
- Manifest / install: rolling calver (no static `version`); 20 keywords;
  `marketplace-entry.json` source shape `url` → `https://github.com/88plug/dehumanize.git`;
  README install uses `dehumanize@88plug`.
- Launch: `scripts/run-python.sh` (T1) for audit tooling — version-gated ≥3.10,
  `EIGHTYEIGHT_PYTHON` / `PLUGIN_PYTHON` / `DEHUMANIZE_PYTHON` overrides.
- CI: Dependabot (github-actions weekly); fleet action pins
  (`checkout@v7.0.0`, `setup-python@v6.3.0`, Python 3.13, runner fallback).

## 2026.6.23

- Initial release: SessionStart, Stop, and UserPromptSubmit hooks
- 5 anti-pattern categories: human_time, ask_for_access, emotional_labor, sequential_framing, human_capacity
- Commands: /dehumanize:audit, :status, :patterns, :fix
- Backtested against 6,300 session logs across 464 project directories
