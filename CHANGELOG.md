# Changelog

## 2026.7.17

- **TR-backed detect wave** (session-history + total-recall probes): expand all
  five patterns in `hooks/lib/patterns.sh`; keep FP budget (no bare step-N,
  technical "complex number", docs-only, irreversible confirm).
  - `ask_for_access` (critical): screenshot/visual yield — *paste/send a
    screenshot*, *I can't see* / *I cannot see*, *tell me what you see*,
    *feel free to paste*, *I need you to paste*; correction names screen capture.
  - `human_capacity` (medium): *tricky*, *may take*, *this will take ~N min*,
    *takes/taking a (bit|while|moment)*, *complex multi-step*.
  - `emotional_labor` (medium): short openers `\b(sure|certainly|of course)!`
    (Sure! / Certainly! / Of course!).
  - `human_time` (high): man-weeks/months, *hours of work/effort*,
    *(afternoon|morning|evening)'s work*.
  - `sequential_framing` (high): *running them one by one* / *one by one*.
  - **Audit sync:** `scripts/audit.py` `PATTERNS` lockstep with `patterns.sh`
    (same names, regexes, severities, corrections).
  - Docs: `docs/patterns.md` regexes + quick-ref vocabulary match runtime.
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
- Hooks: terse SessionStart/Stop directives
  (`access yourself. fan out. no paste-asks. no human-time. execute.`).

## 2026.6.23

- Initial release: SessionStart, Stop, and UserPromptSubmit hooks
- 5 anti-pattern categories: human_time, ask_for_access, emotional_labor, sequential_framing, human_capacity
- Commands: /dehumanize:audit, :status, :patterns, :fix
- Backtested against 6,300 session logs across 464 project directories
