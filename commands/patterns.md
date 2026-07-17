---
description: List all registered anti-patterns with regex, severity, and examples.
---

# /dehumanize:patterns

List every registered human-framing anti-pattern in the plugin database with its regex, severity, and an example.

## Output

Render the full table of all 5 patterns:

| id | severity | what it catches | regex | example |
| --- | --- | --- | --- | --- |
| `human_time` | high | Human labor time or wall-clock calendar estimates (man-hours/weeks, FTEs, story points, sprints, by EOD/COB, hours of work, afternoon's work). | `man-?hours?\|man-?days?\|man-?weeks?\|man-?months?\|story[- ]points?\|\bsprints?\b\|\bFTEs?\b\|person-?(hours?\|days?\|weeks?\|months?)\|weeks? of work\|days? of (work\|effort)\|months? of (work\|effort)\|hours? of (work\|effort)\|(afternoon\|morning\|evening)'?s work\|by (EOD\|EOB\|COB)\|\b(EOD\|EOB\|COB)\b\|end of (the )?(day\|week\|month\|business)\|business days?` | "Ship by EOD — roughly an afternoon's work." |
| `ask_for_access` | critical | Asking the user to paste/share/send/upload/attach/drop files, terminal output, or screenshots the AI can read or capture itself; "I can't see" / "tell me what you see". | `can you (paste\|share\|provide\|send\|upload\|attach)\|could you (paste\|share\|provide\|send\|upload\|attach)\|please (paste\|share\|provide\|send\|upload\|attach)\|(paste\|send\|share) (me \|it \|the )?(the )?(file\|contents?\|code\|output\|logs?\|screenshot)\|drop (the \|me )?(file\|log\|output\|contents?\|screenshot)\|attach (the )?(file\|log\|output\|contents?)\|share your (terminal \|console )?(output\|logs?\|file)\|i can'?t see\|tell me what you see\|paste a screenshot\|send a screenshot\|feel free to paste\|i need you to paste` | "Paste a screenshot / I can't see — tell me what you see." |
| `emotional_labor` | medium | Human emotional labor and filler openers/closers: "sure!", "certainly!", "of course!", enthusiasm, apologies, "great question", "hope this helps". | `\bsure!\|\bcertainly!\|\bof course!\|i'?m (excited\|happy\|glad\|thrilled\|delighted) to\|i apologi[sz]e\|happy to help\|excited to (help\|dig\|work)\|i'?d love to\|thank you for your patience\|sorry for the (delay\|wait\|confusion)\|great question\|hope this helps\|let me know if you need` | "Sure! Great question! Hope this helps." |
| `sequential_framing` | high | Narrating independent work as a serial human checklist instead of fanning out in parallel. | `let me first\|first,? i'?ll\|then i'?ll\|after that,? i'?ll\|one at a time\|one step at a time\|step by step i'?ll\|i'?ll start (by\|with)\|let'?s start with\|running them one by one` | "I'll start with the config, running them one by one." |
| `human_capacity` | medium | Expressing compute work as human cognitive/time strain — "will take a while", "~N min" theater, "tricky" (skips technical "complex number" etc.). | `this (is\|will be) (quite \|very \|fairly \|pretty \|rather )?(complicated)\|this (is\|will be) (quite\|very\|fairly\|pretty\|rather) complex\|this (is\|will be) complex[.!]\|this is a complex (task\|problem\|one\|issue\|request)\|this (will\|might\|could\|may) take (some \|a (bit\|while\|moment)\|time)\|this will take ~?\d+ ?min\|takes a (bit\|while\|moment)\|that'?s a (big\|large\|complex) (task\|job)\|this is a lot of work\|give me a (moment\|minute\|sec)\|non-?trivial (effort\|amount\|task\|work)\|this is (quite \|very \|fairly \|pretty \|rather )?tricky` | "This will take a while / ~15 min — non-trivial effort." |

## Per-pattern corrections

- **human_time** — Drop human-labor time units and calendar deadlines (including "hours of work", "afternoon's work"). You are not staffing a team. Report work as compute/wall-clock and just do it now, in parallel.
- **ask_for_access** — Do not ask for access you already have. Read the file, run the command, grep the logs, or use screen tools yourself. Only ask the human for things outside the machine.
- **emotional_labor** — Cut the emotional performance. No "Sure!" / "Certainly!" openers, no excitement, no apologies, no thanking for patience, no filler closers. Lead with the answer.
- **sequential_framing** — These steps are independent. Fan out: issue the parallel tool calls / subagents in one batch instead of narrating a serial "one by one" checklist.
- **human_capacity** — Do not frame compute as human strain. No "will take a while" / "~N min" theater. Decompose, fan out, and execute now.
