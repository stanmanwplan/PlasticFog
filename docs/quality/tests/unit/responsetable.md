# pf_ResponseTable_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_ResponseTable_Tests.cpp` · CTest: `pf_ResponseTable` · Labels: `unit;fast;public`

The response table is the resource-directed counterpart to the reply table: it
arms a slot per child, matches arriving cuts to it, and reports why a cut was
not usable. The end-to-end lane exercises the happy path on every round, so
this test covers the rejection paths, and the one rule that differs from the
price-directed side.

## What it verifies

- Matching is by exact round, never by high-water mark, and that is pinned in
  both directions. A cut from an earlier round and a cut from a later one are
  each rejected as an iteration mismatch and leave the slot armed, still
  waiting for the real answer; the exact round is accepted, which is the half a
  reject-everything defect would still pass.
- The reason this rule is stricter than the price-directed one is what a cut
  is: a bound derived from one specific allocation. Crediting a late cut to the
  round now in flight would attach a bound to an allocation never sent, and a
  master with no copy of the recourse model would adopt the row rather than
  detect it.
- An accepted response routes to its armed child, fills the slot, is readable,
  and returns the payload that went in.
- The five route results are each reached by name, because they are the
  vocabulary a stale-reply record is written in: no outstanding request on an
  empty table and on an unknown service — leaving the armed slot untouched — a
  duplicate second response with the first still in the slot, the iteration
  mismatch above, and acceptance.
- A slot marked timed out stays timed out: a late cut reports no outstanding
  request, the accurate reason, and does not resurrect the slot.
- Clearing a round deactivates the table, empties the slot, and makes a cut
  from the finished round unroutable.
- A mismatched reserved echo does not reject a response; it is reported to the
  caller separately.

## Running

```bash
ctest --test-dir build -R '^pf_ResponseTable$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
