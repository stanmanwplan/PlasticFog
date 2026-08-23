# pf_ColumnVerifier_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_ColumnVerifier_Tests.cpp` · CTest: `pf_ColumnVerifier` · Labels: `unit;fast;public`

Column verification is where a column produced by a process the master does not
trust becomes a column the master will use. The arithmetic is pure, so this
test pins it exactly — no solver, no document, no running services — and
concentrates on the threshold: a verifier right in the middle of its range and
wrong at its boundary would admit non-improving columns and cycle.

## What it verifies

- The three verdicts, one clear case each: a column that improves against the
  true reduced-cost vector is admitted, including a speculatively farmed
  candidate generated from a vector the master never trusted; a candidate the
  true vector does not want is rejected as non-improving, with its recomputed
  cost reported rather than hidden.
- A claimed reduced cost that disagrees with the recomputation is rejected as a
  cost mismatch even when the column would otherwise improve — the order of the
  checks is what catches it — and the signed discrepancy is reported. An honest
  claim on the same column is admitted, and a difference inside the claim
  tolerance is not a mismatch. Mismatch and non-improvement are never conflated.
- A boundary table straddles `threshold - tolerance` on both sides at five
  magnitudes across ten orders and both signs, stepping one representable double
  either way, plus zero, positive and negative tolerances. Two of its rows are
  a fixture's own hand-traced numbers, including the terminal round where
  nothing improves and the run converges.
- Duplicate indices in a support accumulate rather than overwrite, and the
  empty point sums to zero and is judged by the same arithmetic rather than
  treated as a special case.
- Mismatched array lengths, an out-of-range or negative index, one bad index
  among good ones, and a support against an empty vector are all rejected as
  malformed. Each verdict has exactly one spelling.

## Running

```bash
ctest --test-dir build -R '^pf_ColumnVerifier$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
