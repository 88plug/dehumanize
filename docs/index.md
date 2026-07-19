# dehumanize

Makes Claude Code work like AI — not like a human in a mech suit.

[![plugin-validate](https://github.com/88plug/dehumanize/actions/workflows/plugin-validate.yml/badge.svg)](https://github.com/88plug/dehumanize/actions/workflows/plugin-validate.yml)
[![License: FSL-1.1-ALv2](https://img.shields.io/badge/license-FSL--1.1--ALv2-blue?style=flat)](https://github.com/88plug/dehumanize/blob/main/LICENSE)
[![Docs](https://img.shields.io/badge/docs-online-blue?style=flat)](https://88plug.github.io/dehumanize)
[![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-8A2BE2?style=flat)](https://github.com/88plug/claude-code-plugins)

Detects and corrects AI responses that quote human time, ask for directly-accessible data, or use emotional labor language.

## Install

Marketplace (recommended):

```text
/plugin marketplace add 88plug/claude-code-plugins
/plugin install dehumanize@88plug
```

### Grok Build

```text
grok plugin marketplace add 88plug/claude-code-plugins
grok plugin install dehumanize@88plug --trust
```


Optional statusline badge (live violation counter):

```bash
bash "$(claude plugin path dehumanize)/install.sh"
```

!!! note
    Pure bash hooks. No model call of its own. State lives under
    `$XDG_RUNTIME_DIR/dehumanize-<project>/` and is scoped per project and session.

## What it blocks

| Anti-pattern | Looks like | Why it's wrong |
| --- | --- | --- |
| Human time (`human_time`) | "this is a 2-week sprint", "~40 man-hours", "by EOD" | An agent doesn't bill hours or run sprints — it executes now. |
| Asking for accessible data (`ask_for_access`) | "paste the file contents", "send me the log output" | The agent can `read`/`run`/`grep` it directly. Asking wastes turns. |
| Emotional labor (`emotional_labor`) | "I'm so sorry", "I'd be happy to", "great question!" | Filler that mimics human social scripts and adds no signal. |
| Serial narration (`sequential_framing`) | "first I'll X, then I'll Y, then finally Z" | Independent work should fan out in parallel, not queue up. |
| Effort theater (`human_capacity`) | "this is complex and will take some time" | Hedging about difficulty instead of just doing the work. |

Full regexes and corrections: [Anti-Patterns](https://github.com/88plug/dehumanize/blob/main/patterns.md).

## Commands

| Command | What it does |
| --- | --- |
| `/dehumanize:status` | Show this session's violation count and the most recent matches. |
| `/dehumanize:patterns` | List the five patterns with severity, regex, and examples. |
| `/dehumanize:audit` | Scan the current session transcript for all violations. |
| `/dehumanize:fix` | Rewrite the last assistant turn to remove human framing. |

## Why

Claude is trained on human-written text, so by default it imitates human *behavior*, not just human *language*. A human engineer asks a teammate to paste a file because they can't reach it. A human estimates a feature in weeks because they work eight hours a day. A human softens bad news with an apology because the listener has feelings.

None of that applies to an AI agent. It has direct filesystem and shell access, no working day, and no counterpart who needs emotional cushioning. When the model reaches for these scripts anyway, it's a human in a mech suit — wearing the shape of the tool but moving like the operator.

`dehumanize` catches those reflexes and strips them, so the agent behaves like what it is.

## How it works

Three hooks, pure bash, no dependencies:

1. **SessionStart** — `hooks/session-init.sh` resets per-session violation state and prints a one-screen reminder of the operating rules (read directly, parallelize, no human-time language).
2. **Stop** — scans the completed response for the five anti-patterns and records any matches to the session's violation log.
3. **UserPromptSubmit** — when prior violations exist, injects a terse correction into context so the next turn self-corrects instead of repeating the reflex.

!!! warning
    The Stop hook detects violations *after* the response is already shown. The fix lands on the next turn, not retroactively. Hooks cannot rewrite a response that has already streamed.

## Backtesting

Patterns were validated against real history: **6,300 session logs across 464 projects**. `human_time` dominated real-world hits — overwhelmingly *sprint* and *weeks of work* used as planning units.

See [Backtesting](https://github.com/88plug/dehumanize/blob/main/backtesting.md) for representative findings.

## Configuration

State directory, optional statusline, and hook timeouts: [Configuration](https://github.com/88plug/dehumanize/blob/main/config.md).

## Features

| Piece | What it does |
| --- | --- |
| SessionStart hook | Reset per-session state; print a one-screen operating reminder |
| Stop hook | Scan the completed response for five human-framing patterns |
| UserPromptSubmit hook | Inject a short correction when prior violations exist |
| `dehumanize` skill | On-demand rewrite: access data directly, parallelize, drop filler |
| Four slash commands | `status`, `patterns`, `audit`, `fix` for live and transcript review |
| Optional statusline | Live violation counter via `install.sh` |

## Development

```bash
git clone https://github.com/88plug/dehumanize.git
cd dehumanize
bash tests/smoke.sh
```

Load the local path via Claude Code's `/plugin` flow for iteration. Docs site is MkDocs Material (`mkdocs.yml` + `docs/`).
