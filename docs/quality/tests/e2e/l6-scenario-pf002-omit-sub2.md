# Lane: L6

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `L6` · Defined in: `tests/tools/lanes.txt` · Group: CPU

L6 is the services-unavailable fast-fail lane. One subproblem service is never
launched, and green means the application refused to start a solve it could not
complete, said exactly what was missing, and exited immediately rather than
waiting out a timeout.

## Scenario

The harness stages the constellation as usual but omits one subproblem service
entirely — the test-the-test hook, used here to make a required service genuinely
absent rather than merely slow.

This is the one mode of this runner that launches the application on the
generalized path, with a problem-definition document, and it has to be: the
fast-fail outcome is an exit code from the submission flow, and the legacy
demonstration application has neither exit codes nor count enforcement. Nothing
solves in this lane; the check is a process exit.

What is asserted: the application exits with the services-unavailable code
within a bounded wait, and its output carries a missing-services block naming
the service type together with the requested, received and missing counts and
the liveness window in effect. The measured behaviour is an immediate exit,
where the earlier behaviour was to hang until the solve timeout and then report
a timeout — a distinction that matters, because "timed out" sends an operator
looking for a slow solver rather than an absent service.

## Running

```bash
tests/e2e/run_scenario.sh --scenario pf002 --omit sub2 --mode unavailable
```

`--omit` accepts a comma-separated list. Failed runs always retain their working
directory.
