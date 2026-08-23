# pf_ServiceIdManager_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_ServiceIdManager_Tests.cpp` · CTest: `pf_ServiceIdManager` · Labels: `unit;fast;public`

Every service reads its own identifier from a small file at startup. This test
pins that read, and in particular the property that a failed read cannot be
mistaken for a successful one: the reader returns a boolean and writes the
value through an output parameter, so failure and the registry service's
legitimate identifier of 1 stay distinguishable.

## What it verifies

- Writing an identifier and reading it back round-trips, for each of the
  service identifiers the demonstration constellation uses, and the writer
  leaves no trailing newline — so a bare value at end of file still parses.
- Accepted line shapes are enumerated: a value terminated by a newline, by a
  carriage return and newline, or by a bare carriage return; trailing spaces and
  tabs stripped; content after the first line ignored; leading zeros accepted;
  the maximum representable value accepted; and the identifier 1 read as a
  success.
- Rejected shapes are enumerated just as explicitly, and none may hand a caller
  a usable identifier: an empty file, a file containing only a line ending,
  non-numeric content, digits followed by a letter, a leading space — rejected
  even when trailing padding would otherwise be stripped — a negative value, an
  explicit plus sign, hexadecimal notation, an embedded space, a value one past
  the maximum, a grossly out-of-range value, and a file that does not exist.
- On every failure the output parameter is left exactly as the caller set it,
  asserted against a sentinel no test file can produce. A successful read of the
  identifier 1 still delivers it, and a failed read never does.
- Writing to an unwritable path returns without throwing and creates nothing.

The reader tolerates a carriage return because the tree is edited across a
bridge that produces Windows line endings, but a leading non-digit is rejected:
it means a corrupt file far more often than deliberate formatting.

## Running

```bash
ctest --test-dir build -R '^pf_ServiceIdManager$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
