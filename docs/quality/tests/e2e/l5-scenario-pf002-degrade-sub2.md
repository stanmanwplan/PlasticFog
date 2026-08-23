# Lane: L5

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `L5` · Defined in: `tests/tools/lanes.txt` · Group: CPU

L5 is the fault-injection lane: the contention scenario run with one subproblem
service killed before the solve begins. Green means the run completed, the loss
was recorded rather than silently absorbed, and the harness refused to let a
degraded run stand in for a healthy one.

## Scenario

The whole constellation is launched with a shortened subproblem reply timeout,
applied per service rather than exported into the harness's own environment, so
a strict run in the same shell afterwards is unaffected. A watcher blocks on the
target service's output and signals it as soon as it has registered — before the
application triggers the solve — so it answers nothing at all.

That timing is deliberate, and the script says why. Killing on the first reply
exercises loss mid-solve against a service that demonstrably worked, but batch
pricing made it unreliable: the pricing phase is short enough that the signal
often lands after the last round, and the "degraded" run is then not degraded at
all — it passes every strict check while asserting nothing. A fault injector
that silently injects nothing is worse than one explicit about when it fires.
Both ends of the watcher are bounded, so no descendant outlives the run.

The coordinator responds to the missing replies by pricing that block locally,
so the solve still completes and still reports optimal — which is exactly why a
separate assertion profile exists. Under it the objective is asserted present
and never compared, because a degraded run must never count as a reproduction of
the known-good value; optimal status stays a hard check; the generated-variable
count is reported rather than asserted, since a locally priced block makes it
measure something else; and a transport-timeout record naming the killed
service's identifier is a hard check read from the master's error stream. A
further assertion requires the failure to have reached the application as data,
not merely the master's stderr.

## Running

```bash
tests/e2e/run_scenario.sh --scenario pf002 --degrade sub2 --degrade-mode pre-solve
```

The killed service is recorded in the working directory so a preserved run stays
self-describing; the assertions alone are
`tests/e2e/assert_scenario.sh <workdir> pf002 degraded`.
