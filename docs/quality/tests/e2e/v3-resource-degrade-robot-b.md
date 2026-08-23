# Lane: V3

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `V3` · Defined in: `tests/tools/lanes.txt` · Group: CPU

V3 is the resource-directed fault lane: one recourse child is killed before the
first round, so its master never receives a cut. Green means the run failed
loudly instead of converging to a number.

## Scenario

The constellation is the same flat Benders cell the healthy lane runs — one
master over two recourse children — launched with a shortened subproblem reply
deadline applied as a per-process prefix rather than exported into the harness's
shell. The named robot is killed before the first round, and its directory,
service identifier and process identifier are all recorded in the run's summary,
so a preserved working directory stays self-describing.

The outcome asserted is abort, not degradation. Under the resource-directed
failure rule, substitution is invalid for a recourse child: there is no
surrogate for a cut the way there is for a missing column, because a cut is a
bound derived from one specific allocation and a master with no copy of the
recourse model cannot manufacture one. The lane therefore asserts the abort
outcome in place of the converged one, and the objective the healthy lane pins
is deliberately not asserted here — asserting it would be asserting the
confidently wrong answer the policy exists to refuse.

Either robot can be named; the lane runs under its own scenario name so a
degraded run's working directory is never mistaken for a healthy one's.

## Running

```bash
tests/e2e/run_resource.sh --degrade robot_b
```

Accepts the same `--domain`, `--inforepo-port`, `--timeout`, `--workdir` and
`--keep` options as the healthy lane. The assertions alone are
`tests/e2e/assert_resource.sh <workdir> degrade <robot>`.
