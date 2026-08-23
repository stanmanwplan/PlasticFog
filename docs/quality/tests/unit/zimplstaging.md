# pf_ZimplStaging_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_ZimplStaging_Tests.cpp` · CTest: `pf_ZimplStaging` · Labels: `unit;fast;public`

`pf_ZimplStaging` holds the text rules that turn a master's published model into
the stub a child is prefaced with: removing include statements and marked
regions, collecting the filenames they name, and reading off the variables the
stub declares. These rules once existed twice over, in places no test could
reach; this file checks the single implementation, with no transport and no
compiler linked.

## What it verifies

- Include handling: a mid-file include line is removed whole, both of two
  includes are removed, a source with none is unchanged, and each removed
  filename is collected in order. A last-line include is removed with or
  without a trailing newline, and an include inside a marked region is removed
  by the include pass first.
- Region handling: a paired region is removed with its markers and reports
  success, two regions are both removed, a region ending at end of file with no
  newline erases to the end, and an unmatched opening marker is reported as
  such while the earlier complete regions are still removed.
- Stub construction leaves the declarations and removes the rest, and prefacing
  a child joins the stub and the child's source with exactly one newline. A
  declaration outside the markers does reach the stub.
- Declared-variable extraction accumulates across a source, yields the base name
  of an indexed declaration, treats an underscore as part of an identifier, and
  skips declarations that are commented out in either comment style or trailed
  by a comment. A source with no declaration contributes none.
- Service-id collection narrowing is exercised for a present identifier, an
  absent one, and an empty collection.
- Two behaviours nobody chose are pinned as today's behaviour and labelled as
  such, so a change must flip the test rather than delete it: an include on the
  first line is not stripped and contributes no filename, and identifier
  matching in a collection is by substring, so a prefix reports found and the
  collection narrows to an entry that is not the identifier asked for.

## Running

```bash
ctest --test-dir build -R '^pf_ZimplStaging$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
