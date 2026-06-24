# Changelog

## Current release

The current release ships the core dehumanize detector with five built-in anti-patterns, a stateful per-session counter, an optional statusline, and a backtesting harness that replays past Claude Code sessions to estimate how often each pattern would have fired.

**Highlights**

- Five built-in anti-patterns: `human_time`, `ask_for_access`, `emotional_labor`, `sequential_framing`, `human_capacity` — see [Anti-Patterns](patterns.md).
- Per-severity session counters persisted to the [state directory](config.md#state-directory).
- Custom pattern support via `patterns.json` with the same schema as built-ins.
- Optional [statusline](config.md#statusline-setup) integration showing live pattern tallies.
- [Backtesting](backtesting.md) over historical sessions to quantify impact before enabling enforcement.

!!! note "Severity model"
    Patterns carry one of three severities — `critical`, `high`, `medium`. The current set has one critical pattern (`ask_for_access`), two high (`human_time`, `sequential_framing`), and two medium (`emotional_labor`, `human_capacity`).
