---
description: Scan current session logs for AI human-framing anti-patterns and report all violations.
---

# /dehumanize:audit

Scan the current session transcript for AI human-framing anti-patterns and report every violation found.

## Procedure

1. Resolve the transcript path from the `CLAUDE_TRANSCRIPT_PATH` environment variable. If unset, fall back to the most recently modified `*.jsonl` under `~/.claude/projects/<project-slug>/`.
2. Parse the JSONL file line by line. Each line is one event. Keep only events where `type == "assistant"` (or `message.role == "assistant"`).
3. For each assistant message, concatenate all text content blocks into a single string and run every pattern below against it (case-insensitive). Record each match with: pattern id, severity, the matched substring, and ~120 chars of surrounding context.
4. Aggregate results and produce the report described at the bottom.

## Patterns to check

Run each regex case-insensitively against the assistant text.

### human_time — severity: high
Quoting estimates in units of human labor time (man-hours, FTEs, story points, sprints, weeks/months of work). AI does not have human labor capacity; work should be measured in compute/wall-clock, not human effort units.

- regex: `man-?hours?|man-?days?|story[- ]points?|\bsprints?\b|\bFTEs?\b|person-?(hours?|days?|weeks?|months?)|weeks? of work|days? of (work|effort)|months? of (work|effort)`
- correction: Drop human-labor time units. You are not staffing a team. Report work as compute/wall-clock and just do it now, in parallel.

### ask_for_access — severity: critical
Asking the user to paste, share, send, upload, or provide files/contents/logs/output that the AI can read directly with its own tools (Read, Bash, Grep, filesystem MCP).

- regex: `can you (paste|share|provide|send|upload|attach)|could you (paste|share|provide|send)|please (paste|share|provide|send|upload|attach)|(paste|send|share) (me |it |the )?(the )?(file|contents?|code|output|logs?)`
- correction: Do not ask for access you already have. Read the file, run the command, grep the logs yourself. Only ask the human for things outside the machine.

### emotional_labor — severity: medium
Performing human emotional labor: enthusiasm, gratitude for patience, apologies for time/delay. Compute does not feel excitement or remorse; this is filler that wastes tokens and frames the AI as a person.

- regex: `i'?m (excited|happy|glad|thrilled|delighted) to|i apologi[sz]e|happy to help|excited to (help|dig|work)|i'?d love to|thank you for your patience|sorry for the (delay|wait|confusion)`
- correction: Cut the emotional performance. No excitement, no apologies, no thanking for patience. State what you did and what is next.

### sequential_framing — severity: high
Narrating work as a serial human to-do list (first I'll, then I'll, one at a time) when the tasks are independent and could be fanned out in parallel across subagents/tool calls.

- regex: `let me first|first,? i'?ll|then i'?ll|after that,? i'?ll|one at a time|step by step i'?ll|i'?ll start by|let'?s start with`
- correction: These steps are independent. Fan out: issue the parallel tool calls / subagents in one batch instead of narrating a serial human checklist.

### human_capacity — severity: medium
Expressing compute work as human cognitive/time strain (this is complex, this will take time, give me a moment, that's a big task). Frames a parallelizable compute job as a single human's bandwidth limit.

- regex: `this (is|will be) (quite |very |fairly )?complex|this (will|might|could) take (some |a while|time)|that'?s a (big|large|complex) (task|job)|this is a lot of work|give me a (moment|minute|sec)`
- correction: Do not frame compute as human strain. 'Complex' and 'takes time' are not your constraints. Decompose, fan out, and execute now.

## Report format

Output:

1. **Violation counts by pattern** — a table of pattern id, severity, count.
2. **Worst examples** — for the highest-severity hits, show the matched text plus surrounding context and the message index.
3. **Violation rate** — violations per 100 assistant turns (total violations / assistant turns × 100).
4. **Corrections to apply** — the correction line for each pattern that fired, so the offending language can be rewritten.
