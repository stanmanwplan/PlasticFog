# Lane: V1

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `V1` · Defined in: `tests/tools/lanes.txt` · Group: CPU

V1 is the control-plane lane. It runs the nested constellation through several
campaigns and publishes control commands between them, and green means a command
aimed at a running system took effect and the failure policy resolved the paused
node as it should.

## Scenario

Commands are published as their own documents through the application's command
mode, addressed at services through the topology snapshot a previous submission
wrote. That snapshot is written when a run finishes, so a command cannot be
aimed at the campaign producing the snapshot it needs: the first campaign on a
fresh constellation exists to produce it, and the campaigns after it are the
ones under test. That structure is what the design admits, not a convenience of
the harness.

This variant pauses a child under the mid and asserts the substitution that
follows: the paused node is approximated master-side, as a missing column is,
and the run still completes. Two negative controls run alongside, so the lane
cannot pass by having no effect at all.

The timing is measured rather than assumed. A mode that issues the command
during the campaign is implemented and gated on an observed marker in the mid's
own narration, never on a sleep — but it does not work at this fixture's
timescale: the mid's inner campaign completes in single-digit milliseconds while
the command process needs about a second to reach its first publication, so the
command lands after the campaign it was aimed at has converged. The mode is kept
because it is the measurement; the default issues the command between campaigns,
which is the deterministic one. No sleep is used to close the gap in either
mode.

## Running

```bash
tests/e2e/run_nested.sh --command-variant 1
```

`--pause-when` selects when the command is issued: between campaigns by default,
during the campaign, or not at all — the last running the reuse control of two
consecutive campaigns on one constellation instead. Failures always retain the
working directory, which includes a command trace.
