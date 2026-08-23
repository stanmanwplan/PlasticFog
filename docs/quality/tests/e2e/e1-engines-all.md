# Lane: E1

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `E1` · Defined in: `tests/tools/lanes.txt` · Group: CPU

E1 is the default engine matrix: seven CPU lanes run in one invocation. Green
means the engine named on each binding is the engine that actually solved it,
and that the standing engine refusals still refuse.

## Scenario

Every inherited lane resolves the role default at every site, so none of them
can tell "the seam resolved a name" from "the seam used the name it always
used". These lanes ask that question directly. The engine evidence is read from
the structured records the services write to their error streams, so the rest of
the matrix stays byte-stable on standard output.

The seven are: a flat price-directed problem with both leaves bound to one
engine, against an independently solved hand-flattened monolith; the
resource-directed robot cell rebound to that same engine, whose oracle is read
out of the standing resource lane's assertions rather than re-typed, so the two
cannot drift; a mixed lane that runs one document twice — once with two children
on different engines, once with no solver block at all — and asserts the two
objectives are identical while each child used its own bound engine, which is
the per-binding control; the refusing and accepting sides of the conditional GPU
engine, run through validation alone because both outcomes are decided before
any transport entity exists, the accepting side with a negative control that
takes the stub away and gets the refusal back; a pricing-certification lane
where one child's unproven emptiness claim must be referred to an exact solver
before convergence is declared, with the other child as a control that must
certify zero times; and a recourse ray-capability lane in both halves, where a
guarantee names a capable fallback and the negative half is refused on
capability.

The GPU smoke lanes and the speculative-farming lanes are deliberately outside
`--lane all`: the first need a GPU and an installed library, and the second are
kept out so the CPU matrix can be compared against its own baseline.

## Running

```bash
tests/e2e/run_engines.sh --lane all
```

Individual lanes are reached by naming them. Failed runs retain their working
directory.
