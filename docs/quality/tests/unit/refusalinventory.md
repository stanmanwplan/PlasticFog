# pf_RefusalInventory_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_RefusalInventory_Tests.cpp` · CTest: `pf_RefusalInventory` · Labels: `unit;fast;public`

A refusal has no lane. It produces no output, and a future edit that widens a
predicate by one condition retires it by accident — the document simply starts
being accepted, and the first evidence is a wrong answer from a constellation
that should never have started. This test is the fixed inventory of what the
build declines, each entry pinned by its exact diagnostic.

## What it verifies

- Each entry asserts the specific note text or refusal code, not merely that
  something was refused — "it was refused" is satisfied by a document invalid
  for an unrelated reason — so every case is valid in every respect except the
  one under test. A note marks a valid document this runtime cannot execute,
  refused at publish; a refusal marks a document asking for something unsound,
  rejected at parse or at build.
- Notes are pinned for a resource-directed boundary above a price-directed one,
  for two coordination bindings the runtime does not implement, and for a
  resource boundary above a resource subtree — a shape deliberately not claimed.
- Refusals are pinned for integer recourse on a resource child, for substitution
  as that child's failure policy, for mixing paradigms downward from one node,
  for a results scope naming a node that carries no master-side role, and for a
  price-over-resource node whose epigraph variable is not zero.
- A third kind is conditional: the document is valid and whether the runtime
  executes it is measured at validation time. Both branches are pinned — the
  refusal and the acceptance — because a conditional asserted only on its
  refusing branch is satisfied by a probe hard-wired to false, which looks
  identical to a correct implementation on any machine without the hardware.
  The GPU engine and the GPU service kind are both entries of this kind.
- Retirements are recorded rather than deleted: an entry whose refusal was
  earned away asserts the acceptance in its place.

## Running

```bash
ctest --test-dir build -R '^pf_RefusalInventory$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
