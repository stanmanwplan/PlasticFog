# pf_Graph_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_Graph_Tests.cpp` · CTest: `pf_Graph` · Labels: `unit;fast;public`

`pf_Graph` records the decomposition topology — which module talks to which —
and serialises it to a graph file and a companion map. This test characterises
that behaviour with modules constructed as plain objects: no participant or
transport entity is created, though the header's includes mean the target still
needs the full toolchain configure.

## What it verifies

- Copying is prohibited at compile time, asserted with static assertions,
  because the graph owns and deletes its map.
- Adding a fresh node or module succeeds and adding a duplicate identifier
  fails, including a subproblem colliding with a master's identifier.
- A full round trip: modules are added, both files are written, the serialised
  text names every expected edge, and the combined string is the graph followed
  by the map. Rewriting recreates the file.
- A mid-level node — a master to its children, a subproblem to its parent —
  survives serialisation with both halves of its source byte-equal and its
  flags, version, source name and every attribute intact, its sibling leaf
  still reconstructing.
- A map written before mid-level nodes existed still reconstructs, with an
  absent section yielding an empty half rather than an error, and its
  attributes and commands surviving.
- Identifiers wider than 32 bits are kept whole: two masters sharing their low
  32 bits are distinct vertices, lookups and edges carry the full identifier,
  and no truncated vertex appears in the file. A graph and map that disagree do
  not crash the walk — traversal terminates safely on an orphaned vertex.
- A committed graph fixture reads back, every line confirmed to be an edge pair
  and the application's own master identifier found in it. A node that is a
  master without being a subproblem reconstructs with both flags correct, so
  setting one does not clobber the other.

The file records what it deliberately does not cover: the error paths that
terminate the process, which would need a forking test.

## Running

```bash
ctest --test-dir build -R '^pf_Graph$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`,
and runs in its own working directory.
