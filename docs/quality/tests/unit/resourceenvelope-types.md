# pf_ResourceEnvelope_Types_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_ResourceEnvelope_Types_Tests.cpp` · CTest: `pf_resource_envelope_types` · Labels: `—`

The allocation and cut payloads are the pair a resource-directed master and its
child exchange, decoded inside transport callbacks on both sides. Two
properties matter there, and this test pins both: a round trip preserves every
field, and malformed input produces a failed status rather than an exception.
It links no transport.

## What it verifies

- An allocation round-trips with its value names in order, its values exactly,
  and its schema version intact. A bound on the epigraph variable survives with
  both its presence and its value, an unset bound is absent from the encoded
  bytes rather than defaulted, and an allocation written without one decodes
  without one.
- An allocation looks a name up by the model's own spelling and reports a name
  it does not carry as absent rather than returning a default.
- Optimality and feasibility cuts each round-trip with their family, sense,
  coefficient names in order, diagnostics and recourse cost. Negative
  coefficients and a negative right-hand side keep their signs, and the
  spelling of each payload's kind matches its family.
- An answer that adds nothing round-trips as such and validates: having nothing
  to add is a complete answer, not a missing one.
- Validation refuses what would otherwise reach a master's model and corrupt it
  quietly: an allocation with no values or an unnamed value, a cut with no
  coefficients, an unnamed coefficient or an unknown sense, and an optimality
  cut with no recourse cost. Several of these parse before they fail
  validation, and the recourse cost is reported absent rather than defaulted to
  zero, which is the distinction that keeps the refusal meaningful.
- The two decoders refuse each other's payloads rather than reading them as
  empty, and no malformed input throws.

## Running

```bash
ctest --test-dir build -R '^pf_resource_envelope_types$' --output-on-failure
```

The target requires the transport-free configure, `-DPF_BUILD_PROBLEM_INPUT_TESTS=ON`.
