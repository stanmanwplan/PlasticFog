# pf_Mps2English_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_Mps2English_Tests.cpp` · CTest: `pf_Mps2English` · Labels: `unit;fast;public`

`pf_Mps2English` renders a solved model back into readable prose: the
objective, the constraints, and each variable's value beside a description.
This is a characterisation test over golden fixtures — real MPS and symbol-table
files harvested from a verified end-to-end run, not hand-built — so it asserts
what the conversion does today rather than what it might ideally do.

## What it verifies

- Argument validation is reported as an explicit message, not a partial
  rendering: an empty problem name, a negative variable identifier, an MPS file
  that cannot be opened, a symbol table that cannot be opened, and a first call
  that supplies neither file while nothing is stored.
- A golden conversion of the real model names the problem and produces the
  objective, constraint and solution sections. Variable names are the original
  modelling names recovered through the symbol table rather than the shortened
  forms in the MPS file, the supplied descriptions are rendered, and
  constraints carry a relational operator taken from the MPS row types.
- Persistence works both ways: a second call supplying no files reuses the
  stored static data and the stored descriptions, and a partial update stores
  the new value, keeps the stored description when the update supplies an empty
  one, and leaves the omitted variables untouched.
- A different model renders differently, which shows the conversion is driven
  by the files rather than by anything cached across problems.
- Two problems can share one database file and each remains retrievable.

Each case uses its own database inside a temporary directory, because the
conversion persists into that file and sharing one would make the cases
order-dependent.

## Running

```bash
ctest --test-dir build -R '^pf_Mps2English$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
