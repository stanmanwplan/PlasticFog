# Lane: L2

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `L2` · Defined in: `tests/tools/lanes.txt` · Group: CPU

L2 is the load-bearing half of the regression pair: the contention scenario,
whose objective is unreachable by independent per-vehicle solves. Green is the
one assertion in this pair that distinguishes working distributed coordination
from a plausible imitation of it.

## Scenario

The harness stages private copies of the seven service directories, installs
the contention model as the application's active model, and launches the
isolated repository process, the register, overall-problem, master and three
subproblem services, then the application. The tracked directories are
read-only inputs throughout.

Readiness is gated twice over: each service on its own startup banner, and each
registrant on the register service's cumulative registration count, because a
banner is printed before any transport setup and proves nothing about
discoverability. The application is gated on its register-service round trip
and then publishes the problem without operator input; completion is the
master's own solution marker.

The assertions read the master's output: the objective is 5.33 as a hard check,
the status must be optimal, the generated-variable count must show distributed
columns entering the master, and the three path lengths must match their
known-good values within a small tolerance that absorbs floating-point printing
noise. Participation is asserted at the far end of the wire as an exact count
per subproblem service, because a run has been observed reporting the right
objective, the right status and the right path lengths while every price
publication was failing and no subproblem had answered at all. That the
participation gate can itself fail is provable on demand through a self-test
mode.

Like its sibling, this lane drives the legacy demonstration path — the
application launched bare, its built-in graph solving — so no problem-definition
document is submitted and it seeds no row in the proven-combination table.

## Running

```bash
tests/e2e/run_scenario.sh --scenario pf002
```

Also registered as the CTest name `pf_e2e_pf002`. Add `--keep` to retain the
working directory on success; failures always retain it. The assertions alone
are `tests/e2e/assert_scenario.sh <workdir> pf002`.
