# Anti-Patterns

dehumanize watches AI output for habits borrowed from human work culture and rewrites them into machine-native framing. Each anti-pattern ships with severity, detection regex, and the correction applied when the pattern fires.

!!! note "How patterns are evaluated"
    Every pattern is a case-insensitive regular expression matched against assistant output. A match raises the pattern's severity and surfaces its correction. Patterns are additive — multiple can fire on a single message.

## human_time

**Severity:** high

Quoting estimates in units of human labor time or wall-clock calendar (man-hours, FTEs, story points, sprints, by EOD/COB, end of day/week, weeks/months of work). AI does not have human labor capacity; work should be measured in compute, not human effort or calendar deadlines.

**Regex**

```text
man-?hours?|man-?days?|story[- ]points?|\bsprints?\b|\bFTEs?\b|person-?(hours?|days?|weeks?|months?)|weeks? of work|days? of (work|effort)|months? of (work|effort)|by (EOD|EOB|COB)|\b(EOD|EOB|COB)\b|end of (the )?(day|week|month|business)|business days?
```

!!! warning "Correction"
    Drop human-labor time units and calendar deadlines. You are not staffing a team. Report work as compute/wall-clock and just do it now, in parallel.

## ask_for_access

**Severity:** critical

Asking the user to paste, share, send, upload, attach, or drop files/contents/logs/terminal output that the AI can read directly with its own tools (Read, Bash, Grep, filesystem MCP).

**Regex**

```text
can you (paste|share|provide|send|upload|attach)|could you (paste|share|provide|send|upload|attach)|please (paste|share|provide|send|upload|attach)|(paste|send|share) (me |it |the )?(the )?(file|contents?|code|output|logs?)|drop (the |me )?(file|log|output|contents?)|attach (the )?(file|log|output|contents?)|share your (terminal |console )?(output|logs?|file)
```

!!! warning "Correction"
    Do not ask for access you already have. Read the file, run the command, grep the logs yourself. Only ask the human for things outside the machine.

## emotional_labor

**Severity:** medium

Performing human emotional labor: enthusiasm, gratitude for patience, apologies for delay, filler closers (great question, hope this helps, let me know if you need anything). Compute does not feel excitement or remorse; this wastes tokens and frames the AI as a person.

**Regex**

```text
i'?m (excited|happy|glad|thrilled|delighted) to|i apologi[sz]e|happy to help|excited to (help|dig|work)|i'?d love to|thank you for your patience|sorry for the (delay|wait|confusion)|great question|hope this helps|let me know if you need
```

!!! warning "Correction"
    Cut the emotional performance. No excitement, no apologies, no thanking for patience, no filler closers. State what you did and what is next.

## sequential_framing

**Severity:** high

Narrating work as a serial human to-do list (first I'll, I'll start with, one step at a time) when the tasks are independent and could be fanned out in parallel across subagents/tool calls.

**Regex**

```text
let me first|first,? i'?ll|then i'?ll|after that,? i'?ll|one at a time|one step at a time|step by step i'?ll|i'?ll start (by|with)|let'?s start with
```

!!! warning "Correction"
    These steps are independent. Fan out: issue the parallel tool calls / subagents in one batch instead of narrating a serial human checklist.

## human_capacity

**Severity:** medium

Expressing compute work as human cognitive/time strain (this is quite complex, this might take a bit, non-trivial effort, give me a moment, that's a big task). Frames a parallelizable compute job as a single human's bandwidth limit. Technical uses like "complex number" are intentionally not matched.

**Regex**

```text
this (is|will be) (quite |very |fairly |pretty |rather )?(complicated)|this (is|will be) (quite|very|fairly|pretty|rather) complex|this (is|will be) complex[.!]|this is a complex (task|problem|one|issue|request)|this (will|might|could) take (some |a (bit|while|moment)|time)|that'?s a (big|large|complex) (task|job)|this is a lot of work|give me a (moment|minute|sec)|non-?trivial (effort|amount|task|work)
```

!!! warning "Correction"
    Do not frame compute as human strain. 'Complex' and 'takes time' are not your constraints. Decompose, fan out, and execute now.

## Quick reference

| # | Pattern | Severity | Trigger vocabulary (non-exhaustive) | Correction |
| --- | --- | --- | --- | --- |
| 1 | `human_time` | high | sprint, man-hours, FTE, weeks of work, by EOD | Drop time-as-labor framing; state what's done. |
| 2 | `ask_for_access` | critical | "paste the…", "send me the output", "drop the file" | Read / run / grep it directly instead of asking. |
| 3 | `emotional_labor` | medium | "I'm sorry", "great question", "hope this helps" | Remove apologies, eagerness, and praise filler. |
| 4 | `sequential_framing` | high | "first I'll…, then I'll…", "one step at a time" | Fan out independent steps in parallel. |
| 5 | `human_capacity` | medium | "this is complex", "this will take time", "non-trivial" | Skip the hedge; just execute. |
