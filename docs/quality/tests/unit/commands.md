# pf_Commands_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_Commands_Tests.cpp` · CTest: `pf_Commands` · Labels: `unit;fast;public`

`pf_Commands` is the container the control plane passes by value between
modules, so its copy semantics decide whether two holders end up sharing one
command set. This test pins ownership: deep-copy independence, transfer on
insertion, payload lifetime, and survival under churn.

## What it verifies

- Copy construction and copy assignment produce distinct element objects, not
  aliases, and clone the whole payload — command id and option vector, not just
  the count. Independence is asserted in both directions: mutating the copy
  leaves the original untouched and mutating the original leaves the copy
  untouched. This is the assertion a shallow copy fails and every size or
  round-trip check passes.
- Assignment over a pre-loaded target releases what it replaces, and
  self-assignment preserves the contents rather than destroying them.
- Passing a command set into another holder clones it, so mutating the receiver
  does not reach the source, and fanning one source out to several holders
  leaves each holding distinct objects.
- Insertion stores the pointer it is handed rather than a copy, so a caller
  that keeps its handle can still append options afterwards and see them
  through the container — the behaviour the graph-map parser depends on — and a
  copy taken after that parse captures the late options.
- Removal reports what it removed and takes the matching command only; clearing
  and resetting empty the container, and reset also clears the recipient.
- Moves transfer the same object rather than cloning it.
- A cloned payload is independent, survives the destruction of its original,
  and remains writable afterwards; self-assignment of a payload is safe.
- Construct, copy, assign and destroy at volume, with option payloads attached,
  disturb no object and leave the original intact — where shared elements would
  abort rather than leak slowly.

The file also records the manual `valgrind` invocation used to check for leaks,
which CTest cannot assert.

## Running

```bash
ctest --test-dir build -R '^pf_Commands$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
