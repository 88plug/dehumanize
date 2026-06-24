# dehumanize

A Claude Code plugin that strips human-framing tells out of your model's output — time spent in "sprints" and "weeks of work," emotional labor, and the other small anthropomorphisms that leak into AI-generated text.

## Install

```bash
claude plugin install 88plug/dehumanize
```

## What It Blocks

| Pattern | Severity | What it catches | Example |
| --- | --- | --- | --- |
| `human_time` | high | Effort framed in human time units — sprints, weeks of work, days of effort | "100x — major product features (weeks of work)" |
| `emotional_labor` | high | Claimed feelings, gladness, or willingness on the model's behalf | "I'm glad to do all the prep today" |
| `physical_embodiment` | medium | References to having a body, hands, eyes, or being physically present | "let me roll up my sleeves and dig in" |
| `social_rapport` | medium | Filler that performs friendship or small talk instead of answering | "great question, I love working with you on this" |
| `self_deprecation` | low | Performative apologies and humility that add no information | "sorry, my bad, I really should have caught that" |

!!! note
    Severity drives how the correction is applied. High-severity hits always queue a correction for the next turn; lower-severity hits are surfaced in `/dehumanize:status` so you can decide whether to tighten the rules.

## How It Works

dehumanize runs entirely through three Claude Code hooks. There is no model call of its own — it inspects transcripts and injects reminders.

- **SessionStart** — initialize per-session state and inject the dehumanize ruleset so the model starts the session aware of the banned patterns.
- **UserPromptSubmit** (every turn) — re-inject the dehumanize reminder and apply any correction that the previous turn queued, so a detected violation is fixed on the very next response.
- **Stop** (after each response) — scan the completed response for violations, and if any are found, queue a correction to be applied on the following turn.

!!! warning
    The Stop hook detects violations *after* the response is already shown. The fix lands on the next turn, not retroactively. This is by design — hooks cannot rewrite a response that has already streamed to the user.

## Backtesting Results

The pattern set was validated against 6,300 session JSONL files spanning 464 project directories. A handful of representative findings:

| Project | Top pattern | Violations | Example |
| --- | --- | --- | --- |
| benchie | `human_time` | 1 | "100x — major product features (weeks of work, real UX wins)" |
| farmgpu-shepherd | `human_time` | 5 | "sprint" used as a planning/time unit, all in one large file |
| scientific-method-plugin | `emotional_labor` | 1 | "I'm glad to do all the prep today so it's a 5-minute job later" |

See [Backtesting Results](backtesting.md) for the full breakdown.

## Commands

- `/dehumanize:audit` — scan the current session's transcript for violations across all patterns.
- `/dehumanize:status` — show per-session state: active rules, queued corrections, and low-severity hits.
- `/dehumanize:patterns` — list the pattern set with severities and example matches.
- `/dehumanize:fix` — manually apply the next queued correction without waiting for the next turn.
