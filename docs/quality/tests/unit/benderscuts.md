# pf_BendersCuts_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_BendersCuts_Tests.cpp` · CTest: `pf_BendersCuts` · Labels: `unit;fast;public`

This test pins the cut algebra behind resource-directed decomposition: how a
Benders feasibility or optimality cut is built from a linking system, and how
the orientation of a solver's rays and duals maps onto that construction. Its
numbers were computed by hand in a design memo before the implementation
existed, so the test constrains the code rather than restating it.

## What it verifies

- A feasibility cut built from a Farkas ray reproduces the hand-computed
  coefficients and right-hand side, including the contribution of a capacity
  row whose right-hand side is negative — dropping that row changes the answer.
- The same cut is judged on both sides: it must cut off the allocation the
  memo calls infeasible *and* admit the one it calls feasible, so a sign error
  cannot satisfy one condition by luck.
- Positively scaling a ray leaves the cut unchanged; an all-zero ray, or one of
  the wrong length, is refused rather than turned into a vacuous row.
- An optimality cut carries its epigraph variable at +1, distinct coefficients
  on the two linking columns, and a right-hand side distinct from the recourse
  cost — so a transposition, or a confusion of the two quantities, fails.
- The identity check rejects a cut whose recorded recourse cost does not match
  its own row.
- The closing cases rebuild the same instance in `OsiClpSolverInterface`,
  extract a ray from an infeasible solve and duals from an optimal one, and
  require the resulting cuts to match the hand computation. Bound save and
  restore, and the refusal of an allocation naming a variable the model lacks,
  are checked alongside.

## Running

```bash
ctest --test-dir build -R '^pf_BendersCuts$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
