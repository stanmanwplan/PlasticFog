# pf_ZimplRegistry_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_ZimplRegistry_Tests.cpp` · CTest: `pf_ZimplRegistry` · Labels: `unit;fast;public`

The source registry gives every model and data source a content identity; the
artifact cache keeps the results of compiling them. This test covers ingestion,
derived relations, pinning, eviction, single-flight compilation and
persistence, against the same goldens the parity harness uses.

## What it verifies

- Ingestion derives identity from the problem-input layer rather than minting
  its own: a definition assembled in memory, never passed through the codec,
  still hashes to what the codec would have produced. Relations are derived
  rather than stored — the test asks twice without mutating anything, and an
  unknown model, an unknown revision and a data source each relate to nothing.
- Pinning is exercised through the commit observer in commit order: every source
  of a revision is pinned, a source carried forward stays pinned — pinned by the
  new revision before the old one's pin is dropped — and a dropped source becomes
  evictable at once.
- A cache hit runs no producer, a failing producer's result reaches the caller
  but is not retained, invalidation makes a request compile again, and a cached
  result carries no staging path because that directory belonged to one compile.
- Eviction is budget-driven: a pinned artifact survives even an explicit
  eviction, an unpinned one goes under a minimal budget, the least recently used
  entry is evicted, byte accounting returns to zero, and a malformed budget
  falls back to the default.
- Single flight is asserted twice: deterministically, with a producer held in
  flight while a second caller arrives, and against the real compiler, counting
  actual compilations under two concurrent identical requests. Both callers get
  the same result.
- Persistence is off by default, asserted as an absence: the run redirects the
  home, temporary and standard cache directories into a sandbox the test owns
  and fails if a byte lands there. An explicit snapshot writes, a loaded
  artifact is re-attributed and pinned again, a snapshot whose bytes disagree
  with their hash is rejected, an empty path is refused, and anything but the
  exact enabling value leaves writes off.

## Running

```bash
ctest --test-dir build -R '^pf_ZimplRegistry$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
