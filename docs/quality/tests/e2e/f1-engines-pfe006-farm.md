# Lane: F1

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `F1` · Defined in: `tests/tools/lanes.txt` · Group: CPU

F1 is the column-farm lane. It submits the speculative-farming fixture with a
farm of four candidate columns per child, and green means the farm ran, the
schedule matched the one derived on paper, and the answer did not move.

## Scenario

The runner stages the fixture and launches the same flat constellation the
baseline lane uses — a price-directed root over two children — differing only in
the document, which adds a speculation block with a column count, a perturbation
size and a fixed seed on both children.

Every number the assert script checks is derived rather than read off a run.
The optimum and the round count come from a trace of the unfarmed campaign, made
before the machinery existed, with each round's duals and the perturbed vectors
printed at full precision. The farm schedule is derived too, from the
four-column trace and the recorded derivation of the gate threshold beside it,
and was re-pinned once when that threshold moved to the block's own convexity
dual. The optimum is the same as the unfarmed lane's, because farming buys
columns per round and nothing else: an objective that moved would be a defect
rather than a result. The campaign takes one round fewer, because a column that
the unfarmed run reaches at a later round enters the restricted master earlier.

The per-round stamps are asserted individually, and the lane is as explicit
about where farming gains nothing as about where it pays. On one round a
child's farm proposes four candidates, produces one distinct column and gains
nothing — three wasted solves, asserted as three wasted solves — because that
child's true reduced-cost vector has a single negative entry and a positive
scaling cannot make a positive entry beat it. On the same round the other
child's farm produces the exchange that pays, and the admitted column is
admitted on its merits: its reduced cost is recomputed against the true vector,
never taken on the perturbation's word. A later round is provably inert and
reported inert, and the final round carries no farm stamp at all, because no
reply passes the gate.

## Running

```bash
tests/e2e/run_engines.sh --lane pfe006-farm --domain 260 --inforepo-port 12360
```

This lane is not part of `--lane all`. Assertions can be re-run alone with
`tests/e2e/assert_pfe006_farm.sh <workdir>`.
