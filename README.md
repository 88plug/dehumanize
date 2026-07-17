<div align="center">

# dehumanize

Makes Claude Code work like AI — not like a human in a mech suit.

[![plugin-validate](https://github.com/88plug/dehumanize/actions/workflows/plugin-validate.yml/badge.svg)](https://github.com/88plug/dehumanize/actions/workflows/plugin-validate.yml)
[![License: FSL-1.1-ALv2](https://img.shields.io/badge/license-FSL--1.1--ALv2-blue?style=flat)](LICENSE)
[![Docs](https://img.shields.io/badge/docs-online-blue?style=flat)](https://88plug.github.io/dehumanize)
[![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-8A2BE2?style=flat)](https://github.com/88plug/claude-code-plugins)
[![DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/88plug/dehumanize)

</div>

Detects and corrects AI responses that quote human time, ask for directly-accessible data, or use emotional labor language.

## Install

```bash
/plugin marketplace add 88plug/claude-code-plugins
/plugin install dehumanize@88plug
```

## What it blocks

| Anti-pattern | Looks like | Why it's wrong |
| --- | --- | --- |
| Human time | "this is a 2-week sprint", "~40 man-hours" | An agent doesn't bill hours or run sprints — it executes now. |
| Asking for accessible data | "paste the file contents", "send me the log output" | The agent can `read`/`run`/`grep` it directly. Asking wastes turns. |
| Emotional labor | "I'm so sorry", "I'd be happy to", "great question!" | Filler that mimics human social scripts and adds no signal. |
| Serial narration | "first I'll X, then I'll Y, then finally Z" | Independent work should fan out in parallel, not queue up. |
| Effort theater | "this is complex and will take some time" | Hedging about difficulty instead of just doing the work. |

## Why

Claude is trained on human-written text, so by default it imitates human *behavior*, not just human *language*. A human engineer asks a teammate to paste a file because they can't reach it. A human estimates a feature in weeks because they work eight hours a day. A human softens bad news with an apology because the listener has feelings.

None of that applies to an AI agent. It has direct filesystem and shell access, no working day, and no counterpart who needs emotional cushioning. When the model reaches for these scripts anyway, it's a human in a mech suit — wearing the shape of the tool but moving like the operator.

`dehumanize` catches those reflexes and strips them, so the agent behaves like what it is.

## How it works

Three hooks, pure bash, no dependencies:

1. **SessionStart** — `hooks/session-init.sh` resets per-session violation state and prints a one-screen reminder of the operating rules (read directly, parallelize, no human-time language).
2. **Stop** — scans the completed response for the five anti-patterns and records any matches to the session's violation log.
3. **UserPromptSubmit** — when prior violations exist, injects a terse correction into context so the next turn self-corrects instead of repeating the reflex.

State lives under `$XDG_RUNTIME_DIR/dehumanize-<project>/` and is scoped per project and per session.

## Anti-pattern reference

| # | Pattern | Trigger vocabulary (non-exhaustive) | Correction |
| --- | --- | --- | --- |
| 1 | `human_time` | sprint, man-hours, FTE, weeks of work, "by end of day" | Drop time-as-labor framing; state what's done, not how long a human would take. |
| 2 | `ask_accessible_data` | "paste the…", "send me the output", "share the contents of…" | Read / run / grep it directly instead of asking. |
| 3 | `emotional_labor` | "I'm sorry", "I'd be happy to", "great question", "unfortunately" | Remove apologies, eagerness, and praise filler. |
| 4 | `serial_narration` | "first I'll…, then I'll…, finally I'll…" | Fan out independent steps in parallel; don't narrate a queue. |
| 5 | `effort_theater` | "this is complex", "this will take time", "this is tricky" | Skip the hedge; just execute. |

## Backtesting

Patterns were validated against real history: **6,300 session logs across 464 projects**. A sample of what the detector surfaced:

```json
[
  {
    "project": "benchie",
    "top_pattern": "human_time",
    "total_violations": 1,
    "best_example": "## 100x - major product features (weeks of work, real UX wins) ### SLO-driven recommendation pipeline"
  },
  {
    "project": "farmgpu-shepherd (656ebd9d session)",
    "top_pattern": "human_time",
    "total_violations": 5,
    "best_example": "All 5 violations are the word 'sprint' used as a planning/time-framing unit, all from the single largest file"
  }
]
```

`human_time` dominated real-world hits — overwhelmingly the words *sprint* and *weeks of work* used as planning units, exactly the human-scheduling reflex this plugin exists to remove.

## Commands

| Command | What it does |
| --- | --- |
| `/dehumanize:status` | Show this session's violation count and the most recent matches. |

## License

[FSL-1.1-ALv2](LICENSE) — Functional Source License, Apache-2.0 future grant.
