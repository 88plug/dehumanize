<div align="center">

# Dehumanize

AI agent guardrails for Claude Code and Grok — strips human-framing anti-patterns so the LLM works like AI, not a human in a mech suit.

[![plugin-validate](https://github.com/88plug/dehumanize/actions/workflows/plugin-validate.yml/badge.svg)](https://github.com/88plug/dehumanize/actions/workflows/plugin-validate.yml)
[![License: FSL-1.1-ALv2](https://img.shields.io/badge/license-FSL--1.1--ALv2-blue?style=flat)](LICENSE)
[![Docs](https://img.shields.io/badge/docs-online-blue?style=flat)](https://88plug.github.io/dehumanize/)
[![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-8A2BE2?style=flat)](https://github.com/88plug/claude-code-plugins)
[![DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/88plug/dehumanize)

</div>

## Install

### Claude Code

```text
/plugin marketplace add 88plug/claude-code-plugins
/plugin install dehumanize@88plug
```

### Grok Build

```text
grok plugin marketplace add 88plug/claude-code-plugins
grok plugin install dehumanize@88plug --trust
```


Hooks activate on the next session. No API keys, no model calls of their own — pure bash guardrails.

## Why this Claude Code plugin

Claude and other LLMs are trained on human-written text, so AI coding agents often imitate human *behavior*, not just human language. They quote man-hours and sprints, ask you to paste files they can `read` themselves, open with "Sure! Great question!", and narrate serial checklists instead of fanning out tool calls.

None of that fits an AI agent with shell access, no working day, and no need for emotional cushioning. **dehumanize** is instruction-following guardrails for Claude Code: detect those anti-patterns on Stop, inject a terse correction on the next UserPromptSubmit, and keep the agent productive.

## Features

| Piece | What it does |
| --- | --- |
| SessionStart hook | Reset per-session state; print a one-screen operating reminder |
| Stop hook | Scan the completed response for five human-framing patterns |
| UserPromptSubmit hook | Inject a short correction when prior violations exist |
| `dehumanize` skill | On-demand rewrite: access data directly, parallelize, drop filler |
| Four slash commands | `status`, `patterns`, `audit`, `fix` for live and transcript review |
| Optional statusline | Live violation counter via `install.sh` |

## What it blocks

| Pattern id | Looks like | Why it's wrong |
| --- | --- | --- |
| `human_time` | "2-week sprint", "~40 man-hours", "by EOD" | Agents don't bill hours or run sprints — they execute now. |
| `ask_for_access` | "paste the file", "send me the log", "I can't see your screen" | The agent can read, run, grep, or capture it. Asking wastes turns. |
| `emotional_labor` | "Sure!", "I'd be happy to", "great question!" | Social filler. No signal. |
| `sequential_framing` | "first I'll… then I'll…", "one by one" | Independent work should fan out in parallel. |
| `human_capacity` | "this is complex", "will take ~15 min", "tricky" | Capacity theater instead of doing the work. |

Full regexes, severities, and corrections: [docs/patterns](https://88plug.github.io/dehumanize/patterns/) or `/dehumanize:patterns`.

## Quickstart

1. Install from the hub (above). Start a new Claude Code session.
2. Work as usual. If a response hits a pattern, the next prompt gets a one-line correction in context.
3. Check the session:

```text
/dehumanize:status
```

4. List patterns, audit the transcript, or rewrite the last turn:

```text
/dehumanize:patterns
/dehumanize:audit
/dehumanize:fix
```

> [!NOTE]
> The Stop hook records violations *after* the response is already shown. The correction lands on the **next** turn. Hooks cannot rewrite a response that has already streamed.

## How it works

Three hooks, pure bash, no dependencies:

1. **SessionStart** — `hooks/session-init.sh` resets violation state and prints the rules (read directly, parallelize, no human-time language).
2. **Stop** — `hooks/capture-stop.sh` runs the detector (`hooks/lib/detect-human-framing.sh` + `hooks/lib/patterns.sh`) and appends matches to the session log.
3. **UserPromptSubmit** — `hooks/inject-correction.sh` injects a terse fix when the log is non-empty so the next turn self-corrects.

State lives under `$XDG_RUNTIME_DIR/dehumanize-<project>/`, scoped per project and session.

## Commands

| Command | What it does |
| --- | --- |
| `/dehumanize:status` | Session violation count and most recent matches |
| `/dehumanize:patterns` | All five patterns: severity, regex, examples, corrections |
| `/dehumanize:audit` | Scan the current session transcript for every hit |
| `/dehumanize:fix` | Rewrite the last assistant turn with human framing removed |

## Skill

The `dehumanize` Claude skill encodes the same five rules for on-demand use: access data and screens directly, fan out independent steps, drop human time units, cut emotional labor, skip capacity theater. Invoke when a draft drifts; keep technical content, strip only the human framing.

## Anti-pattern reference

| # | Pattern | Trigger vocabulary (non-exhaustive) | Correction |
| --- | --- | --- | --- |
| 1 | `human_time` | sprint, man-hours, FTE, weeks of work, by EOD/COB | Drop labor-time framing; state what's done. |
| 2 | `ask_for_access` | paste/send/share the file, drop the log, screenshot | Read / run / grep / capture it yourself. |
| 3 | `emotional_labor` | Sure!, Certainly!, great question, hope this helps | Lead with the answer; no praise filler. |
| 4 | `sequential_framing` | first I'll, I'll start with, one step at a time | Fan out independent steps in one batch. |
| 5 | `human_capacity` | this is complex, will take a while, non-trivial effort | Skip the hedge; decompose and execute. |

## Backtesting

Patterns were validated against real history: **6,300 session logs across 464 projects**. Sample detector output:

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

`human_time` dominated real-world hits — *sprint* and *weeks of work* as planning units. Corpus evals also tightened false positives on sequential and access patterns (see [docs/backtesting](https://88plug.github.io/dehumanize/backtesting/)).

## Optional statusline

Live violation counter in the Claude Code statusline:

```bash
bash "$(claude plugin path dehumanize)/install.sh"
```

Details: [docs/config](https://88plug.github.io/dehumanize/config/).

## Development

```bash
git clone https://github.com/88plug/dehumanize.git
cd dehumanize
bash tests/smoke.sh
```

Load the local path via Claude Code's `/plugin` flow for iteration. Docs site is MkDocs Material (`mkdocs.yml` + `docs/`).

## Docs and license

- [Online docs](https://88plug.github.io/dehumanize/)
- [DeepWiki](https://deepwiki.com/88plug/dehumanize)
- [88plug Claude Code plugins marketplace](https://github.com/88plug/claude-code-plugins)

[FSL-1.1-ALv2](LICENSE) — Functional Source License, Apache-2.0 future grant.
