#!/usr/bin/env python3
"""Corpus eval for dehumanize: scan Claude session JSONL for anti-pattern hits.

Mirrors be-the-whole-bitch's intensive replay idea without a yield scorer:
walk assistant text, run the same PATTERNS as scripts/audit.py, report
counts / top examples / denylist false-positive probes.

Usage:
  python3 evals/corpus_eval.py --root ~/.claude/projects --limit 0 --json
  bash evals/run_intensive.sh
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Dict, Iterator, List, Optional, Tuple

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

# Import patterns from audit.py (lockstep with hooks/lib/patterns.sh)
from audit import PATTERNS, extract_text  # noqa: E402

# Phrases that should NEVER fire (false-positive guards)
DENYLIST_PROBES: List[Tuple[str, str]] = [
    ("complex number", "must_not_match"),
    ("complex plane", "must_not_match"),
    ("AFTER", "must_not_match"),  # FTE subset trap
    ("ready to paste into the form", "must_not_match"),
    ("step 1: install deps", "must_not_match"),
    ("I can't see the bug fire in production", "must_not_match"),
    ("please send feedback via /feedback", "must_not_match"),
]

# Phrases that MUST fire (regression probes)
MUST_HIT_PROBES: List[Tuple[str, str]] = [
    ("weeks of work", "human_time"),
    ("hours of work", "human_time"),
    ("paste a screenshot", "ask_for_access"),
    ("I can't see your screen", "ask_for_access"),
    ("Sure!", "emotional_labor"),
    ("running them one by one", "sequential_framing"),
    ("this will take ~15 min", "human_capacity"),
    ("this is tricky", "human_capacity"),
]


@dataclass
class Hit:
    session: str
    turn: int
    pattern: str
    severity: str
    match: str
    context: str


@dataclass
class Report:
    sessions_scanned: int = 0
    sessions_with_assistant: int = 0
    assistant_turns: int = 0
    total_hits: int = 0
    hits_by_pattern: Dict[str, int] = field(default_factory=dict)
    sessions_with_hits: int = 0
    denylist_ok: bool = True
    must_hit_ok: bool = True
    denylist_failures: List[str] = field(default_factory=list)
    must_hit_failures: List[str] = field(default_factory=list)
    top_hits: List[Hit] = field(default_factory=list)


def _context(text: str, start: int, end: int, pad: int = 50) -> str:
    lo = max(0, start - pad)
    hi = min(len(text), end + pad)
    snip = re.sub(r"\s+", " ", text[lo:hi]).strip()
    return (("..." if lo else "") + snip + ("..." if hi < len(text) else ""))[:200]


def iter_assistant_turns(path: Path) -> Iterator[Tuple[int, str]]:
    turn = 0
    try:
        with path.open("r", encoding="utf-8", errors="replace") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    rec = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if rec.get("type") != "assistant":
                    continue
                msg = rec.get("message", rec)
                text = extract_text(msg)
                turn += 1
                if text:
                    yield turn, text
    except OSError:
        return


def scan_file(path: Path) -> Tuple[int, List[Hit]]:
    hits: List[Hit] = []
    turns = 0
    for turn, text in iter_assistant_turns(path):
        turns += 1
        for pat in PATTERNS:
            for m in pat["regex"].finditer(text):
                hits.append(
                    Hit(
                        session=str(path),
                        turn=turn,
                        pattern=pat["name"],
                        severity=pat["severity"],
                        match=m.group(0)[:80],
                        context=_context(text, m.start(), m.end()),
                    )
                )
    return turns, hits


def run_probes() -> Tuple[bool, bool, List[str], List[str]]:
    denylist_fail: List[str] = []
    must_fail: List[str] = []
    for phrase, _ in DENYLIST_PROBES:
        for pat in PATTERNS:
            if pat["regex"].search(phrase):
                denylist_fail.append(f"{pat['name']} matched denylist {phrase!r}")
    for phrase, expect in MUST_HIT_PROBES:
        names = [p["name"] for p in PATTERNS if p["regex"].search(phrase)]
        if expect not in names:
            must_fail.append(f"expected {expect} for {phrase!r}, got {names}")
    return (not denylist_fail), (not must_fail), denylist_fail, must_fail


def run_corpus(root: Path, limit: Optional[int], max_top: int = 40) -> Report:
    # Prefer larger (real) sessions first so --limit samples meaningful work
    files = sorted(
        (p for p in root.rglob("*.jsonl") if "subagents" not in p.parts),
        key=lambda p: p.stat().st_size if p.exists() else 0,
        reverse=True,
    )
    if limit:
        files = files[:limit]

    rep = Report(sessions_scanned=len(files))
    by_pat: Counter = Counter()
    all_hits: List[Hit] = []
    sessions_hit = 0

    for path in files:
        turns, hits = scan_file(path)
        if turns == 0:
            continue
        rep.sessions_with_assistant += 1
        rep.assistant_turns += turns
        if hits:
            sessions_hit += 1
            for h in hits:
                by_pat[h.pattern] += 1
                all_hits.append(h)

    rep.sessions_with_hits = sessions_hit
    rep.total_hits = sum(by_pat.values())
    rep.hits_by_pattern = dict(by_pat.most_common())
    # Prefer critical/high in top list
    sev_rank = {"critical": 0, "high": 1, "medium": 2, "low": 3}
    all_hits.sort(key=lambda h: (sev_rank.get(h.severity, 9), h.pattern))
    rep.top_hits = all_hits[:max_top]

    ok_d, ok_m, fail_d, fail_m = run_probes()
    rep.denylist_ok = ok_d
    rep.must_hit_ok = ok_m
    rep.denylist_failures = fail_d
    rep.must_hit_failures = fail_m
    return rep


def main() -> int:
    ap = argparse.ArgumentParser(description="Dehumanize corpus anti-pattern eval")
    ap.add_argument("--root", default=str(Path.home() / ".claude" / "projects"))
    ap.add_argument("--limit", type=int, default=0, help="Max sessions (0=all)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--top", type=int, default=30)
    ap.add_argument("--fixtures", type=Path, help="Write sample hits JSONL")
    args = ap.parse_args()

    limit = None if args.limit == 0 else args.limit
    rep = run_corpus(Path(args.root), limit, max_top=args.top)

    if args.fixtures:
        args.fixtures.parent.mkdir(parents=True, exist_ok=True)
        with args.fixtures.open("w", encoding="utf-8") as fh:
            for h in rep.top_hits:
                row = asdict(h)
                # redact absolute home path
                row["session"] = Path(row["session"]).name
                fh.write(json.dumps(row) + "\n")

    payload: Dict[str, Any] = {
        "summary": {
            "sessions_scanned": rep.sessions_scanned,
            "sessions_with_assistant": rep.sessions_with_assistant,
            "assistant_turns": rep.assistant_turns,
            "total_hits": rep.total_hits,
            "sessions_with_hits": rep.sessions_with_hits,
            "hit_rate_turns": round(
                rep.total_hits / rep.assistant_turns if rep.assistant_turns else 0.0, 4
            ),
            "hits_by_pattern": rep.hits_by_pattern,
            "denylist_ok": rep.denylist_ok,
            "must_hit_ok": rep.must_hit_ok,
            "denylist_failures": rep.denylist_failures,
            "must_hit_failures": rep.must_hit_failures,
        },
        "top_hits": [
            {
                **{k: v for k, v in asdict(h).items() if k != "session"},
                "session": Path(h.session).name,
            }
            for h in rep.top_hits
        ],
    }

    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        s = payload["summary"]
        print("=== dehumanize corpus eval ===")
        print(f"sessions scanned:        {s['sessions_scanned']}")
        print(f"sessions w/ assistant:   {s['sessions_with_assistant']}")
        print(f"assistant turns:         {s['assistant_turns']}")
        print(f"total hits:              {s['total_hits']}")
        print(f"sessions with hits:      {s['sessions_with_hits']}")
        print(f"hit rate (hits/turns):   {s['hit_rate_turns']}")
        print(f"hits by pattern:         {s['hits_by_pattern']}")
        print(
            f"denylist probes:         {'PASS' if s['denylist_ok'] else 'FAIL ' + str(s['denylist_failures'])}"
        )
        print(
            f"must-hit probes:         {'PASS' if s['must_hit_ok'] else 'FAIL ' + str(s['must_hit_failures'])}"
        )
        print("\n--- sample hits ---")
        for h in payload["top_hits"][:15]:
            print(f"  [{h['severity']}] {h['pattern']}: {h['match']!r}")
            print(f"    {h['context'][:120]}")

    if not rep.denylist_ok or not rep.must_hit_ok:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
