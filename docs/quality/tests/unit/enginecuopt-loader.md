# pf_EngineCuOpt_Loader_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_EngineCuOpt_Loader_Tests.cpp` · CTest: `pf_EngineCuOpt_Loader` · Labels: `unit;fast;public`

The NVIDIA cuOpt adapter is loaded at run time, so this test pins the loading decision
rather than the solving. It runs against stub libraries and states what it
cannot prove — that the declared C interface matches a shipping cuOpt install,
or that the adapter computes a correct answer. Only the gated smoke lane can
test either.

## What it verifies

- The probe reaches all four outcomes: a working library, a missing one, one
  whose symbols are incomplete — with the missing symbol named — and one whose
  symbols resolve but which reports no device. The symbol check runs before the
  device check, shown in both directions by stubs built to fail one and pass
  the other. A bad path is reported as asked for with no fallback, forcing
  unavailability overrides a working library, and moving either environment
  variable re-probes rather than reusing the cached answer.
- Capabilities are asserted individually, including the false ones and why: no
  dual-ray certificate, no integer surface in this version, not deterministic,
  and no solver interface object to return. The warm-start bits are measured —
  true against a complete stub, false with no installation.
- A solve refused because the probe failed reports "not solved" rather than a
  zero optimum, names the probe outcome, and observes nothing. A recognised
  optimal solve returns the stub's canned objective, primal, dual and reduced
  costs without a ray, leaving the caller's model unsolved because a copy was
  solved; an infeasible result is an answer; an unrecognised model surfaces as
  a refusal. Integer solving is refused even with the probe passing.
- The engine is registered whether or not the probe passes but is executable
  only when it passes, and both sides of the runtime agree on that. Legality is
  independent of availability: the engine is legal at subproblem roles and
  refused at master roles even with a working stub.

## Running

```bash
ctest --test-dir build -R '^pf_EngineCuOpt_Loader$' --output-on-failure
```

The target requires a tree configured with both `-DPF_BUILD_UNIT_TESTS=ON` and
`-DPF_BUILD_TEST_TOOLS=ON`, which is what builds the stub libraries it loads.
