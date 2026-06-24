# dehumanize — Plugin Status

**Plugin name:** dehumanize

## Anti-patterns

5 patterns are detected and corrected:

1. Asking the user to paste files instead of reading them directly.
2. Serializing work that could be fanned out in parallel.
3. Emitting human time units (e.g. "give me a few hours").
4. Emotional filler and apologetic padding.
5. Framing tasks as "this is complex" instead of computing and acting.

## Hooks

- **SessionStart** — primes the session with the dehumanize directive.
- **Stop** — audits the completed turn against the 5 anti-patterns.
- **UserPromptSubmit** — injects the directive on every user prompt.

## Commands

- **audit** — scan a session for anti-pattern hits.
- **status** — report plugin state and counters.
- **patterns** — list the 5 anti-patterns and their detectors.
- **fix** — rewrite flagged output to remove anti-patterns.

## JSONL extraction

The last assistant text is pulled from a session JSONL file:

```bash
LAST_ASST_TEXT=$(python3 -c 'import json,sys
t=""
for line in open(sys.argv[1]):
    try: o=json.loa
```

## Session log backtesting

Backtested against **6,300 files** across **464 projects**.

## User prompt injection

The directive injected on every prompt:

> You are AI, not a person. Access files directly, never ask for them. Fan out in parallel, never serialize. No human time units, no emotional filler, no "this is complex." Compute and act now.

## Next steps

- git push
- register in 88plug marketplace
- deepwiki index
- set GitHub topics
