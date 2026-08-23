# pf_MidPricing_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_MidPricing_Tests.cpp` · CTest: `pf_MidPricing` · Labels: `unit;fast;public`

A mid-level node answers its parent with a column. A merely suboptimal column
is not a visible failure — it is a well-formed reply the parent will price,
and the campaign converges to the wrong answer while every service reports
success. There is no runtime signal for that, so it is caught here, against a
fixture whose feasible set in interface space is three points and can be
enumerated by hand.

## What it verifies

- The inner column map is read from the compiled table, declaring the expected
  number of columns and naming both an interface column and an inner one.
- Objective injection spans every inner column, matches exactly the three
  interface names and gives each its arriving reduced cost, and zeroes every
  other column — including the one carrying a native cost in the model.
- Two inner campaigns are run whose hand-computed answers differ in both the
  winning option and the objective, so an implementation that always returned
  the same column cannot pass both. Each asserts all three reported interface
  values and the inner objective, and that a converged campaign is not reported
  as truncated.
- The fixture's native cost exists precisely to catch a failure to zero: keeping
  the compiled costs would change the first case's answer, so that omission
  fails here rather than converging quietly.
- An interface name that matches no column fails rather than being dropped, with
  a mapping error that names every unmatched column, not only the first, and the
  campaign itself refuses the unmatched interface.
- The iteration policy is parsed and applied: the default imposes no limit, a
  single-iteration policy limits pricing to one round, a bounded policy imposes
  its own bound and is refused without a positive one, and an unrecognised
  policy is refused rather than silently run unbounded. A bounded campaign
  completes and is reported as truncated.

## Running

```bash
ctest --test-dir build -R '^pf_MidPricing$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`,
and is registered with its fixture directory as an argument.
