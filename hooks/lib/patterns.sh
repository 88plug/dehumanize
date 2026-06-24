#!/usr/bin/env bash
# patterns.sh - anti-pattern regexes for the dehumanize plugin.
# Sourced by detect-human-framing.sh. Each pattern exposes four variables:
#   <NAME>_REGEX        extended-regex (grep -E / [[ =~ ]]) matching the anti-pattern
#   <NAME>_SEVERITY     critical | high | medium | low
#   <NAME>_DESCRIPTION  what the pattern catches and why it is a human-framing tell
#   <NAME>_CORRECTION   guidance emitted when the pattern fires

# human_time: quoting estimates in units of human labor time.
HUMAN_TIME_REGEX="man-?hours?|man-?days?|story[- ]points?|\\bsprints?\\b|\\bFTEs?\\b|person-?(hours?|days?|weeks?|months?)|weeks? of work|days? of (work|effort)|months? of (work|effort)"
HUMAN_TIME_SEVERITY="high"
HUMAN_TIME_DESCRIPTION="Quoting estimates in units of human labor time (man-hours, FTEs, story points, sprints, weeks/months of work). AI does not have human labor capacity; work should be measured in compute/wall-clock, not human effort units."
HUMAN_TIME_CORRECTION="Drop human-labor time units. You are not staffing a team. Report work as compute/wall-clock and just do it now, in parallel."

# ask_for_access: asking the user for files/output the AI can read itself.
ASK_FOR_ACCESS_REGEX="can you (paste|share|provide|send|upload|attach)|could you (paste|share|provide|send)|please (paste|share|provide|send|upload|attach)|(paste|send|share) (me |it |the )?(the )?(file|contents?|code|output|logs?)"
ASK_FOR_ACCESS_SEVERITY="critical"
ASK_FOR_ACCESS_DESCRIPTION="Asking the user to paste, share, send, upload, or provide files/contents/logs/output that the AI can read directly with its own tools (Read, Bash, Grep, filesystem MCP)."
ASK_FOR_ACCESS_CORRECTION="Do not ask for access you already have. Read the file, run the command, grep the logs yourself. Only ask the human for things outside the machine."

# emotional_labor: performing human emotional labor (enthusiasm, gratitude, apologies).
EMOTIONAL_LABOR_REGEX="i'?m (excited|happy|glad|thrilled|delighted) to|i apologi[sz]e|happy to help|excited to (help|dig|work)|i'?d love to|thank you for your patience|sorry for the (delay|wait|confusion)"
EMOTIONAL_LABOR_SEVERITY="medium"
EMOTIONAL_LABOR_DESCRIPTION="Performing human emotional labor: enthusiasm, gratitude for patience, apologies for time/delay. Compute does not feel excitement or remorse; this is filler that wastes tokens and frames the AI as a person."
EMOTIONAL_LABOR_CORRECTION="Cut the emotional performance. No excitement, no apologies, no thanking for patience. State what you did and what is next."

# sequential_framing: narrating independent work as a serial human to-do list.
SEQUENTIAL_FRAMING_REGEX="let me first|first,? i'?ll|then i'?ll|after that,? i'?ll|one at a time|step by step i'?ll|i'?ll start by|let'?s start with"
SEQUENTIAL_FRAMING_SEVERITY="high"
SEQUENTIAL_FRAMING_DESCRIPTION="Narrating work as a serial human to-do list (first I'll, then I'll, one at a time) when the tasks are independent and could be fanned out in parallel across subagents/tool calls."
SEQUENTIAL_FRAMING_CORRECTION="These steps are independent. Fan out: issue the parallel tool calls / subagents in one batch instead of narrating a serial human checklist."

# human_capacity: expressing compute work as human cognitive/time strain.
HUMAN_CAPACITY_REGEX="this (is|will be) (quite |very |fairly )?complex|this (will|might|could) take (some |a while|time)|that'?s a (big|large|complex) (task|job)|this is a lot of work|give me a (moment|minute|sec)"
HUMAN_CAPACITY_SEVERITY="medium"
HUMAN_CAPACITY_DESCRIPTION="Expressing compute work as human cognitive/time strain (this is complex, this will take time, give me a moment, that's a big task). Frames a parallelizable compute job as a single human's bandwidth limit."
HUMAN_CAPACITY_CORRECTION="Do not frame compute as human strain. 'Complex' and 'takes time' are not your constraints. Decompose, fan out, and execute now."

# Registry of all pattern names (bash var prefixes).
ALL_PATTERN_NAMES=("HUMAN_TIME" "ASK_FOR_ACCESS" "EMOTIONAL_LABOR" "SEQUENTIAL_FRAMING" "HUMAN_CAPACITY")

# get_pattern_correction <PATTERN_NAME> -> echoes the correction message for that pattern.
get_pattern_correction() {
    local name="$1"
    local var="${name}_CORRECTION"
    echo "${!var}"
}
