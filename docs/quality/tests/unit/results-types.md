# pf_Results_Types_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `pf_Results_Types_Tests.cpp` · CTest: `pf_results_types` · Labels: `—`

The results envelope is how a solved problem's answer leaves the runtime, and
it is decoded inside a transport callback. Two properties matter most there and
this test pins both: a round trip preserves every field, and malformed input
produces a failed status rather than an exception. It links no transport.

## What it verifies

- Every field of a well-formed envelope survives a round trip: correlation
  identifier, problem identifier, finality, objective, best bound, gap,
  elapsed time, round count, diagnostics, and every primal value with its name,
  including names carrying the mangling an MPS file imposes.
- Every solve status round-trips through its string form, and an unrecognised
  status decodes as unknown rather than failing.
- Per-node provenance survives with its node path, producing service
  identifier, engine, termination status and proof status. Every member of the
  proof-status vocabulary round-trips, an unrecognised proof status decodes as
  not observed rather than as itself, and an envelope with no per-node
  provenance carries no such key at all.
- Absent is distinguished from empty throughout: an unset engine, termination
  status or proof status emits no key, and decodes back to unset rather than to
  a value.
- Byte stability is asserted in both configurations — an envelope observing
  none of the optional fields serialises identically after a round trip, and so
  does one carrying them — so adding a field cannot silently move an existing
  envelope's bytes.
- Degradation is carried and visible after a round trip: the degraded block,
  its subproblem service identifier and the reason survive, while an undegraded
  solve reports no degraded blocks.
- Non-finite values are handled deliberately rather than by accident: an
  infinite bound serialises and parses back, and a non-finite objective or
  bound is published as zero.
- Malformed payloads are handled without an exception and never yield
  fabricated primal values.

## Running

```bash
ctest --test-dir build -R '^pf_results_types$' --output-on-failure
```

The target requires the transport-free configure, `-DPF_BUILD_PROBLEM_INPUT_TESTS=ON`.
