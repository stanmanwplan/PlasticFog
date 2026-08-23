# Lane: V4

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `V4` · Defined in: `tests/tools/lanes.txt` · Group: CPU

V4 is the mixed lane — the one composed shape that executes: a price-directed
root over a resource-directed mid with pure-feasibility recourse. Green means
two paradigms coordinated in one campaign, with the answer unchanged from the
purely price-directed instance of the same size.

## Scenario

The lane deliberately reuses the nested harness rather than getting its own, and
that reuse is the point. It stands up the identical constellation the nested
lane stages — eight processes, two master services, three subproblem services,
the same explicit service identifiers, one mid in the middle — and the only
thing that differs is which paradigm the mid drives downward. That is exactly
the fact the composition invariant says nobody above the mid should have to care
about: a harness needing its own staging, launch order and service map because a
child three levels down solves by cuts instead of by columns would be evidence
against the invariant. Reusing this one is the harness-level statement of it,
and the flag changes only the fixture directory, the root model source and the
asserter.

The oracle is 5.0, and the participation assertions are what make it mean
something, for the same reason they do on the nested lane: an unanswered block
is priced locally by the coordinator, and that fallback reproduces the answer,
so the traffic has to be asserted at both levels rather than inferred from the
number.

This is the only lane that seeds the mixed-shape row in the proven-combination
table, where the shape is recorded root-down — a price root over a resource mid
being a different shape from the reverse.

## Running

```bash
tests/e2e/run_nested.sh --mixed-lane
```

Accepts the nested lane's `--domain`, `--inforepo-port`, `--timeout`,
`--workdir` and `--keep`. Failures always retain the working directory.
