# Lane: L7

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `L7` · Defined in: `tests/tools/lanes.txt` · Group: CPU

L7 is the nested lane, and the only one with a mid-level node: a service that is
a subproblem to its parent and a master to its own children at the same time.
Green means two levels of decomposition coordinated, and it is the lane that
demonstrates nesting actually runs.

## Scenario

The constellation's shape differs from every flat lane, not just its data. Eight
processes rather than seven: two master services instead of one, three
subproblem services under two different masters, and one service holding both
halves of the mid, because the two halves share a single inner model. Staging,
launch order and assertions all differ for that reason, which is why this is its
own harness rather than a mode of another.

The oracle is 5.0, independent of the runtime: it comes from a hand-flattened
monolith of the same instance, solved with a vendored solver and cross-checked
with another, and reproduced by hand enumeration in the design notes. The
optimum is unique and strictly worse than the sum of the independent per-child
minima, so a run that failed to coordinate could not reach it.

The participation checks are the point. The coordinator prices an unanswered
block locally with its own fallback, and that fallback reproduces the known-good
objective exactly — so a correct objective is not evidence that anything was
distributed, and at a mid it is not even evidence the mid ran an inner campaign:
a mid whose upward face never came up would simply never answer, and the root
would price its block locally and still report the same number. The lane
therefore asserts the traffic at both levels, as an equality per boundary: each
of the root's two children answered exactly as many times as the root asked, and
each of the mid's two children answered exactly as many times as the mid asked.

## Running

```bash
tests/e2e/run_nested.sh
```

Accepts `--domain N`, `--inforepo-port P`, `--timeout S`, `--workdir DIR` and
`--keep`; failures always retain the working directory. The oracle and the
pinned participation counts live in `tests/e2e/assert_nested.sh`, which is
callable on its own against any preserved working directory.
