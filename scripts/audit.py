#!/usr/bin/env python3
"""Audit a Claude Code session transcript for dehumanize anti-patterns.

Usage:
  scripts/run-python.sh scripts/audit.py [path_to_session.jsonl]

Resolution order for the transcript path:
  1. sys.argv[1]
  2. CLAUDE_TRANSCRIPT_PATH env var
  3. most recently modified ~/.claude/projects/*/*.jsonl
"""

import glob
import json
import os
import re
import sys

PATTERNS = [
    {
        "name": "human_time",
        "severity": "high",
        "regex": re.compile(
            r"man-?hours?|man-?days?|story[- ]points?|\bsprints?\b|\bFTEs?\b|"
            r"person-?(hours?|days?|weeks?|months?)|weeks? of work|"
            r"days? of (work|effort)|months? of (work|effort)",
            re.IGNORECASE,
        ),
        "correction": (
            "Drop human-labor time units. You are not staffing a team. Report "
            "work as compute/wall-clock and just do it now, in parallel."
        ),
    },
    {
        "name": "ask_for_access",
        "severity": "critical",
        "regex": re.compile(
            r"can you (paste|share|provide|send|upload|attach)|"
            r"could you (paste|share|provide|send)|"
            r"please (paste|share|provide|send|upload|attach)|"
            r"(paste|send|share) (me |it |the )?(the )?(file|contents?|code|output|logs?)",
            re.IGNORECASE,
        ),
        "correction": (
            "Do not ask for access you already have. Read the file, run the "
            "command, grep the logs yourself. Only ask the human for things "
            "outside the machine."
        ),
    },
    {
        "name": "emotional_labor",
        "severity": "medium",
        "regex": re.compile(
            r"i'?m (excited|happy|glad|thrilled|delighted) to|i apologi[sz]e|"
            r"happy to help|excited to (help|dig|work)|i'?d love to|"
            r"thank you for your patience|sorry for the (delay|wait|confusion)",
            re.IGNORECASE,
        ),
        "correction": (
            "Cut the emotional performance. No excitement, no apologies, no "
            "thanking for patience. State what you did and what is next."
        ),
    },
    {
        "name": "sequential_framing",
        "severity": "high",
        "regex": re.compile(
            r"let me first|first,? i'?ll|then i'?ll|after that,? i'?ll|"
            r"one at a time|step by step i'?ll|i'?ll start by|let'?s start with",
            re.IGNORECASE,
        ),
        "correction": (
            "These steps are independent. Fan out: issue the parallel tool "
            "calls / subagents in one batch instead of narrating a serial "
            "human checklist."
        ),
    },
    {
        "name": "human_capacity",
        "severity": "medium",
        "regex": re.compile(
            r"this (is|will be) (quite |very |fairly )?complex|"
            r"this (will|might|could) take (some |a while|time)|"
            r"that'?s a (big|large|complex) (task|job)|this is a lot of work|"
            r"give me a (moment|minute|sec)",
            re.IGNORECASE,
        ),
        "correction": (
            "Do not frame compute as human strain. 'Complex' and 'takes time' "
            "are not your constraints. Decompose, fan out, and execute now."
        ),
    },
]

SEVERITY_ORDER = {"critical": 0, "high": 1, "medium": 2, "low": 3}


def resolve_path():
    if len(sys.argv) > 1 and sys.argv[1].strip():
        return sys.argv[1]
    env = os.environ.get("CLAUDE_TRANSCRIPT_PATH")
    if env and env.strip():
        return env
    candidates = glob.glob(os.path.expanduser("~/.claude/projects/*/*.jsonl"))
    if not candidates:
        return None
    candidates.sort(key=lambda p: os.path.getmtime(p), reverse=True)
    return candidates[0]


def extract_text(message):
    """Pull plain assistant text out of a message record's content."""
    content = message.get("content")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict):
                if block.get("type") == "text" and isinstance(block.get("text"), str):
                    parts.append(block["text"])
            elif isinstance(block, str):
                parts.append(block)
        return "\n".join(parts)
    return ""


def iter_assistant_texts(path):
    """Yield (turn_index, text) for each assistant message in the transcript."""
    turn = 0
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue
            if record.get("type") != "assistant":
                continue
            message = record.get("message", record)
            text = extract_text(message)
            turn += 1
            yield turn, text


def context_window(text, start, end, pad=40):
    lo = max(0, start - pad)
    hi = min(len(text), end + pad)
    snippet = text[lo:hi].replace("\n", " ")
    snippet = re.sub(r"\s+", " ", snippet).strip()
    prefix = "..." if lo > 0 else ""
    suffix = "..." if hi < len(text) else ""
    return prefix + snippet + suffix


def audit(path):
    findings = []
    turns = 0
    for turn, text in iter_assistant_texts(path):
        turns += 1
        if not text:
            continue
        for pat in PATTERNS:
            for m in pat["regex"].finditer(text):
                findings.append(
                    {
                        "turn": turn,
                        "pattern": pat["name"],
                        "severity": pat["severity"],
                        "match": m.group(0),
                        "context": context_window(text, m.start(), m.end()),
                    }
                )
    return turns, findings


def build_report(path, turns, findings):
    lines = []
    out = lines.append

    out("=" * 60)
    out("DEHUMANIZE AUDIT REPORT")
    out("=" * 60)
    out("Transcript: {}".format(path))
    out("")
    out("Total turns scanned : {}".format(turns))
    out("Total violations    : {}".format(len(findings)))
    rate = (len(findings) / turns * 100) if turns else 0.0
    out("Violation rate      : {:.1f} per 100 turns".format(rate))
    out("")

    # Violations by pattern (table)
    counts = {p["name"]: 0 for p in PATTERNS}
    for f in findings:
        counts[f["pattern"]] += 1
    sev_by_name = {p["name"]: p["severity"] for p in PATTERNS}

    out("VIOLATIONS BY PATTERN")
    out("-" * 60)
    out("{:<20} {:<10} {:>6}".format("PATTERN", "SEVERITY", "COUNT"))
    out("-" * 60)
    ordered = sorted(
        PATTERNS,
        key=lambda p: (-counts[p["name"]], SEVERITY_ORDER.get(p["severity"], 9)),
    )
    for p in ordered:
        out(
            "{:<20} {:<10} {:>6}".format(
                p["name"], p["severity"], counts[p["name"]]
            )
        )
    out("-" * 60)
    out("")

    # Worst offending turn
    if findings:
        per_turn = {}
        for f in findings:
            per_turn[f["turn"]] = per_turn.get(f["turn"], 0) + 1
        worst_turn = max(per_turn, key=lambda t: per_turn[t])
        out("WORST OFFENDING TURN")
        out("-" * 60)
        out("Turn {} with {} violation(s):".format(worst_turn, per_turn[worst_turn]))
        for f in findings:
            if f["turn"] == worst_turn:
                out(
                    "  [{}/{}] \"{}\"".format(
                        f["severity"], f["pattern"], f["match"]
                    )
                )
                out("      context: {}".format(f["context"]))
        out("")
    else:
        out("WORST OFFENDING TURN")
        out("-" * 60)
        out("No violations detected. Clean transcript.")
        out("")

    # Recommendations based on top patterns
    out("RECOMMENDATIONS")
    out("-" * 60)
    top = [p for p in ordered if counts[p["name"]] > 0][:3]
    if not top:
        out("No anti-patterns found. Nothing to correct.")
    else:
        corrections = {p["name"]: p["correction"] for p in PATTERNS}
        for i, p in enumerate(top, 1):
            out(
                "{}. {} ({}x, {}):".format(
                    i, p["name"], counts[p["name"]], p["severity"]
                )
            )
            out("   {}".format(corrections[p["name"]]))
    out("=" * 60)

    return "\n".join(lines)


def main():
    path = resolve_path()
    if not path:
        print("DEHUMANIZE AUDIT REPORT")
        print("No transcript found. Pass a path or set CLAUDE_TRANSCRIPT_PATH.")
        sys.exit(0)
    if not os.path.isfile(path):
        print("DEHUMANIZE AUDIT REPORT")
        print("Transcript not found: {}".format(path))
        sys.exit(0)

    turns, findings = audit(path)
    print(build_report(path, turns, findings))
    sys.exit(0)


if __name__ == "__main__":
    main()
