# pf_Catalog_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_Catalog_Tests.cpp` · CTest: `pf_Catalog` · Labels: `unit;fast;public`

The catalog is the append-only store of problem-definition revisions. This test
pins the four properties that make a stored revision worth trusting —
immutability, hash determinism, an exact round trip, and a ranked search that
never picks one answer silently — and it tests each by its mechanism rather
than through the convenience of the API.

## What it verifies

- Immutability is asserted from outside the library: raw `UPDATE` and `DELETE`
  statements are issued against the database with SQLite directly and must be
  refused as append-only, after which the rows are re-read and shown unchanged.
  Appending a new revision remains permitted.
- Revision chains link correctly: the first revision has a null parent, later
  ones name their predecessor, a changed document gets a different content hash,
  the stored bytes re-hash to the stored hash, and unknown applications or
  revisions are errors.
- Hash determinism is checked both across two ingests into one database and
  across two separate databases, so the claim is about the canonical form and
  not about one connection's state. Re-ingesting identical bytes appends rather
  than deduplicating.
- The round trip is byte-for-byte over every `*.problem.json` fixture
  enumerated at run time, with the known documents each named so a glob that
  returned nothing fails loudly; referenced resources are compared as well.
- Search is exercised on both retrieval paths — the detected full-text path and
  the fallback query path, forced on so it cannot rot unexercised. A unique
  match returns a one-element list, repeated queries return the same order,
  candidates are ordered by non-increasing score, tag and text filters combine
  as a conjunction, and the document body is searched.
- A document refused by validation is still ingested, with its status, its
  refusal code and its bytes unaltered; unparseable JSON is not stored.

## Running

```bash
ctest --test-dir build -R '^pf_Catalog$' --output-on-failure
```

The target is built when the tree is configured with either
`-DPF_BUILD_UNIT_TESTS=ON` or `-DPF_BUILD_PROBLEM_INPUT_TESTS=ON`.
