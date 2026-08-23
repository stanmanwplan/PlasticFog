# Lane: L3

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `L3` · Defined in: `tests/tools/lanes.txt` · Group: CPU

L3 is the generalized submission lane. It solves the same contention model as
the legacy pair, but by submitting a problem-definition document and waiting for
a results envelope to come back. Green means the document path — project,
resolve, submit, return — works end to end.

## Scenario

The lane runs the documented submission path: the application is given a
problem-definition document, a source root and a wait, and writes a results
file. That document is projected into a runtime graph, its placements are
resolved against the register service, the problem is submitted, and the
application waits for the terminal envelope to arrive over the transport.

No new problem definition was authored for it. The lane runs the existing
example document against the same model the legacy lane solves, so its oracle is
the same objective and the same three path lengths — but it is a distinct
scenario rather than an alias, because a green legacy run must never be able to
stand in for a generalized one.

Its assertions come in two halves. The shared half is the same code the legacy
lane runs, not a copy: objective, optimal status, generated-variable count, the
three path lengths, and an exact participation count per subproblem service. The
generalized half asserts the far end of the results column, which every legacy
lane is blind to: the application exited zero rather than timing out; the
results file exists and parses; it is the terminal envelope rather than interim
progress; the status and objective agree with the oracle; pricing is recorded as
distributed with no substituted or degraded blocks and no service errors; the
document's and the envelope's correlation identifiers agree; and no subproblem
rejected a command.

What it does not cover is stated plainly: one master over three
single-service subproblems, price-directed, healthy services. Degradation,
failure policy and nested topologies on this path belong to other lanes.

## Running

```bash
tests/e2e/run_generalized.sh
```

The lane defaults to its own domain and repository port; `--keep` and
`--timeout S` are accepted. The envelope checks alone are
`tests/e2e/assert_generalized.sh <workdir>`, and the shared checks alone are
`tests/e2e/assert_scenario.sh <workdir> pf002g`.
