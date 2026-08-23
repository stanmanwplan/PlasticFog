# Lane: V8

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `V8` · Defined in: `tests/tools/lanes.txt` · Group: CPU

V8 is the per-master results lane. The nested problem is submitted from a
document that asks for the mid's own results as well as the overall answer, and
green means the mid published its own envelope and the application landed it
beside the overall one.

## Scenario

The lane submits a different definition rather than the same one with a flag,
and that is the design of the experiment. The two fixtures differ in exactly one
field — the results scopes naming the mid alongside the overall problem — plus
the problem's identifier and its description. So anything this lane sees and the
plain nested lane does not is attributable to per-master return and to nothing
else: the lane compares two documents, not two code paths.

Everything else is held constant: the same eight-process constellation, the same
models, the same service identifiers, and the same oracle. The overall answer
must come back unchanged at 5.0, which is what makes the added envelope an
addition rather than a change.

What is asserted is that the mid published an envelope scoped to its own node,
and that the envelope arrived in the results document's per-node array where a
caller can find it. A per-master result that was produced but never delivered,
or delivered without its scope, would be indistinguishable from the overall
answer to anyone reading the file.

## Running

```bash
tests/e2e/run_nested.sh --scopes-lane
```

Accepts the nested lane's `--domain`, `--inforepo-port`, `--timeout`,
`--workdir` and `--keep`. Failures always retain the working directory.
