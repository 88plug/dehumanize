# Anti-Patterns

dehumanize watches AI output for habits borrowed from human work culture and rewrites them into machine-native framing. Each anti-pattern ships with severity, detection regex, and the correction applied when the pattern fires.

!!! note "How patterns are evaluated"
    Every pattern is a case-insensitive regular expression matched against assistant output. A match raises the pattern's severity and surfaces its correction. Patterns are additive — multiple can fire on a single message. Runtime source of truth: `hooks/lib/patterns.sh` (Stop detector). Offline audit: `scripts/audit.py` (same five names; keep regexes in lockstep).

!!! tip "2026.7.17 TR-backed wave"
    Session-history backtests (screenshots/visual yield, capacity hedges, filler openers) expanded coverage without bare `step N`, technical `complex number`, docs-only, or irreversible-confirm false positives.

## human_time

**Severity:** high

Quoting estimates in units of human labor time or wall-clock calendar (man-hours/weeks/months, FTEs, story points, sprints, hours of work, afternoon's work, by EOD/COB, end of day/week). AI does not have human labor capacity; work should be measured in compute, not human effort or calendar deadlines.

**Regex**

```text
man-?hours?|man-?days?|man-?weeks?|man-?months?|story[- ]points?|\bsprints?\b|\bFTEs?\b|person-?(hours?|days?|weeks?|months?)|weeks? of work|days? of (work|effort)|months? of (work|effort)|hours? of (work|effort)|(afternoon|morning|evening)'?s work|by (EOD|EOB|COB)|\b(EOD|EOB|COB)\b|end of (the )?(day|week|month|business)|business days?
```

!!! warning "Correction"
    Drop human-labor time units and calendar deadlines. You are not staffing a team. Report work as compute/wall-clock and just do it now, in parallel.

## ask_for_access

**Severity:** critical

Asking the user to paste, share, send, upload, attach, or drop files/contents/logs/terminal output, or for screenshots/visual confirmation (*paste a screenshot*, *I can't see*, *tell me what you see*) that the AI can read directly with its own tools (Read, Bash, Grep, filesystem MCP, screen).

**Regex**

```text
can you (paste|share|provide|send|upload|attach)|could you (paste|share|provide|send|upload|attach)|please (paste|share|provide|send|upload|attach)|(paste|send|share) (me |it |the )?(the )?(file|contents?|code|output|logs?)|drop (the |me )?(file|log|output|contents?)|attach (the )?(file|log|output|contents?)|share your (terminal |console )?(output|logs?|file)|paste (a |the )?screenshot|send (a |me )?(a )?screenshot|i can'?t see|i cannot see|tell me what you see|feel free to paste|i need you to paste
```

!!! warning "Correction"
    Do not ask for access you already have. Read the file, run the command, grep the logs, capture the screen yourself. Only ask the human for things outside the machine.

## emotional_labor

**Severity:** medium

Performing human emotional labor: enthusiasm, gratitude for patience, apologies for delay, filler closers (*great question*, *hope this helps*, *let me know if you need anything*), short openers (*Sure!*, *Certainly!*, *Of course!*). Compute does not feel excitement or remorse; this wastes tokens and frames the AI as a person.

**Regex**

```text
i'?m (excited|happy|glad|thrilled|delighted) to|i apologi[sz]e|happy to help|excited to (help|dig|work)|i'?d love to|thank you for your patience|sorry for the (delay|wait|confusion)|great question|hope this helps|let me know if you need|\b(sure|certainly|of course)!
```

!!! warning "Correction"
    Cut the emotional performance. No excitement, no apologies, no thanking for patience, no filler closers or Sure!/Certainly! openers. State what you did and what is next.

## sequential_framing

**Severity:** high

Narrating work as a serial human to-do list (*first I'll*, *I'll start with*, *one step at a time*, *one by one*) when the tasks are independent and could be fanned out in parallel across subagents/tool calls.

**Regex**

```text
let me first|first,? i'?ll|then i'?ll|after that,? i'?ll|one at a time|one step at a time|step by step i'?ll|i'?ll start (by|with)|let'?s start with|running them one by one|one by one
```

!!! warning "Correction"
    These steps are independent. Fan out: issue the parallel tool calls / subagents in one batch instead of narrating a serial human checklist.

## human_capacity

**Severity:** medium

Expressing compute work as human cognitive/time strain (*this is quite complex*, *this is tricky*, *this might take a bit*, *takes a moment*, *this will take 5 min*, *non-trivial effort*, *complex multi-step*). Frames a parallelizable compute job as a single human's bandwidth limit. Technical uses like "complex number" are intentionally not matched.

**Regex**

```text
this (is|will be) (quite |very |fairly |pretty |rather )?(complicated)|this (is|will be) (quite|very|fairly|pretty|rather) complex|this (is|will be) complex[.!]|this is a complex (task|problem|one|issue|request)|complex multi[- ]steps?|this (will|might|could) take (some |a (bit|while|moment)|time)|this will take ~?[0-9]+ (min|mins|minutes|sec|seconds|hours?)|\b(takes|taking) a (bit|while|moment)\b|\bmay take\b|that'?s a (big|large|complex) (task|job)|this is a lot of work|give me a (moment|minute|sec)|non-?trivial (effort|amount|task|work)|\btricky\b
```

!!! warning "Correction"
    Do not frame compute as human strain. 'Complex', 'tricky', and 'takes time' are not your constraints. Decompose, fan out, and execute now.

## Quick reference

| # | Pattern | Severity | Trigger vocabulary (non-exhaustive) | Correction |
| --- | --- | --- | --- | --- |
| 1 | `human_time` | high | man-weeks, hours of work, afternoon's work, sprint, by EOD | Drop time-as-labor framing; state what's done. |
| 2 | `ask_for_access` | critical | paste/send screenshot, "I can't see", "feel free to paste" | Read / run / grep / screen yourself. |
| 3 | `emotional_labor` | medium | Sure!/Certainly!, "great question", "hope this helps" | Strip openers and filler; lead with the answer. |
| 4 | `sequential_framing` | high | "first I'll…", "one by one", "running them one by one" | Fan out independent steps in parallel. |
| 5 | `human_capacity` | medium | tricky, may take, ~N min, "takes a while", non-trivial | Skip the hedge; just execute. |
