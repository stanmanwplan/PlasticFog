# pf_Conductor_Supervisor_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_Conductor_Supervisor_Tests.cpp` · CTest: `pf_Conductor_Supervisor` (`unit;integration;public`), `pf_Conductor_Supervisor_Probe` (`integration;public`)

One source file, registered twice, because it holds two things: the
supervisor's unit surface, and a self-contained probe that measured how
readiness can be decided. The probe forks its own repository process on a
scratch port and touches no lane's domain.

## What it verifies

- Deploy planning is deterministic: two resolutions of one definition are
  byte-identical, the action list has the expected size and order — registry,
  overall-problem service, master, then subproblems in staged-pool order — and
  resolving writes nothing to disk.
- Each action records its own readiness criterion: the registry service is
  decided by its startup banner, a spawned registrant by its recorded
  registration, and each spawned service carries its own two clocks.
- Refusals leave nothing half-executed: spawning more leaves than there are
  staged directories, reusing a service id and naming an unknown profile are
  each refused with a stated reason rather than defaulted. An automatic binding
  records every fallback arm in the document's order — not only the first to be
  tried — and each arm states why it would fire.
- Process identity is a three-part match: a wrong start time is refused, which
  is the recycled-identifier case, a wrong command name is refused, and a dead
  identifier matches nothing, so draining would signal nothing. Draining
  reports both children drained and says when one that ignored the polite
  signal had to be killed.
- Sweeping removes dead and mismatched records, leaves live matching ones
  alone, and signals nothing — the report says zero processes were signalled.
- The probe halves run separately because the middleware pins its endpoint
  process-wide on first use. The first shows repeated create/observe/delete
  cycles working in one process with no service-level shutdown between them;
  the second shows the status channel silent across a healthy startup, so
  readiness comes from banners and recorded registrations instead.

## Running

```bash
ctest --test-dir build -R '^pf_Conductor_Supervisor(_Probe)?$' --output-on-failure
```

The target is built when the tree is configured with either
`-DPF_BUILD_UNIT_TESTS=ON` or `-DPF_BUILD_PROBLEM_INPUT_TESTS=ON`. Each probe
half skips itself, saying so, when no repository answers or the staged service
directories carry no binaries.
