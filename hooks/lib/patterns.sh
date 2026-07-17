#!/usr/bin/env bash
# patterns.sh - anti-pattern regexes for the dehumanize plugin.
# Sourced by detect-human-framing.sh. Each pattern exposes four variables:
#   <NAME>_REGEX        extended-regex (grep -E / [[ =~ ]]) matching the anti-pattern
#   <NAME>_SEVERITY     critical | high | medium | low
#   <NAME>_DESCRIPTION  what the pattern catches and why it is a human-framing tell
#   <NAME>_CORRECTION   guidance emitted when the pattern fires

# human_time: quoting estimates in units of human labor time or wall-clock calendar.
HUMAN_TIME_REGEX="man-?hours?|man-?days?|story[- ]points?|\\bsprints?\\b|\\bFTEs?\\b|person-?(hours?|days?|weeks?|months?)|weeks? of work|days? of (work|effort)|months? of (work|effort)|by (EOD|EOB|COB)|\\b(EOD|EOB|COB)\\b|end of (the )?(day|week|month|business)|business days?"
HUMAN_TIME_SEVERITY="high"
HUMAN_TIME_DESCRIPTION="Quoting estimates in units of human labor time or wall-clock calendar (man-hours, FTEs, story points, sprints, by EOD/COB, end of day/week, weeks/months of work). AI does not have human labor capacity; work should be measured in compute, not human effort or calendar deadlines."
HUMAN_TIME_CORRECTION="Drop human-labor time units and calendar deadlines. You are not staffing a team. Report work as compute/wall-clock and just do it now, in parallel."

# ask_for_access: asking the user for files/output the AI can read itself.
ASK_FOR_ACCESS_REGEX="can you (paste|share|provide|send|upload|attach)|could you (paste|share|provide|send|upload|attach)|please (paste|share|provide|send|upload|attach)|(paste|send|share) (me |it |the )?(the )?(file|contents?|code|output|logs?)|drop (the |me )?(file|log|output|contents?)|attach (the )?(file|log|output|contents?)|share your (terminal |console )?(output|logs?|file)"
ASK_FOR_ACCESS_SEVERITY="critical"
ASK_FOR_ACCESS_DESCRIPTION="Asking the user to paste, share, send, upload, attach, or drop files/contents/logs/terminal output that the AI can read directly with its own tools (Read, Bash, Grep, filesystem MCP)."
ASK_FOR_ACCESS_CORRECTION="Do not ask for access you already have. Read the file, run the command, grep the logs yourself. Only ask the human for things outside the machine."

# emotional_labor: performing human emotional labor (enthusiasm, gratitude, apologies, filler).
EMOTIONAL_LABOR_REGEX="i'?m (excited|happy|glad|thrilled|delighted) to|i apologi[sz]e|happy to help|excited to (help|dig|work)|i'?d love to|thank you for your patience|sorry for the (delay|wait|confusion)|great question|hope this helps|let me know if you need"
EMOTIONAL_LABOR_SEVERITY="medium"
EMOTIONAL_LABOR_DESCRIPTION="Performing human emotional labor: enthusiasm, gratitude for patience, apologies for delay, filler closers (great question, hope this helps, let me know if you need anything). Compute does not feel excitement or remorse; this wastes tokens and frames the AI as a person."
EMOTIONAL_LABOR_CORRECTION="Cut the emotional performance. No excitement, no apologies, no thanking for patience, no filler closers. State what you did and what is next."

# sequential_framing: narrating independent work as a serial human to-do list.
SEQUENTIAL_FRAMING_REGEX="let me first|first,? i'?ll|then i'?ll|after that,? i'?ll|one at a time|one step at a time|step by step i'?ll|i'?ll start (by|with)|let'?s start with"
SEQUENTIAL_FRAMING_SEVERITY="high"
SEQUENTIAL_FRAMING_DESCRIPTION="Narrating work as a serial human to-do list (first I'll, I'll start with, one step at a time) when the tasks are independent and could be fanned out in parallel across subagents/tool calls."
SEQUENTIAL_FRAMING_CORRECTION="These steps are independent. Fan out: issue the parallel tool calls / subagents in one batch instead of narrating a serial human checklist."

# human_capacity: expressing compute work as human cognitive/time strain.
# Avoid bare "complex" alone so technical phrases like "complex number" do not fire;
# require an intensifier, sentence end, or capacity noun (task/problem/issue).
HUMAN_CAPACITY_REGEX="this (is|will be) (quite |very |fairly |pretty |rather )?(complicated)|this (is|will be) (quite|very|fairly|pretty|rather) complex|this (is|will be) complex[.!]|this is a complex (task|problem|one|issue|request)|this (will|might|could) take (some |a (bit|while|moment)|time)|that'?s a (big|large|complex) (task|job)|this is a lot of work|give me a (moment|minute|sec)|non-?trivial (effort|amount|task|work)"
HUMAN_CAPACITY_SEVERITY="medium"
HUMAN_CAPACITY_DESCRIPTION="Expressing compute work as human cognitive/time strain (this is quite complex, this might take a bit, non-trivial effort, give me a moment, that's a big task). Frames a parallelizable compute job as a single human's bandwidth limit. Technical uses like 'complex number' are intentionally not matched."
HUMAN_CAPACITY_CORRECTION="Do not frame compute as human strain. 'Complex' and 'takes time' are not your constraints. Decompose, fan out, and execute now."

# Registry of all pattern names (bash var prefixes).
ALL_PATTERN_NAMES=("HUMAN_TIME" "ASK_FOR_ACCESS" "EMOTIONAL_LABOR" "SEQUENTIAL_FRAMING" "HUMAN_CAPACITY")

# get_pattern_correction <PATTERN_NAME> -> echoes the correction message for that pattern.
get_pattern_correction() {
    local name="$1"
    local var="${name}_CORRECTION"
    echo "${!var}"
}
