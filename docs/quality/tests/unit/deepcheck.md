# pf_DeepCheck_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_DeepCheck_Tests.cpp` · CTest: `pf_DeepCheck` · Labels: `unit;fast;public`

`pf_DeepCheck::classify()` turns a Zimpl compiler's diagnostics into one of
four causes, and that cause reaches every compile-failure message the reviewer
emits. This test pins the classifier against three diagnostics captured from a
real compile, plus stated variations on them. It never constructs a plan and
never compiles anything.

## What it verifies

- The three captured diagnostics — a syntax error, an unresolved include and an
  unresolved data file — each classify as themselves.
- Rule order is asserted directly, because the data diagnostic also carries a
  caret line: a missing file beats a parse complaint about the line that named
  it, so an unresolved data file is never reported as a syntax error and a
  syntax error is never reported as a missing file.
- The suffix is what separates an unresolved include from an unresolved data
  file: a `.zpl` name is an include, any other name is data, and the suffix test
  is case-sensitive, matching the filesystem.
- Anything else is reported as other, never guessed — no diagnostics at all,
  blank diagnostics, and a Zimpl error of none of the three shapes.
- The message extracted for the user is the first meaningful diagnostic line:
  the one carrying the line number for a syntax error, the one naming the file
  for the other two. Leading blank and whitespace-only lines are skipped, a
  silent failure still produces a message, a shape broken across two elements is
  not silently re-joined, and the pinned compiler commit never appears in the
  message.
- The compiled coverage table is compared against the tracked `coverage.tsv`
  row for row and field for field — same row count, five fields per row, and
  each of depth, shape, engines, placement and lane agreeing.

## Running

```bash
ctest --test-dir build -R '^pf_DeepCheck$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
