# Lane: L8

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `L8` · Defined in: `tests/tools/lanes.txt` · Group: CPU

L8 is the resource-directed lane: a Benders decomposition of a robot cell, one
master over two recourse children. Green means cuts of both families were
installed and the campaign converged to an independently derived optimum.

## Scenario

The topology is flat — one master service and two subproblem services — and the
paradigm and assertion set share nothing with the price-directed lanes, which is
why this is its own harness rather than a flag on another. The assertions are
about cuts, an epigraph variable and a paradigm provenance field, none of which
exist on the price path.

The oracle is 40.0, and it is independent of the runtime: a hand-flattened
monolith of the same instance, compiled with the vendored modelling frontend and
solved with a vendored solver, cross-checked with a second one. A separate
standalone loop reached the same value against a hand enumeration, which is a
cross-check on the oracle rather than the oracle itself.

The cut assertions are the point. A Benders master that received no cuts at all
would solve its own unconstrained relaxation — every slot at zero, the epigraph
variable at its lower bound — and report that as optimal. A plain objective
check is therefore not evidence that the decomposition ran. The lane requires at
least one feasibility cut and at least one optimality cut, because the two
families answer different questions: without a feasibility cut the master would
stop at the all-zero allocation with an objective of zero, and without an
optimality cut the epigraph variable would never leave zero and the recourse
would be free.

Every service is launched with its environment applied as a per-process prefix
rather than exported into the harness's shell, so a later run in the same shell
is unaffected.

## Running

```bash
tests/e2e/run_resource.sh
```

Accepts `--domain N`, `--inforepo-port P`, `--timeout S`, `--workdir DIR` and
`--keep`; failures always retain the working directory. The assertions alone are
`tests/e2e/assert_resource.sh <workdir>`.
