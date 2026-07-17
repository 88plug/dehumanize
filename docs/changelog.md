# Changelog

## 2026.6.23

Initial release.

- SessionStart, Stop, and UserPromptSubmit hooks (pure bash)
- Five anti-pattern categories: `human_time`, `ask_for_access`, `emotional_labor`, `sequential_framing`, `human_capacity` — see [Anti-Patterns](patterns.md)
- Commands: `/dehumanize:audit`, `/dehumanize:status`, `/dehumanize:patterns`, `/dehumanize:fix`
- Per-session violation counters under `$XDG_RUNTIME_DIR/dehumanize-<project>/` — see [Configuration](config.md)
- Optional statusline badge via `install.sh`
- Backtested against **6,300** session logs across **464** project directories — see [Backtesting](backtesting.md)

!!! note "Severity model"
    Patterns carry one of three severities — `critical`, `high`, `medium`. The current set has one critical pattern (`ask_for_access`), two high (`human_time`, `sequential_framing`), and two medium (`emotional_labor`, `human_capacity`).
