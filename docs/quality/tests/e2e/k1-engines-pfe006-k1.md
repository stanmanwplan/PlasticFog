# Lane: K1

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `K1` · Defined in: `tests/tools/lanes.txt` · Group: CPU

K1 is the baseline for the speculative-farming fixture: the same instance and
the same constellation with no speculation stated anywhere. Green means the
unfarmed campaign reaches the hand-derived optimum in the hand-derived number
of pricing rounds, and that farming is genuinely off by default.

## Scenario

The runner stages the fixture's base document — a price-directed root over two
children — and launches the flat constellation the other engine lanes use. The
document states no speculation block at all.

Two numbers are pinned, both derived on paper before the machinery that
produces them existed. The optimum is −61, derived twice over: directly, by
hand-solving the undecomposed problem through its Lagrangian dual to a unique
multiplier, and again as the terminal value of the unfarmed column-generation
trace. It was then confirmed independently by three vendored solvers on the
hand-flattened monolith. The baseline pricing-round count is six — one
first-phase round and five second-phase rounds — and the fixture's own notes
carry the per-round table with every dual and every admission test.

The round count needs no new output and no debugging switch. The pricing code
already writes one structured record per block per batch round to the error
stream, carrying the round number, which is incremented exactly once per
pricing round; the number of distinct round values in those records is the
round count, read off a line that already exists. The farm's own records use
different phase names, so they can never be miscounted as rounds.

The lane also carries the defaults-off proof at lane level: a document with no
speculation block must emit not one farm stamp. Without that half, "farming is
off unless asked for" would be a claim about the code rather than a
measurement. A measured value that disagrees with either oracle is a finding to
report, never a number to adjust.

## Running

```bash
tests/e2e/run_engines.sh --lane pfe006-k1 --domain 260 --inforepo-port 12360
```

This lane is not part of `--lane all`. The assertions alone are
`tests/e2e/assert_pfe006_k1.sh <workdir>`.
