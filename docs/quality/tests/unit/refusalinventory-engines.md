# pf_RefusalInventory_Engines_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_RefusalInventory_Engines_Tests.cpp` · CTest: `pf_RefusalInventory_Engines` · Labels: `unit;fast;public`

The engine half of the refusal ledger, kept in its own file so engine and
workbench rules never have to be reconciled inside one test. Its purpose is its
siblings': a silent capability claim cannot appear without failing a named test.
Every case perturbs one valid definition by exactly one fact.

## What it verifies

- Each entry pins the exact code, message and document pointer of its refusal,
  and pairs it with a control showing the neighbouring document is accepted, so
  a case cannot pass by refusing something unrelated.
- The GPU engine is refused in any position requiring integer solving, asserted
  twice — with the probe forced unavailable and with a working library — which
  distinguishes a capability refusal, that hardware never retires, from an
  availability refusal, that it does. A CPU engine at the same position, and the
  GPU engine where a linear program is solved, are both accepted.
- Certificate rules are pinned as capability refusals by name: an engine
  reporting no dual rays is refused at a resource child, as is a fallback that is
  itself incapable, a fallback with no engine, and a fallback naming an engine
  illegal for the role. Each has an accepting counterpart.
- Semantic pairing and domain rules are asserted in both directions and in the
  right order — legality is decided before the compatibility ratchet, so the
  ratchet stays silent on a document already refused on its merits.
- Optional blocks carry through exactly: an absent block is never materialised,
  a present one reaches the parsed structure with its stated values, and the
  canonical form is a fixed point of export and import — including a rate that
  survives as the identical floating-point value.
- Retirements are flipped, never deleted: where a refusal was earned away the
  case asserts acceptance and that the retired code is never emitted again, at
  the same pointer. Service-id list membership is pinned against near misses: a
  prefix, a containing string, empty elements and an empty value.

## Running

```bash
ctest --test-dir build -R '^pf_RefusalInventory_Engines$' --output-on-failure
```

The target requires the transport-free configure, `-DPF_BUILD_PROBLEM_INPUT_TESTS=ON`.
