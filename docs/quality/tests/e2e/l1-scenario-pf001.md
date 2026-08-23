# Lane: L1

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `L1` · Defined in: `tests/tools/lanes.txt` · Group: CPU

L1 is the separable baseline of the regression pair. It stages the separable
demonstration model, runs the whole constellation, and asserts a known-good
objective. Green validates the plumbing: eight processes discover each other,
the master solves, and every subproblem service takes part.

## Scenario

The harness stages private copies of the seven service directories, installs
the separable model as the application's active model, and launches an isolated
repository process followed by the register, overall-problem, master and three
subproblem services, then the application. Nothing runs in the tracked
directories: the repository's service directories are read-only inputs, because
the services write generated models, data and a registry database into their
working directories at run time.

Each service is gated on its own startup banner, and each registrant
additionally on the cumulative count of registrations recorded by the register
service — the banner alone is a weak gate, printed before any transport setup,
while the registration count is the first output proving a service is
discoverable. The application is gated on its register-service round trip, then
publishes the problem itself; completion is the master's own solution marker,
bounded by a timeout.

The assertions read the master's output: the objective is 4.75 as a hard check,
the status must be optimal, and the generated-variable count must show that
distributed columns really entered the master. Participation is asserted
separately at the far end of the wire, because the coordinator prices an
unanswered block locally and that fallback reproduces the right answer exactly
— so each subproblem service must have published its solution the expected
number of times, with zero and a mere disagreement reported as different
failures.

This lane drives the legacy demonstration path — the application is launched
bare and its built-in graph solves — so no problem-definition document is
submitted and the lane seeds no row in the proven-combination table.

## Running

```bash
tests/e2e/run_scenario.sh --scenario pf001
```

Also registered as the CTest name `pf_e2e_pf001`. Add `--keep` to retain the
working directory on success; failures always retain it. The assertions alone
are `tests/e2e/assert_scenario.sh <workdir> pf001`.
