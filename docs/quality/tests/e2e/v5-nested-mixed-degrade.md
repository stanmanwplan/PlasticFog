# Lane: V5

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `V5` · Defined in: `tests/tools/lanes.txt` · Group: CPU

V5 injects a fault into the mixed shape: one of the resource-directed mid's own
children is killed before the solve, so the mid's Benders loop loses a child.
Green means the failure was resolved twice — once by the mid for its child, once
by the root for the mid — by two independent decisions.

## Scenario

The constellation is the mixed lane's, unchanged. The named robot is killed
before the solve begins, with a shortened reply deadline applied per service.
The default deadline outlasts the application's own wait, which would turn a
dead child into a results timeout instead of the outcome the failure rule
specifies — a fact the harness measured rather than assumed, and the reason the
deadline is shortened here.

The mid must abort, because substitution is invalid for a resource-directed
child: there is no surrogate for a cut. The root must then resolve the mid's
block by its own configured policy, and the two decisions are independent — which
is the case a nested topology adds and a flat one cannot express.

The root's own reply deadline is short by default and lengthened only where the
root is genuinely waiting for a mid that is alive and working. On a fault lane
the mid is going to abort and never answer, so a long root deadline does not
help it: it pushes the root's resolution past the application's wait and turns a
clean exit into a results timeout. That, too, was measured on this lane rather
than reasoned about.

Fault injection here is fixed to killing before the solve, and the harness
rejects any other mode rather than silently coercing it. The alternative kills
the victim after its first reply, and on this fixture the batch pricing path
outruns that window — the campaign is over before the kill lands. A lane that
accepted the other mode and then behaved as this one would report a mode it did
not run.

## Running

```bash
tests/e2e/run_nested.sh --mixed-lane --mixed-degrade robot_r1
```

The degrade flag requires the mixed lane and is rejected without it. Failures
always retain the working directory.
