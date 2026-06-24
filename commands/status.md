---
description: Show current session violation stats from state dir.
---

# /dehumanize:status

Show the running violation stats for the current session from the plugin state directory.

## Procedure

1. Resolve the state directory from the `STATE_DIR` environment variable (the plugin sets this; fall back to the plugin's default state path if unset).
2. Read `$STATE_DIR/violations.txt` — this holds the running total violation count.
3. Read `$STATE_DIR/violations.log` — this holds per-violation detail lines (timestamp, pattern, matched example).

## Display

- **Total violations** — the count from `violations.txt`.
- **Last pattern caught** — the pattern id from the final line of `violations.log`.
- **Last example** — the matched text/context from the final line of `violations.log`.

If either file is missing or empty, report a clean session (0 violations).
