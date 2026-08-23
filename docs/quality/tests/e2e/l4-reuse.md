# Lane: L4

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `L4` · Defined in: `tests/tools/lanes.txt` · Group: CPU

L4 is the constellation-reuse lane. One set of service processes serves two
sequential solves of two different scenarios, and green means the services are
durable: every process identifier is the same at the end as at the beginning.

## Scenario

The master service was once one-shot — it managed a single problem and then
shut down, so a second submission meant restarting everything. This lane asserts
that it no longer does. The harness stages the services once, launches the
repository process and the six long-lived services, and then submits twice in
order: first the separable scenario, then the contention scenario, each with its
own model installed as the application's active model.

What counts as the constellation is stated explicitly: the repository process
and the six long-lived services. The application is a submitting client that
runs once per submission and exits, so it is not held to identifier stability —
only the services are.

The lane fails on any restart, any wrong objective, or any process death. Each
submission is judged by the same shared assertions the single-scenario lanes
use, held to that scenario's own objective, so the second solve is not merely
observed to happen but observed to be correct.

It drives the model-file submission path rather than submitting a document,
because what is being proven is service durability across submissions; the
submission mechanism is the trigger, not the subject. For the same reason it
reuses a published graph rather than projecting a new one, and so seeds no row
in the proven-combination table.

## Running

```bash
tests/e2e/run_reuse.sh
```

Accepts `--domain N`, `--inforepo-port P`, `--timeout S`, `--workdir DIR` and
`--keep`; the working directory is always retained on failure. Each segment's
assertions can be re-run alone with
`tests/e2e/assert_scenario.sh <workdir> <scenario>`.
