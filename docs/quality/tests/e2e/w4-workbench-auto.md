# Lane: W4

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `W4` · Defined in: `tests/tools/lanes.txt` · Group: CPU

W4 is the automatic-placement lane. The document's bindings list two placement
arms in order — discover first, spawn second — against an empty registry, so the
first arm fails and the second fires. Green means the fallback chain was
followed in the order the document stated and the failure was recorded rather
than merely implied.

## Scenario

Nothing is running when the lane begins and no service is registered, so the
query arm cannot resolve. The supervisor moves to the spawn arm and brings the
constellation up itself.

The lane's distinguishing assertion is that the query arm's reason is recorded.
An automatic binding that silently fell through to spawning would be
indistinguishable from one that never tried to discover at all, and an operator
reading the deployment afterwards would have no way to tell whether discovery
was attempted and failed or skipped. Order matters as much as outcome: the arms
are recorded in the document's order, because the order is the entire meaning of
the list.

The rest follows the Workbench lane's discipline — the conductor tracked like a
service, the catalog a scratch database under the run directory, the control
socket a short per-run path.

This lane seeds the automatic-placement row in the proven-combination table.

## Running

```bash
tests/e2e/run_workbench.sh --scenario wb-auto
```

Failures always retain the working directory; `--keep` retains it on success.
