# Intensive eval summary — dehumanize

**Date:** 2026-07-17  
**Command:** `python3 evals/corpus_eval.py --root ~/.claude/projects --limit 0 --json`

## Before / after this lap

| Metric | After first eval harness | After 10× quality lap | Δ |
|--------|-------------------------:|----------------------:|---|
| total_hits | 250 | **112** | −55% (noise cut) |
| sequential_framing | 201 | **63** | **~3.2× cleaner** |
| ask_for_access | 21 → 11 (FP fix) then **11** | stable true positives |
| hit_rate_turns | 1.21% | **0.54%** | less inject spam |
| denylist / must-hit | PASS | PASS | |

## Product changes this lap
1. Bare `I can't see` → require screen/display object  
2. Bare `please send` → require file/log/output object  
3. Drop bare `then I'll` / bare `one by one` from sequential (keep first/start/running-them-one-by-one)

## KPI gates — PASS
assistant_turns 20639 ≥200 · denylist/must-hit PASS · hit_rate < 50%
