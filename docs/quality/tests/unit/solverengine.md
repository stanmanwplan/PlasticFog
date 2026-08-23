# pf_SolverEngine_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_SolverEngine_Tests.cpp` · CTest: `pf_SolverEngine` · Labels: `unit;fast;public`

The engine seam is the layer that turns an engine name into something that
solves. It claims three things, and this test asserts each rather than arguing
it: the registry resolves what it says it resolves, the reported capabilities
are true, and wrapping an engine changes no arithmetic.

## What it verifies

- The registry resolves each registered name, reports a matching name back, and
  never returns nothing for a name it lists. Resolution is case-sensitive, the
  empty name is unregistered, and — the load-bearing half — the coordinator's
  name does not resolve, because a registry that accepted it would hand a caller
  a coordinator through an engine handle.
- Capabilities are checked bit by bit against what the wrapped code actually
  exposes, and where the honest answer is no it is asserted as no: engines that
  report no duals, no warm start of either kind, or no integer support. Those
  are the bits a plausible but generous wrapper would get wrong.
- Refusals are explicit rather than silent successes: an engine with no integer
  support refuses an integer solve, and one that solves only integer models
  refuses a linear solve. Dual-ray capability is read from one shared table, so
  the registry's answer and the document codec's cannot drift, and a misspelled
  or empty name defaults to not ray-capable. Proof-status reporting is asserted
  per engine, and a proved-optimal outcome occurs exactly when an engine claims
  to report proof statuses.
- The engine snapshot is byte-identical across calls and carries each capability
  it should. The GPU engine is registered unconditionally but executable only
  when its probe passes; no other engine claims GPU.
- One small linear program with a hand-computed optimum is solved twice: the way
  call sites solved it before the seam existed, and through the registry. Status,
  objective, primal solution and row duals must agree to a tight tolerance and
  both must reach the hand-computed optimum, so a run in which both paths broke
  the same way still fails.

## Running

```bash
ctest --test-dir build -R '^pf_SolverEngine$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
