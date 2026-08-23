# pf_SpeculationPrng_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_SpeculationPrng_Tests.cpp` · CTest: `pf_SpeculationPrng` · Labels: `unit;fast;public`

Speculative farming draws two random streams: one perturbs a pricing exchange,
the other decides whether a round is certified inline. A fixture's hand-worked
mathematics quotes the numbers these functions produce, so this test asserts
those same numbers and keeps the fixture's predictions and the code from
drifting apart.

## What it verifies

- The underlying generator matches its published reference values word by word,
  and advances its state.
- Both draws are asserted as golden values on the exact tuples the fixture
  consumes, printed at the shortest precision at which a double round-trips so
  a reader can compare a printed line against the fixture without trusting
  either.
- The comparisons are exact rather than tolerant, deliberately: the generator is
  integer arithmetic and the scale is a power of two, so every value is
  reproducible bit for bit, and a tolerance would hide precisely the drift the
  test exists to catch.
- The stream is a pure function of its tuple. Two calls with one tuple agree, so
  nothing per-run enters the stream; a draw does not depend on what else was
  drawn; and swapping two fields of the tuple changes the result, so field order
  is pinned rather than assumed.
- Successive exchange indices within one round produce different exchanges, and
  a count of zero is legal and writes nothing.
- The certification rule is asserted as stated — certify inline exactly when the
  draw falls below the sample rate — and then applied to the fixture's own
  rounds, reproducing which of them is certified and which is deferred as proof
  debt.

## Running

```bash
ctest --test-dir build -R '^pf_SpeculationPrng$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
