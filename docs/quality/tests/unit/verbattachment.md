# pf_VerbAttachment_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_VerbAttachment_Tests.cpp` · CTest: `pf_VerbAttachment` · Labels: `unit;fast;public`

When a problem definition is projected into a runtime graph, each module is
attached the commands its role should receive. Attaching a solve order to a
subproblem is not merely wasteful: a subproblem solves in response to prices,
so one told to solve first parks in the wrong state and rejects the prices when
they arrive. This test asserts the table rather than the symptom.

## What it verifies

- The table itself: master roles receive setup and solve, with the run token
  and correlation identifier on the solve; subproblem roles receive setup
  alone, with no options. A master role on a mid-level node is the exception —
  it receives setup only, and its tokens ride that setup, because a mid is
  driven by prices on both faces.
- Command and module counts are asserted for a flat, a nested and a
  resource-directed tree, and a disabled projection owns no commands.
- A mid-level node's two halves are built and marked as such, and the inner
  solve policy is stamped on the master half only, verbatim, with its iteration
  bound present or absent according to the policy.
- Interface closure at a mid: a definition whose master half declares the
  interface builds, while a renamed variable is refused with a code naming the
  unresolved variable, and a commented-out declaration does not satisfy the
  rule. A mid split across mismatched placements fails with its own diagnostic.
- Solver selection is stamped onto the module, numeric options rendered as
  compact JSON and string options unquoted, with compatibility notes emitted or
  withheld per selection — including a GPU note naming the probe's outcome, and
  its absence when the probe passes. Notes are asserted in both directions:
  retired ones absent, standing refusals present and named, and the projection
  attributes surviving a note's retirement.
- Results scopes: the default scopes the root master and not a mid master, a
  named mid node scopes its master half, scoped command sets carry their
  tokens, and extra scopes leave the graph compatible.

## Running

```bash
ctest --test-dir build -R '^pf_VerbAttachment$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
