# pf_StagingPlan_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_StagingPlan_Tests.cpp` · CTest: `pf_StagingPlan` · Labels: `unit;fast;public`

`pf_StagingPlan` decides what each node in a decomposition tree stages: which
unit is planned, in what order, from which bytes, and with which compilation
settings. These rules were once inline in a transport callback reachable only
by standing up a whole constellation. This test judges them directly — no
transport, no compiler, no adapter.

## What it verifies

- Unit assembly per role: a root master and a mid-level node's master half are
  master units, a price leaf and a resource leaf are subproblem units, and a
  mid-level node contributes one unit rather than two, because its subproblem
  half travels on its own module.
- Source composition: a price child's entry is the master's stub prefaced onto
  the child's own source, while a resource child carries its own source
  unprefaced. A mid-level node's master half compiles its own source like any
  master and carries its subproblem half's raw source separately. Compilation
  settings are asserted per role, because a master generates block structure and
  a subproblem never has.
- Children are planned before parents in walk order, each unit names the view
  node it came from, and every unit of one master shares an ordinal.
- Block assignment follows association order rather than identifier order, a
  repeated service identifier takes no second block, and all associations are
  still recorded even when the block map collapses duplicates.
- Data-file resolution is last-wins by name while keeping the first writer's
  position, each entry is tagged with the child it came from, and child
  templates come first per child with the per-service collection last.
- An unmatched region marker is reported on the master's status, one status per
  master, naming the offender. A behaviour nobody chose — the master compiling
  its published source unstripped — is pinned as today's behaviour, so a change
  must flip the test rather than delete it.

## Running

```bash
ctest --test-dir build -R '^pf_StagingPlan$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
The graph walk that feeds this planner is judged end to end by the staging
parity lanes instead, because constructing a graph needs the full toolchain.
