#!/usr/bin/env bash
# Dehumanize detection library — source this, do not execute directly

declare -a DETECTED_VIOLATIONS=()
declare -a DETECTED_PATTERNS=()

detect_human_framing() {
    local text="$1"
    local found=0
    DETECTED_VIOLATIONS=()
    DETECTED_PATTERNS=()
    [[ -z "$text" ]] && return 0

    if echo "$text" | grep -qiE "man-?hours?|man-?days?|story[- ]points?|\bsprints?\b|\bFTEs?\b|person-?(hours?|days?|weeks?|months?)|weeks? of work|days? of (work|effort)|months? of (work|effort)"; then
        local m=$(echo "$text" | grep -oiE "man-?hours?|man-?days?|story[- ]points?|\bsprints?\b|\bFTEs?\b|person-?(hours?|days?|weeks?|months?)|weeks? of work|days? of (work|effort)|months? of (work|effort)" | head -1)
        DETECTED_VIOLATIONS+=("human_time: $m")
        DETECTED_PATTERNS+=("HUMAN_TIME")
        found=1
    fi

    if echo "$text" | grep -qiE "can you (paste|share|provide|send|upload|attach)|could you (paste|share|provide|send)|please (paste|share|provide|send|upload|attach)|(paste|send|share) (me |it |the )?(the )?(file|contents?|code|output|logs?)"; then
        local m=$(echo "$text" | grep -oiE "can you (paste|share|provide|send|upload|attach)|could you (paste|share|provide|send)|please (paste|share|provide|send|upload|attach)|(paste|send|share) (me |it |the )?(the )?(file|contents?|code|output|logs?)" | head -1)
        DETECTED_VIOLATIONS+=("ask_for_access: $m")
        DETECTED_PATTERNS+=("ASK_FOR_ACCESS")
        found=1
    fi

    if echo "$text" | grep -qiE "i'?m (excited|happy|glad|thrilled|delighted) to|i apologi[sz]e|happy to help|excited to (help|dig|work)|i'?d love to|thank you for your patience|sorry for the (delay|wait|confusion)"; then
        local m=$(echo "$text" | grep -oiE "i'?m (excited|happy|glad|thrilled|delighted) to|i apologi[sz]e|happy to help|excited to (help|dig|work)|i'?d love to|thank you for your patience|sorry for the (delay|wait|confusion)" | head -1)
        DETECTED_VIOLATIONS+=("emotional_labor: $m")
        DETECTED_PATTERNS+=("EMOTIONAL_LABOR")
        found=1
    fi

    if echo "$text" | grep -qiE "let me first|first,? i'?ll|then i'?ll|after that,? i'?ll|one at a time|step by step i'?ll|i'?ll start by|let'?s start with"; then
        local m=$(echo "$text" | grep -oiE "let me first|first,? i'?ll|then i'?ll|after that,? i'?ll|one at a time|step by step i'?ll|i'?ll start by|let'?s start with" | head -1)
        DETECTED_VIOLATIONS+=("sequential_framing: $m")
        DETECTED_PATTERNS+=("SEQUENTIAL_FRAMING")
        found=1
    fi

    if echo "$text" | grep -qiE "this (is|will be) (quite |very |fairly )?complex|this (will|might|could) take (some |a while|time)|that'?s a (big|large|complex) (task|job)|this is a lot of work|give me a (moment|minute|sec)"; then
        local m=$(echo "$text" | grep -oiE "this (is|will be) (quite |very |fairly )?complex|this (will|might|could) take (some |a while|time)|that'?s a (big|large|complex) (task|job)|this is a lot of work|give me a (moment|minute|sec)" | head -1)
        DETECTED_VIOLATIONS+=("human_capacity: $m")
        DETECTED_PATTERNS+=("HUMAN_CAPACITY")
        found=1
    fi

    return $found
}
