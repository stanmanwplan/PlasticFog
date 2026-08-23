# pf_Conductor_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_Conductor_Tests.cpp` · CTest: `pf_Conductor` · Labels: `unit;fast;public`

This test pins the conductor's control plane rather than its runtime: framing,
the verb table and error vocabulary, the capabilities document, single-instance
locking, autostart and path resolution. None of it needs a constellation.

## What it verifies

- Framing: one JSON object per line ending in exactly one newline; verb and
  version survive the round trip; absent arguments decode as an empty object; a
  correlation id is echoed with its original type, even from a rejected request.
  Non-JSON input, a missing verb, non-object arguments and a wrong or absent
  version each draw their own error code, and an error detail cannot overwrite
  the code or message.
- The verb table answers twenty-two verbs at version 1, the deferred-prefix
  list is empty — nothing is named and unimplemented — and an unknown verb is
  answered with the table. Version is decided before the verb.
- The capabilities document is byte-identical across two invocations and states
  which coordination methods, engines, placement modes, run-specification modes
  and log display modes execute. Engine roles, backend registry entries, the
  engine list's source and the one engine a probe may refuse are each asserted.
- Autostart connects to a live socket, spawns a conductor when none is
  listening, and reports a suppression rather than failing silently. The path
  override wins, the lock sits beside the socket, and the runtime directory is
  created 0700 explicitly rather than left to the umask.
- The lock refuses a second acquire while held and names the holder; tested
  against a killed process rather than a mock, it takes over a stale lock and
  reports both the staleness and the dead process.
- A real socket is exercised by a forked server: two requests round trip on one
  connection, an unknown verb still gets a reply, a second conductor refuses to
  start while the first keeps answering, and the stop verb is acknowledged
  before the daemon exits, leaving no socket or lock file behind.

## Running

```bash
ctest --test-dir build -R '^pf_Conductor$' --output-on-failure
```

The target is built when the tree is configured with either
`-DPF_BUILD_UNIT_TESTS=ON` or `-DPF_BUILD_PROBLEM_INPUT_TESTS=ON`.
