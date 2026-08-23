# pf_ResourceDrive_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_ResourceDrive_Tests.cpp` · CTest: `pf_ResourceDrive` · Labels: `unit;fast;public`

`pf_ResourceDrive` reads a module's attributes into the resource-directed
boundaries it participates in, and reads a Zimpl symbol table into the alias map
those boundaries' names resolve through. Every failure mode on this path is
silent where it occurs — a misread boundary yields a child with no coupling
names, and the complaint that follows is about the document rather than the
reading — so the link is pinned here.

## What it verifies

- A resource master's attributes are recognised as resource-directed; a module
  with no attributes and a price-directed module are not, and a misspelled
  paradigm value is not accepted.
- Every field of a boundary is read: binding, parent and child node, coupling
  mode, epigraph symbol, and the child's service and subproblem identifiers,
  with a full 64-bit identifier parsing without truncation.
- Master-side coupling names are split on the separator the graph map actually
  uses — with a regression case asserting that a comma is not a separator — and
  surrounding whitespace is trimmed. An empty value and a lone separator each
  yield no names, and a second boundary's names stay separate from the first's.
- Multiple boundaries on one module are all read and come back in boundary-id
  order; a price-directed boundary on the same module is skipped; a boundary
  whose identifier itself contains a dot yields one boundary, not two, and the
  identifier is kept whole.
- A boundary that declares no epigraph reports none, and a child module reads
  its single boundary and its parent from its own side.
- The symbol table reader takes only variable records, not constraint records,
  maps an abbreviated name from its full name and a short name to itself, and
  yields no aliases from an empty or unparseable table.

## Running

```bash
ctest --test-dir build -R '^pf_ResourceDrive$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
