# pf_EngineHighs_Parity_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_EngineHighs_Parity_Tests.cpp` · CTest: `pf_EngineHighs_Parity` · Labels: `unit;fast;public`

Where the math gate pins HiGHS's orientation on a hand-worked 2×2, this test
pins the adapter as the registry actually constructs it, against CLP and CBC on
a larger instance. HiGHS's values are read through the engine result transport
while CLP's are read off the model the established way, so the new path is
compared against the existing one rather than against itself.

## What it verifies

- Both engines prove the same linear program optimal and report the same
  hand-computed objective, and HiGHS's primal values match the hand computation
  term by term.
- The instance's non-degeneracy is asserted rather than assumed: every primal
  variable is strictly positive and every row dual is strictly positive, which
  makes the dual optimum unique and therefore comparable across engines. An
  edit that perturbed the data into degeneracy fails here instead of producing
  an unexplained dual mismatch.
- The transport carries what it should: one dual per row and one reduced cost
  per column from a feasible solve, no ray from a feasible solve, and a ray
  from an infeasible one — one entry per row, non-negative on every `>=` row,
  and usable to build a feasibility cut with no further handling.
- Duals travelling through the transport equal CLP's read off the model, and
  satisfy strong duality against the hand-computed objective.
- On the integer version, HiGHS and CBC report exactly equal objectives, the
  optimum is no better than the linear bound, the reported point is integral,
  satisfies every row, and costs what the reported objective says. No duals and
  no ray travel from an integer solve.
- The engine snapshot names HiGHS, keeps its sorted position, and reports it
  executable with dual rays and without GPU, alongside the other engines'
  standing state. Role legality is asserted for both HiGHS and the GPU engine,
  including the master role each is refused at and the fact that a failing
  probe changes availability but not legality.

## Running

```bash
ctest --test-dir build -R '^pf_EngineHighs_Parity$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
