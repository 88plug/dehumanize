# Configuration

dehumanize works out of the box. The five built-in anti-patterns load with the plugin. Optional knobs: state location, statusline badge, and hook timeouts.

## State directory

Runtime state is per project and per session under the XDG runtime dir:

```text
$XDG_RUNTIME_DIR/dehumanize-<project-id>/
├── violations.txt    # running violation count
├── violations.log    # per-hit JSON lines (ts, pattern, match, context)
└── correction.txt    # pending next-turn correction (consumed on inject)
```

If `XDG_RUNTIME_DIR` is unset, state falls back to `/tmp/dehumanize-<project-id>/`.
`<project-id>` comes from `CLAUDE_PROJECT_ID` (default: `default`).

!!! note "Ephemeral by design"
    State is under the runtime dir so it clears on reboot. It is not meant as
    long-term analytics storage. Use `/dehumanize:audit` against session JSONL
    for historical scans.

## Statusline setup

Install the live violation badge into Claude Code's statusline:

```bash
bash "$(claude plugin path dehumanize)/install.sh"
```

That writes a `statusLine` command into `~/.claude/settings.json` pointing at
`scripts/statusline.sh`. The badge prints:

- `[DEHUMANIZE: OK]` when the session count is zero
- `[DEHUMANIZE: N!]` when N violations have been recorded

Reload Claude Code after install. To wire it by hand:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash \"/path/to/dehumanize/scripts/statusline.sh\""
  }
}
```

## Hook timeouts

Hooks are pure bash regex scans. Defaults ship in the plugin manifest:

| Hook | Script | Default timeout |
| --- | --- | --- |
| SessionStart | `hooks/session-init.sh` | 15s |
| Stop | `hooks/capture-stop.sh` | 20s |
| UserPromptSubmit | `hooks/inject-correction.sh` | 10s |

!!! note "Timeout units"
    Timeouts are in seconds. Checks complete well under one second in normal
    sessions; the ceilings leave headroom without blocking the session.

## Commands reference

| Command | What it does |
| --- | --- |
| `/dehumanize:status` | Session violation count + most recent matches. |
| `/dehumanize:patterns` | Full pattern table (severity, regex, examples). |
| `/dehumanize:audit` | Scan the current session transcript for all hits. |
| `/dehumanize:fix` | Rewrite the last assistant turn without human framing. |
