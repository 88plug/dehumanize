# Backtesting

The dehumanize pattern set was validated by replaying it against real Claude Code history: **6,300 session JSONL files** drawn from **464 project directories** on disk. Each session was scanned for every pattern, and the matches were ranked by severity and frequency to confirm the patterns fire on genuine output rather than synthetic test cases.

## Findings

| Project | Top pattern | Total violations | Best example |
| --- | --- | --- | --- |
| benchie | `human_time` | 1 | "100x — major product features (weeks of work, real UX wins)" |
| farmgpu-shepherd (656ebd9d session) | `human_time` | 5 | "sprint" used as a planning/time unit, all from the single largest file |
| scientific-method-plugin | `emotional_labor` | 1 | "I'm glad to do all the prep today so it's a 5-minute job later" |

## Representative violations

!!! warning "human_time — benchie"
    > ## 100x — major product features (weeks of work, real UX wins) ### SLO-driven recommendation pipeline

    Effort is sized in "weeks of work," a human-time unit. The model has no work-weeks; the framing imports a human cost model that does not apply.

!!! warning "human_time — farmgpu-shepherd"
    All 5 violations in this session are the word **"sprint"** used as a planning or time-framing unit, and all 5 come from the single largest file. "Sprint" is a human team-cadence concept that leaks into planning text.

!!! warning "emotional_labor — scientific-method-plugin"
    > I'm glad to do all the prep today so it's a 5-minute job later

    "I'm glad to" claims a feeling and willingness on the model's behalf — emotional labor that performs eagerness instead of stating the plan.

## What the results show

- The two highest-signal patterns — `human_time` and `emotional_labor` — both fired on real, unprompted output, confirming they target tells that occur naturally rather than contrived strings.
- `human_time` clustered: in the farmgpu-shepherd session all five hits came from one file, which is the expected shape for a planning document that adopts a team-cadence vocabulary throughout.
- Total counts per project are low, which is the intended outcome — these are tells, not pervasive errors, so a small precise pattern set catches them without flooding the user with false positives.

!!! note
    These results reflect a point-in-time scan. Re-run `/dehumanize:audit` on your own sessions to see how the patterns behave against your output.
