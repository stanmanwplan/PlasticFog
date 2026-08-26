# Lane: V1

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `V1` · Defined in: `tests/tools/lanes.txt` · Group: CPU

V1 is the control-plane lane. It runs the nested constellation through one
campaign and publishes control commands into it while it is still solving, and
green means a command aimed at a running system was received, applied and
acknowledged.

## Scenario

Commands are published as their own documents through the application's command
mode, addressed at services through the topology snapshot the submission writes.
That snapshot is written twice — once immediately after the overall problem is
published, before any result exists, and again at completion — so a command can
be aimed at the very campaign that produced the snapshot it needs, and one
campaign serves as both. Writing only at completion would mean commands could be
aimed only at a constellation that had already finished, which is a post-mortem
rather than a control plane.

This variant pauses a child under the mid and asserts the control chain as far
as the acknowledgement: the command is validated against the snapshot, resolved
to a service id, published recipient-keyed, applied by the addressed leaf as a
flag, and answered on the status channel — and the run still completes with the
command in flight against it. The substitution that would follow is deliberately
not asserted, because at this fixture's timescale it cannot be made to happen;
the mechanism stays proven at unit level. Two negative controls run alongside,
so the lane cannot pass by having no effect at all.

The timing is measured rather than assumed. A mode that issues the command
during the campaign is implemented and gated on an observed marker in the mid's
own narration, never on a sleep — but it does not work at this fixture's
timescale: the mid's inner campaign completes in single-digit milliseconds while
the command process needs about a second to reach its first publication, so the
command lands after the campaign it was aimed at has converged. The mode is kept
because it is the measurement; the default issues the command into the running
campaign, gated on the initial snapshot — the earliest observable moment in the
campaign's life — which is the deterministic one. No sleep is used to close the
gap in either mode.

## Running

```bash
tests/e2e/run_nested.sh --command-variant 1
```

`--pause-when` selects when the command is issued: `before-solve` by default,
`mid-solve`, or `never` — the last issuing no command at all and running the
reuse control of two consecutive campaigns on one constellation instead.
Failures always retain the working directory, which includes a command trace.
