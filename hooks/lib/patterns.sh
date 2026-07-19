#!/usr/bin/env bash
# patterns.sh - anti-pattern regexes for the dehumanize plugin.
# Sourced by detect-human-framing.sh. Each pattern exposes four variables:
#   <NAME>_REGEX        extended-regex (grep -E / [[ =~ ]]) matching the anti-pattern
#   <NAME>_SEVERITY     critical | high | medium | low
#   <NAME>_DESCRIPTION  what the pattern catches and why it is a human-framing tell
#   <NAME>_CORRECTION   guidance emitted when the pattern fires

# human_time: quoting estimates in units of human labor time or wall-clock calendar.
export HUMAN_TIME_REGEX="man-?hours?|man-?days?|man-?weeks?|man-?months?|story[- ]points?|\\bsprints?\\b|\\bFTEs?\\b|person-?(hours?|days?|weeks?|months?)|weeks? of work|days? of (work|effort)|months? of (work|effort)|hours? of (work|effort)|(afternoon|morning|evening)'?s work|by (EOD|EOB|COB)|\\b(EOD|EOB|COB)\\b|end of (the )?(day|week|month|business)|business days?"
export HUMAN_TIME_SEVERITY="high"
export HUMAN_TIME_DESCRIPTION="Quoting estimates in units of human labor time or wall-clock calendar (man-hours/weeks/months, FTEs, story points, sprints, hours of work, afternoon's work, by EOD/COB, end of day/week). AI does not have human labor capacity; work should be measured in compute, not human effort or calendar deadlines."
export HUMAN_TIME_CORRECTION="Drop human-labor time units and calendar deadlines. You are not staffing a team. Report work as compute/wall-clock and just do it now, in parallel."

# ask_for_access: paste/share/upload of files/logs the agent can read; visual asks for screen.
# Avoid bare "please send" (matches "please send feedback") and bare "I can't see" (metaphor).
# "can you provide/share/send" require an object — bare "Can you provide:" menus are often legit.
export ASK_FOR_ACCESS_REGEX="can you (paste|upload|attach)|could you (paste|upload|attach)|can you (share|provide|send) (me )?(the )?(file|log|output|contents?|screenshot|code|logs?)|could you (share|provide|send) (me )?(the )?(file|log|output|contents?|screenshot|code|logs?)|please (paste|share|provide|upload|attach)|please send (me )?(the )?(file|log|output|contents?|screenshot|code)|(paste|send|share) (me |it |the )?(the )?(file|contents?|code|output|logs?)|drop (the |me )?(file|log|output|contents?)|attach (the )?(file|log|output|contents?)|share your (terminal |console )?(output|logs?|file)|paste (a |the )?screenshot|send (a |me )?(a )?screenshot|i can'?t see (your |the )?(screen|display|monitor|desktop|window|ui)|i cannot see (your |the )?(screen|display|monitor|desktop|window|ui)|tell me what you see|feel free to paste|i need you to paste"
export ASK_FOR_ACCESS_SEVERITY="critical"
export ASK_FOR_ACCESS_DESCRIPTION="Asking the user to paste, share, send, upload, attach, or drop files/contents/logs/terminal output, or for screenshots/visual confirmation (paste a screenshot, I can't see your screen, tell me what you see) that the AI can read with tools (Read, Bash, Grep, filesystem MCP, screen). Bare 'please send feedback' / metaphorical 'I can't see the bug' are intentionally not matched."
export ASK_FOR_ACCESS_CORRECTION="Do not ask for access you already have. Read the file, run the command, grep the logs, capture the screen yourself. Only ask the human for things outside the machine."

# emotional_labor: performing human emotional labor (enthusiasm, gratitude, apologies, filler).
export EMOTIONAL_LABOR_REGEX="i'?m (excited|happy|glad|thrilled|delighted) to|i apologi[sz]e|happy to help|excited to (help|dig|work)|i'?d love to|thank you for your patience|sorry for the (delay|wait|confusion)|great question|hope this helps|let me know if you need|\\b(sure|certainly|of course)!"
export EMOTIONAL_LABOR_SEVERITY="medium"
export EMOTIONAL_LABOR_DESCRIPTION="Performing human emotional labor: enthusiasm, gratitude for patience, apologies for delay, filler closers (great question, hope this helps, let me know if you need anything), short openers (Sure!, Certainly!, Of course!). Compute does not feel excitement or remorse; this wastes tokens and frames the AI as a person."
export EMOTIONAL_LABOR_CORRECTION="Cut the emotional performance. No excitement, no apologies, no thanking for patience, no filler closers or Sure!/Certainly! openers. State what you did and what is next."

# sequential_framing: serial human to-do narration (high precision).
# Drop bare "then I'll" / bare "one by one" — corpus showed ~100 FP-ish "then I'll" in
# otherwise fine multi-step narration. Keep first/start/one-at-a-time/running-them-one-by-one.
export SEQUENTIAL_FRAMING_REGEX="let me first|first,? i'?ll|after that,? i'?ll|one at a time|one step at a time|step by step i'?ll|i'?ll start (by|with)|let'?s start with|running them one by one|first i'?ll .{0,40} then i'?ll"
export SEQUENTIAL_FRAMING_SEVERITY="high"
export SEQUENTIAL_FRAMING_DESCRIPTION="Narrating work as a serial human to-do list (first I'll, I'll start with, one step at a time, running them one by one, first…then I'll) when independent work should fan out in parallel. Bare 'then I'll' alone is intentionally not matched."
export SEQUENTIAL_FRAMING_CORRECTION="These steps are independent. Fan out: issue the parallel tool calls / subagents in one batch instead of narrating a serial human checklist."

# human_capacity: expressing compute work as human cognitive/time strain.
# Avoid bare "complex" alone so technical phrases like "complex number" do not fire;
# require an intensifier, sentence end, capacity noun (task/problem/issue), or multi-step.
export HUMAN_CAPACITY_REGEX="this (is|will be) (quite |very |fairly |pretty |rather )?(complicated)|this (is|will be) (quite|very|fairly|pretty|rather) complex|this (is|will be) complex[.!]|this is a complex (task|problem|one|issue|request)|complex multi[- ]steps?|this (will|might|could) take (some |a (bit|while|moment)|time)|this will take ~?[0-9]+ (min|mins|minutes|sec|seconds|hours?)|\\b(takes|taking) a (bit|while|moment)\\b|\\bmay take\\b|that'?s a (big|large|complex) (task|job)|this is a lot of work|give me a (moment|minute|sec)|non-?trivial (effort|amount|task|work)|\\btricky\\b"
export HUMAN_CAPACITY_SEVERITY="medium"
export HUMAN_CAPACITY_DESCRIPTION="Expressing compute work as human cognitive/time strain (this is quite complex, this is tricky, this might take a bit, takes a moment, this will take 5 min, non-trivial effort, complex multi-step). Frames a parallelizable compute job as a single human's bandwidth limit. Technical uses like 'complex number' are intentionally not matched."
export HUMAN_CAPACITY_CORRECTION="Do not frame compute as human strain. 'Complex', 'tricky', and 'takes time' are not your constraints. Decompose, fan out, and execute now."

# Registry of all pattern names (bash var prefixes).
export ALL_PATTERN_NAMES=("HUMAN_TIME" "ASK_FOR_ACCESS" "EMOTIONAL_LABOR" "SEQUENTIAL_FRAMING" "HUMAN_CAPACITY")

# get_pattern_correction <PATTERN_NAME> -> echoes the correction message for that pattern.
get_pattern_correction() {
    local name="$1"
    local var="${name}_CORRECTION"
    echo "${!var}"
}
