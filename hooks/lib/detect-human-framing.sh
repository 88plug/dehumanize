#!/usr/bin/env bash
# Dehumanize detection library — source this, do not execute directly

# shellcheck source=patterns.sh
_DEHUMANIZE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$_DEHUMANIZE_LIB_DIR/patterns.sh"

declare -a DETECTED_VIOLATIONS=()
declare -a DETECTED_PATTERNS=()

detect_human_framing() {
    local text="$1"
    local found=0
    DETECTED_VIOLATIONS=()
    DETECTED_PATTERNS=()
    [[ -z "$text" ]] && return 0

    local name regex_var regex id m
    for name in "${ALL_PATTERN_NAMES[@]}"; do
        regex_var="${name}_REGEX"
        regex="${!regex_var}"
        if echo "$text" | grep -qiE "$regex"; then
            m=$(echo "$text" | grep -oiE "$regex" | head -1)
            id=$(echo "$name" | tr '[:upper:]' '[:lower:]')
            DETECTED_VIOLATIONS+=("${id}: $m")
            DETECTED_PATTERNS+=("$name")
            found=1
        fi
    done

    return $found
}
