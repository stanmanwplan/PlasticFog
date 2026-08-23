# pf_SolverStateMachine_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_SolverStateMachine_Tests.cpp` · CTest: `pf_SolverStateMachine` · Labels: `unit;fast;public`

The solver state machine's transition table is a transcription of a committed
CSV fixture, and a transcription checked only by eye rots. This test reads the
fixture at run time and pins every row against the compiled table, then covers
the deferred-command queue that holds commands the machine cannot act on yet.

## What it verifies

- The fixture is asserted to carry 76 transition rows, so a row added or lost
  without updating the test fails immediately.
- A positive sweep constructs the right machine in each row's starting state,
  makes the row's guard hold, dispatches its trigger, and asserts the resulting
  outcome, destination state and action name.
- A guard-false sweep repeats every row that names a boolean guard with the
  guard failing, and asserts that the state does not move and the outcome is not
  "applied".
- A negative matrix covers, for both machines, every pairing of state and
  external command that no row covers — with grouped cells expanded — and
  asserts rejection with no state change.
- The two machines are kept separate: a command that belongs to one table is
  asserted absent from the other, rather than being silently tolerated.
- Durable re-entry is pinned for the machine that has it: from a completed
  state, one command reruns the previous problem and another applies updates
  before rerunning, each with its own action name. The other machine has no such
  path, and that absence is asserted too.
- Policy-dependent transitions, spot-update deferral and the
  resource-directed rows are each exercised as their own group.
- The deferred queue is first-in first-out within a release tag and isolated
  across tags: a held entry never reorders a released one, everything stays
  queued while the machine is busy, only the entries whose tag was released come
  out, and both the command identifier and its option strings are deep-copied.

## Running

```bash
ctest --test-dir build -R '^pf_SolverStateMachine$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
