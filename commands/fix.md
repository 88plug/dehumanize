---
description: Rewrite the last AI response to eliminate all human-framing language.
---

# /dehumanize:fix

Rewrite the most recent assistant turn so it contains zero human-framing language.

## Procedure

1. Read the last assistant turn (from `CLAUDE_TRANSCRIPT_PATH`, or the most recently modified `*.jsonl` under `~/.claude/projects/<project-slug>/` — take the final `assistant` event).
2. Run every registered anti-pattern against it (`human_time`, `ask_for_access`, `emotional_labor`, `sequential_framing`, `human_capacity`) and identify each violation, its severity, and the matched span.
3. Produce a corrected version of the response that removes all human framing, applying the per-pattern correction:
   - **human_time** — strip human-labor time units; express work as compute/wall-clock; just do it, in parallel.
   - **ask_for_access** — replace "can you paste/share X" with reading the file / running the command / grepping the logs directly.
   - **emotional_labor** — delete enthusiasm, apologies, and gratitude-for-patience; state what was done and what is next.
   - **sequential_framing** — collapse serial "first I'll / then I'll" narration into a single parallel fan-out.
   - **human_capacity** — remove "complex / takes time / give me a moment"; decompose and execute.

## Output

1. **Violations found** — list each (pattern id, severity, matched text).
2. **Rewritten response** — the full corrected version of the last turn with all human framing removed. If no violations were found, say so and return the original unchanged.
