# Intensive eval summary — dehumanize

**Date:** 2026-07-17  
**Command:** `bash evals/run_intensive.sh`  
**Corpus:** `~/.claude/projects` (1756 JSONL sessions)  
**Detector:** `hooks/lib/patterns.sh` + `scripts/audit.py` (lockstep)  

## KPI gates — PASS

| Metric | Value | Gate |
|--------|------:|------|
| sessions_scanned | 1756 | — |
| sessions_with_assistant | 1084 | — |
| assistant_turns | 20639 | ≥200 |
| total_hits | 250 | ≥1 |
| hit_rate_turns | 1.21% | &lt;50% |
| denylist probes | PASS | required |
| must-hit probes | PASS | required |

## Hits by pattern (post FP-fix)

| Pattern | Hits |
|---------|-----:|
| sequential_framing | 201 |
| human_time | 18 |
| human_capacity | 14 |
| ask_for_access | 11 |
| emotional_labor | 6 |

## FP fixes from this eval pass

Corpus showed two **critical** false positives in `ask_for_access`:

1. Bare **`I can't see`** matched metaphors (“I can't see the bug fire”).  
   → Now requires screen/display/monitor/desktop/window/ui object.  
2. Bare **`please send`** matched Anthropic **“please send feedback via /feedback”**.  
   → `please send` now requires file/log/output/screenshot object.

After fix: ask_for_access **21 → 11** hits; denylist expanded.

## Sequential volume

`sequential_framing` is the bulk (mostly `then I'll`, `let me first`, `one at a time`).  
That matches the product goal (fan-out culture) but is noisier than time/paste. Keep high severity; consider multi-phrase stacking later if inject floods.

## Artifacts

- `evals/reports/latest.json`  
- `evals/fixtures/sample_hits.jsonl`  
- `evals/corpus_eval.py` / `evals/run_intensive.sh` — new harness  
