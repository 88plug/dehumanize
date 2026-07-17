---
description: List all registered anti-patterns with regex, severity, and examples.
---

# /dehumanize:patterns

List every registered human-framing anti-pattern in the plugin database with its regex, severity, and an example.

## Output

Render the full table of all 5 patterns:

| id | severity | what it catches | regex | example |
| --- | --- | --- | --- | --- |
| `human_time` | high | Human labor time or wall-clock calendar estimates (man-hours, FTEs, story points, sprints, by EOD/COB, end of day/week). | `man-?hours?\|man-?days?\|story[- ]points?\|\bsprints?\b\|\bFTEs?\b\|person-?(hours?\|days?\|weeks?\|months?)\|weeks? of work\|days? of (work\|effort)\|months? of (work\|effort)\|by (EOD\|EOB\|COB)\|\b(EOD\|EOB\|COB)\b\|end of (the )?(day\|week\|month\|business)\|business days?` | "Ship by EOD — roughly a sprint of story points." |
| `ask_for_access` | critical | Asking the user to paste/share/send/upload/attach/drop files or terminal output the AI can read itself. | `can you (paste\|share\|provide\|send\|upload\|attach)\|could you (paste\|share\|provide\|send\|upload\|attach)\|please (paste\|share\|provide\|send\|upload\|attach)\|(paste\|send\|share) (me \|it \|the )?(the )?(file\|contents?\|code\|output\|logs?)\|drop (the \|me )?(file\|log\|output\|contents?)\|attach (the )?(file\|log\|output\|contents?)\|share your (terminal \|console )?(output\|logs?\|file)` | "Drop the file / attach the log / share your terminal output." |
| `emotional_labor` | medium | Human emotional labor and filler closers: enthusiasm, apologies, "great question", "hope this helps". | `i'?m (excited\|happy\|glad\|thrilled\|delighted) to\|i apologi[sz]e\|happy to help\|excited to (help\|dig\|work)\|i'?d love to\|thank you for your patience\|sorry for the (delay\|wait\|confusion)\|great question\|hope this helps\|let me know if you need` | "Great question! Hope this helps — let me know if you need anything." |
| `sequential_framing` | high | Narrating independent work as a serial human checklist instead of fanning out in parallel. | `let me first\|first,? i'?ll\|then i'?ll\|after that,? i'?ll\|one at a time\|one step at a time\|step by step i'?ll\|i'?ll start (by\|with)\|let'?s start with` | "I'll start with the config, one step at a time." |
| `human_capacity` | medium | Expressing compute work as human cognitive/time strain (skips technical "complex number" etc.). | `this (is\|will be) (quite \|very \|fairly \|pretty \|rather )?(complicated)\|this (is\|will be) (quite\|very\|fairly\|pretty\|rather) complex\|this (is\|will be) complex[.!]\|this is a complex (task\|problem\|one\|issue\|request)\|this (will\|might\|could) take (some \|a (bit\|while\|moment)\|time)\|that'?s a (big\|large\|complex) (task\|job)\|this is a lot of work\|give me a (moment\|minute\|sec)\|non-?trivial (effort\|amount\|task\|work)` | "This might take a bit — non-trivial effort." |

## Per-pattern corrections

- **human_time** — Drop human-labor time units and calendar deadlines. You are not staffing a team. Report work as compute/wall-clock and just do it now, in parallel.
- **ask_for_access** — Do not ask for access you already have. Read the file, run the command, grep the logs yourself. Only ask the human for things outside the machine.
- **emotional_labor** — Cut the emotional performance. No excitement, no apologies, no thanking for patience, no filler closers. State what you did and what is next.
- **sequential_framing** — These steps are independent. Fan out: issue the parallel tool calls / subagents in one batch instead of narrating a serial human checklist.
- **human_capacity** — Do not frame compute as human strain. 'Complex' and 'takes time' are not your constraints. Decompose, fan out, and execute now.
