# Lane: V2

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `V2` · Defined in: `tests/tools/lanes.txt` · Group: CPU

V2 is the spot-update lane: one constellation, two solves, and an update
document applied between them while the first solve is still running. Green
means an update executes against a running system rather than a stopped one.

## Scenario

The update is issued as soon as the campaign is addressable — gated on the
topology snapshot appearing, the same gate the control-plane lane uses and for
the same reason — and it asks for no interruption. Nothing is halted: the
republished modules arrive at services that are mid-campaign, and each adopts at
the first state where accepting a setup is legal. "Deferred, then adopted after
completion" is therefore a claim about the ordering of log lines, and that is
exactly how it is asserted.

The assertions pin the whole chain rather than the outcome alone: that the
update commits revision 2; that the republish set is exactly the pinned minimal
one, including the mid the walk-up added — a mid compiles its children's sources,
so a change at the leaf changes what the mid compiles — and excluding the root
the content rule spared; that both the changed leaf and the mid adopt revision 2;
and that the update completed while the first solve was still running, with no
halt published by an update that asked for none.

The second solve is a submission rather than a restart, and the lane explains
why: a subtree-scoped redistribution deliberately does not touch a master whose
content did not change, which at this fixture includes the root, so nothing in
the update path carries a command that would start a campaign. The update writes
the committed definition beside its snapshot, and the second solve submits that
document — the next revision, on the same constellation, with the same process
identifiers.

The lane also carries negative controls, and it drives the state they need
rather than depending on the machine's. One control submits an update smuggling
a capability whose refusal is conditional on hardware being absent; on a machine
where that hardware is present the update would be legitimately accepted and the
control would pass vacuously. The lane therefore forces the capability probe to
report unavailable, using a hook that can only ever make the runtime report less
capability and never more, so the control's subject stays the gate rather than
the hardware.

## Running

```bash
tests/e2e/run_nested.sh --update-lane
```

Failures always retain the working directory, which records each update
invocation's exit code and streams under a label the assertions read.
