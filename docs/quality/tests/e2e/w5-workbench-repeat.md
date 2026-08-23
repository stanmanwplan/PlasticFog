# Lane: W5

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `W5` · Defined in: `tests/tools/lanes.txt` · Group: CPU

W5 is the campaign lane. It runs a counted schedule and then an interval one on
the same constellation, and green means the scheduler ran the stated number of
solves, each reached the same answer, and warm start was carried between them.

## Scenario

The lane submits a run specification rather than a single solve. The first
campaign is counted, running a fixed number of times with warm start carried
across runs; the second runs on a short interval. Each campaign records one run
row per execution, and the assertions check three things together: that the
expected number of rows exists per campaign, that the objective is identical on
every run, and that the runs which carried warm start are marked as having
reused the cached artifacts. That last check is the standing guard — without it,
"warm start carried" would be a claim about intent rather than a measurement,
and a campaign that silently recompiled everything each time would look
identical.

The campaign lanes run against the constellation the harness starts rather than
a spawned one, and the reason is structural: this build stages one master
directory, so a nested topology cannot be spawned at all, and the fixture the
results oracle needs is the nested one, because only a mid holds an envelope of
its own. What spawning would add is who started the processes, and that is what
the spawn and log lanes already prove.

## Running

```bash
tests/e2e/run_workbench.sh --scenario wb-repeat
```

Failures always retain the working directory; `--keep` retains it on success.
