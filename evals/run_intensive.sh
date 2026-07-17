#!/usr/bin/env bash
# Intensive dehumanize eval: unit probes + full corpus scan + KPI gates.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

mkdir -p evals/reports evals/fixtures

echo "== pattern unit probes =="
bash tests/test_patterns.sh

echo "== plugin validate =="
python3 .ci/validate_plugin.py .

echo "== smoke =="
bash tests/smoke.sh

echo "== full corpus scan (may take a few minutes) =="
python3 evals/corpus_eval.py \
  --root "${HOME}/.claude/projects" \
  --limit 0 \
  --fixtures evals/fixtures/sample_hits.jsonl \
  --top 40 \
  --json > evals/reports/latest.json

python3 -c "
import json
from pathlib import Path
r = json.loads(Path('evals/reports/latest.json').read_text())
s = r['summary']
print('INTENSIVE EVAL SUMMARY')
for k, v in s.items():
    if k.endswith('_failures') and not v:
        continue
    print(f'  {k}: {v}')
assert s['assistant_turns'] >= 200, f'corpus too small: {s[\"assistant_turns\"]} turns'
assert s['denylist_ok'] is True, f'denylist failed: {s.get(\"denylist_failures\")}'
assert s['must_hit_ok'] is True, f'must-hit failed: {s.get(\"must_hit_failures\")}'
# Sanity: we should see *some* real corpus signal without flooding
assert s['total_hits'] >= 1, 'zero corpus hits — detector may be broken'
assert s['hit_rate_turns'] < 0.5, f'hit rate suspiciously high (FP flood?): {s[\"hit_rate_turns\"]}'
print('KPI gates: PASS')
"

echo "== done =="
