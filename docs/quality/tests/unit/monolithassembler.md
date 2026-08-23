# pf_MonolithAssembler_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_MonolithAssembler_Tests.cpp` · CTest: `pf_MonolithAssembler` · Labels: `unit;fast;public`

The monolith assembler flattens a decomposed problem into one model, which is
how a decomposed answer can be checked against an undecomposed one. An
end-to-end tool pins the numbers; this test judges the assembly rules one at a
time over hand-built miniatures, so a failure says which rule broke. It
compiles nothing and needs no solver.

## What it verifies

- Statement splitting respects string literals and comments: a `#` inside a
  string does not start a comment, a real comment line is dropped, statements
  come back trimmed. Renaming operates on tokens, not substrings — a longer
  name containing the renamed one is left alone, and a data file name inside a
  string literal is untouched. Includes splice in once even when a name is
  included twice, and an include the unit does not carry is reported rather
  than dropped.
- On a nested price-directed document, a mid-level node's rows are merged and
  namespaced by service id while the root's keep their spelling; the root's
  objective survives and the mid's does not, leaving exactly one objective. A
  column an ancestor declared is interface and not namespaced, a private column
  is, and two units carrying different bytes under one name both survive.
- On a resource-directed document the epigraph column is dropped with the rows
  that mention it and substituted by zero in the objective, because a monolith
  sees the recourse and pays it; the child's recourse cost is added, its linking
  column renamed to the master's, its redeclaration dropped, its rows
  namespaced. A mixed document is checked the same way, one rule at a time.
- A binding the assembler has no rule for is refused rather than approximated:
  one refusal per boundary, with a code, a pointer to the smallest document node
  that decides the shape, and a message naming the binding. Nothing partial is
  produced, a refused result cannot be written, and a plan with no root master
  is refused under the same code.

## Running

```bash
ctest --test-dir build -R '^pf_MonolithAssembler$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
