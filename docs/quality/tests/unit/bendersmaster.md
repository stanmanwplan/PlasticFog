# pf_BendersMaster_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_BendersMaster_Tests.cpp` · CTest: `pf_BendersMaster` · Labels: `unit;fast;public`

Where the cut test pins the arithmetic, this one pins what the arithmetic is
used for: the Benders loop itself. The master and its two children run in a
single process — the children are real recourse LPs solved through the same
entry points the subproblem service uses — so everything between choosing an
allocation and proving optimality is exercised without a running constellation.

## What it verifies

- The loop converges to the optimum the file's header enumerates by hand, 40,
  with the upper and lower bounds closing on it and the gap shut. The instance
  is chosen so that a master ignoring its shared-slot constraint would report a
  worse value and one violating it a better one, so the assertion discriminates
  in both directions.
- Both cut families fire at least once. Optimality cuts alone would leave the
  loop unaware that some allocations admit no recourse; feasibility cuts alone
  would never cost the recourse.
- The incumbent returned actually satisfies the shared-slot constraint.
- The round-boundary hook is called at least once per round, and the loop emits
  a structured cut log.
- A master model carrying no epigraph variable is refused at setup rather than
  run, because such a loop would report a lower bound that silently ignores
  every recourse cost.
- A loop stopped by its iteration limit reports `iteration_limit`, never
  optimal, and leaves a diagnostic; a stop requested before the first round
  halts at the round boundary having run no round.

## Running

```bash
ctest --test-dir build -R '^pf_BendersMaster$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
