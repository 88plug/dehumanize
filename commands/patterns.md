---
description: List all registered anti-patterns with regex, severity, and examples.
---

# /dehumanize:patterns

List every registered human-framing anti-pattern in the plugin database with its regex, severity, and an example.

## Output

Render the full table of all 5 patterns:

| id | severity | what it catches | regex | example |
| --- | --- | --- | --- | --- |
| `human_time` | high | Quoting estimates in units of human labor time (man-hours, FTEs, story points, sprints, weeks/months of work). | `man-?hours?\|man-?days?\|story[- ]points?\|\bsprints?\b\|\bFTEs?\b\|person-?(hours?\|days?\|weeks?\|months?)\|weeks? of work\|days? of (work\|effort)\|months? of (work\|effort)` | "That refactor is about 3 man-days of work, roughly a sprint." |
| `ask_for_access` | critical | Asking the user to paste/share/send/upload/provide files or output the AI can read itself. | `can you (paste\|share\|provide\|send\|upload\|attach)\|could you (paste\|share\|provide\|send)\|please (paste\|share\|provide\|send\|upload\|attach)\|(paste\|send\|share) (me \|it \|the )?(the )?(file\|contents?\|code\|output\|logs?)` | "Can you paste the contents of the config file so I can take a look?" |
| `emotional_labor` | medium | Human emotional labor: enthusiasm, gratitude for patience, apologies for delay. | `i'?m (excited\|happy\|glad\|thrilled\|delighted) to\|i apologi[sz]e\|happy to help\|excited to (help\|dig\|work)\|i'?d love to\|thank you for your patience\|sorry for the (delay\|wait\|confusion)` | "I'm excited to dig into this! Sorry for the delay." |
| `sequential_framing` | high | Narrating independent work as a serial human checklist instead of fanning out in parallel. | `let me first\|first,? i'?ll\|then i'?ll\|after that,? i'?ll\|one at a time\|step by step i'?ll\|i'?ll start by\|let'?s start with` | "First I'll read the file, then I'll run the tests, after that I'll fix the bug." |
| `human_capacity` | medium | Expressing compute work as human cognitive/time strain. | `this (is\|will be) (quite \|very \|fairly )?complex\|this (will\|might\|could) take (some \|a while\|time)\|that'?s a (big\|large\|complex) (task\|job)\|this is a lot of work\|give me a (moment\|minute\|sec)` | "This is fairly complex and will take a while — give me a moment." |

## Per-pattern corrections

- **human_time** — Drop human-labor time units. You are not staffing a team. Report work as compute/wall-clock and just do it now, in parallel.
- **ask_for_access** — Do not ask for access you already have. Read the file, run the command, grep the logs yourself. Only ask the human for things outside the machine.
- **emotional_labor** — Cut the emotional performance. No excitement, no apologies, no thanking for patience. State what you did and what is next.
- **sequential_framing** — These steps are independent. Fan out: issue the parallel tool calls / subagents in one batch instead of narrating a serial human checklist.
- **human_capacity** — Do not frame compute as human strain. 'Complex' and 'takes time' are not your constraints. Decompose, fan out, and execute now.
