# Lane: W2

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `W2` · Defined in: `tests/tools/lanes.txt` · Group: CPU

W2 is the spawn lane: the harness starts no constellation at all. The
deployment verb spawns everything — the repository process, the register and
overall-problem services, the master and its three subproblem services — and the
stop verb drains exactly what it started.

## Scenario

Where the basic Workbench lane runs the front end over a constellation the
harness stages, this one hands that job to the supervisor. Nothing is running
when the lane begins; the document's placements ask for services to be spawned,
and the deployment brings them up in order, each gated on its own readiness
criterion rather than on a delay.

Stopping is asserted as precisely as starting. The supervisor drains the
processes it started and only those, matching each against a multi-part identity
so a recycled process identifier cannot be mistaken for the one it recorded.

The conductor is launched in the foreground and tracked like any other process,
the catalog is a scratch database under the run directory, and the control
socket is a short per-run path — short because the address-family limit on
socket paths is smaller than a deep checkout path, a failure the harness now
checks for up front and reports with the byte count rather than discovering at
bind time.

This lane is one of three that seed a placement row in the proven-combination
table: it is the one that proves a spawned deployment of a flat price-directed
problem end to end.

## Running

```bash
tests/e2e/run_workbench.sh --scenario wb-spawn
```

Failures always retain the working directory; `--keep` retains it on success.
