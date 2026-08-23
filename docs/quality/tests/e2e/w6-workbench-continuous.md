# Lane: W6

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `W6` · Defined in: `tests/tools/lanes.txt` · Group: CPU

W6 is the continuous-campaign lane: a schedule bounded by a maximum run count,
with one failing run injected deliberately. Green means the ceiling stopped the
campaign and the consecutive-failure accounting was observed rising and
resetting rather than merely asserted.

## Scenario

A continuous run specification has no natural end, so the lane bounds it with a
maximum run count and asserts the campaign stopped for that reason rather than
for any other. Stop reasons are distinguishable in this runtime — a reached
ceiling and a run of consecutive failures are reported differently — so
asserting which one fired is a real check.

One run is made to fail on purpose, and it sits in the middle of the campaign
rather than at its end. That placement is what makes the failure counter
observable in both directions: it rises when the failing run completes and
resets when the next successful run does, which is the behaviour that keeps a
campaign that recovered from being treated as failing. Observing the counter
move is stronger than asserting a final value, which a scheduler that never
incremented it at all could also satisfy.

Like the other campaign lane, this one runs against the constellation the
harness starts rather than a spawned one, for the same structural reason.

## Running

```bash
tests/e2e/run_workbench.sh --scenario wb-continuous
```

Failures always retain the working directory; `--keep` retains it on success.
