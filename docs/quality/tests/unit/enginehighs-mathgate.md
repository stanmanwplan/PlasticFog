# pf_EngineHighs_MathGate_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_EngineHighs_MathGate_Tests.cpp` · CTest: `pf_EngineHighs_MathGate` · Labels: `unit;fast;public`

HiGHS is the first engine in this build not reached through the COIN-OR solver
interface, and the one thing no derivation settles about a new solver is the
orientation of the duals and rays it returns: a cut built from a ray the wrong
way round is still a cut, and the campaign converges to a confident wrong
answer. This test gates that against the same hand-worked instance the Benders
cut test uses, and then against CLP's extracted values.

## What it verifies

- On the feasible allocation, HiGHS proves optimality and returns the
  hand-computed objective, primal values and row duals, with the slack row's
  dual at zero and strong duality satisfied. Those duals build an optimality cut
  whose coefficients and right-hand side match the hand computation and which
  reproduces the recourse cost at its own allocation.
- The same values are extracted from CLP and compared: both engines report the
  same number of duals, agree on each dual under the normalised convention, and
  agree on the recourse cost.
- On the infeasible allocation, HiGHS proves infeasibility and yields a usable
  Farkas ray, oriented non-negative on every `>=` row. The feasibility cut built
  from it matches the hand-computed coefficients and right-hand side, cuts off
  the infeasible allocation, admits the feasible one, and is identical to the
  cut CLP's ray produces — same sense, same coefficient count, same variables in
  the same slots. Positively scaling the ray changes nothing.
- The status mapping is asserted as a total function over the solver's status
  enumeration, each status mapped to proved, unproven or not applicable, and
  then reached for real on an optimal model, an infeasible one, an unbounded
  one, an iteration-limited solve and a time-limited solve.

The file records what it measured rather than assumed, including that this
version of HiGHS already agrees with CLP's orientation for `>=` rows in a
minimisation, and a buffer-sizing hazard between the two ray-retrieval calls.

## Running

```bash
ctest --test-dir build -R '^pf_EngineHighs_MathGate$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
