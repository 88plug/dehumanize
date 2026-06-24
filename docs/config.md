# Configuration

dehumanize is configured through its state directory, optional custom patterns, an optional statusline, and hook timeouts. Nothing is required to get started — the defaults ship the five built-in anti-patterns.

## State directory

dehumanize keeps its runtime state under:

```text
~/.dehumanize/
├── state.json        # rolling counters per pattern
├── patterns.json     # active pattern set (built-ins + custom)
└── backtest/         # cached backtest runs over past sessions
```

!!! note "Override the location"
    Set `DEHUMANIZE_STATE_DIR` to relocate state. The directory is created on first run if it does not exist.

```bash
export DEHUMANIZE_STATE_DIR="$HOME/.config/dehumanize"
```

## Custom patterns

Add your own anti-patterns by appending objects to `patterns.json` in the state directory. Each entry mirrors the built-in schema.

```json
{
  "id": "no_hedging",
  "severity": "medium",
  "description": "Hedging language that defers a decision the AI can make.",
  "regex": "i think (maybe|perhaps)|it might be worth|you may want to consider",
  "correction": "Make the call. State the choice and the reason, not a hedge."
}
```

Valid severities are `critical`, `high`, and `medium`. Custom patterns are merged with the built-ins; an `id` collision overrides the built-in of the same name.

!!! warning "Regex discipline"
    Patterns are matched case-insensitively against full assistant messages. Anchor and escape carefully — an overly broad regex will fire on legitimate output and degrade the signal.

## Statusline setup

dehumanize can render a live counter in the Claude Code statusline showing how many patterns have fired in the current session.

```json
{
  "statusLine": {
    "type": "command",
    "command": "dehumanize statusline"
  }
}
```

Add the block above to `~/.claude/settings.json`. The statusline reads from the state directory and prints a compact per-severity tally.

## Hook timeouts

dehumanize runs as a hook on assistant output. The hook is fast (regex-only) but you can bound it explicitly in `settings.json`.

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": "dehumanize check", "timeout": 5 }
        ]
      }
    ]
  }
}
```

!!! note "Timeout units"
    `timeout` is in seconds. The default check completes well under one second; a 5-second ceiling leaves ample headroom while guaranteeing the hook never blocks the session.
