# pf_ServicesRepo_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_ServicesRepo_Tests.cpp` · CTest: `pf_ServicesRepo` · Labels: `unit;fast;public`

`pf_ServicesRepo` is the registry service's store of which services exist and
what type each is. This is a characterisation test: it records the behaviour as
it stands, including the parts that are awkward, so a change to any of them is
visible rather than silent.

## What it verifies

- Two properties of the class shape every case, and both are asserted rather
  than worked around: the database path is a fixed relative name resolved
  against the working directory, and the constructor deletes any existing
  database before recreating it. Constructing a repository is therefore itself
  destructive, and each case runs in its own directory.
- No database exists before construction; the constructor creates it in the
  working directory; the file survives destruction of the repository object;
  and reconstructing deletes what was there, with a service present beforehand
  and gone afterwards.
- Registration and lookup round-trip: an identifier is stored and read back, the
  expected counts come back per service type, and a duplicate identifier does
  not overwrite the stored type — the original row is retained.
- Query behaviour is characterised as it is: the exact query shape the
  application publishes returns the right service for each type, a row limit
  returns a single result, an unmatched type returns an empty result, and an
  empty query list or a mismatch between query and name counts also returns
  nothing.
- The raw query surface is recorded honestly: an arbitrary statement is executed
  verbatim, and one malformed query discards the results of the valid queries
  alongside it.

## Running

```bash
ctest --test-dir build -R '^pf_ServicesRepo$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`,
and is registered with its own working directory because the database path is
relative.
