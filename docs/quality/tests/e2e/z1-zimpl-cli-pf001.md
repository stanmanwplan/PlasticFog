# Lane: Z1

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `Z1` · Defined in: `tests/tools/lanes.txt` · Group: CPU

Z1 repeats the separable baseline with model compilation switched to the Zimpl
command-line backend instead of the in-process one. Green means the two
compilation paths produce a model that solves to the same answer through the
same constellation.

## Scenario

The lane is the separable scenario, unchanged: the same staging, the same eight
processes, the same readiness gates, the same assertions on the objective, the
status, the generated-variable count and per-service participation. The only
difference is an environment variable selecting the backend, applied to the
invocation rather than exported, which the matrix driver sets when it reads this
lane's entry.

That single difference is what makes the lane worth running. Compiling in
process, inside a long-lived service, is the arrangement the rest of the suite
exercises, and a unit test already pins the request digest, the refusals and the
state reset that arrangement requires. What no unit test can show is that a
whole distributed campaign reaches the same answer when the compilation happens
in a child process instead. A byte-level comparison of the two backends' outputs
belongs to the parity harness; this lane is the end-to-end half of the same
question.

Like the two scenario lanes it repeats, Z1 drives the legacy demonstration
path — the application launched bare, its built-in graph solving — so no
problem-definition document is submitted and the lane seeds no row in the
proven-combination table.

## Running

```bash
env PF_ZIMPL_BACKEND=cli tests/e2e/run_scenario.sh --scenario pf001
```

Accepts every option the scenario runner accepts. Failures always retain the
working directory; the assertions alone are
`tests/e2e/assert_scenario.sh <workdir> pf001`.
