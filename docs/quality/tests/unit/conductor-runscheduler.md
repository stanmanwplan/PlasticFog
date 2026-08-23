# pf_Conductor_RunScheduler_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_Conductor_RunScheduler_Tests.cpp` · CTest: `pf_Conductor_RunScheduler` · Labels: `unit;fast;public`

The run scheduler decides whether a campaign runs now, waits, skips a slot or
stops. It takes the current instant as an argument, so this test constructs
cadences and overruns exactly rather than waiting them out; nothing here starts
a process or opens a socket.

## What it verifies

- A single-run campaign runs once and then stops with a reason naming the mode
  rather than a count; an absent run specification behaves identically.
- A counted campaign runs exactly its count, skips nothing, starts at its own
  origin with no initial wait, and stops with a reason distinguishing a reached
  count from a run ceiling.
- Interval slots are measured from the origin, not from the previous run's end:
  a tick half a slot in is not due, and the reported wait is the remainder of
  the slot rather than a whole interval.
- The two overlap policies reach different decisions on the identical overrun.
  Under one a missed slot is recorded as a skip — counted, never silently
  caught up — and the campaign resumes on the current slot; under the other the
  missed slot runs and the decision names which tick is owed.
- A continuous campaign stops at its maximum-runs ceiling with the
  corresponding reason. When two limits apply, the smaller one is named, so a
  stated limit is never silently ignored.
- Consecutive failures stop a campaign and are reported as such rather than as
  a finished count; a success resets the counter. An exhausted time budget and
  an external stop are honoured, the latter carrying its reason verbatim.
- Warm start is cold on the first run and on a changed revision whatever the
  policy says, carries on a repeat of the same revision, and stays cold
  throughout under the cold policy.
- Asking the same instant twice gives an identical decision, advances nothing,
  and every decision states its reason.

## Running

```bash
ctest --test-dir build -R '^pf_Conductor_RunScheduler$' --output-on-failure
```

The target is built when the tree is configured with either
`-DPF_BUILD_UNIT_TESTS=ON` or `-DPF_BUILD_PROBLEM_INPUT_TESTS=ON`.
