# pf_RefusalInventory_Workbench_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_RefusalInventory_Workbench_Tests.cpp` · CTest: `pf_RefusalInventory_Workbench` · Labels: `unit;fast;public`

The Workbench half of the refusal ledger. It holds the entries for the
scheduling, placement and observability capabilities the Workbench schema
declares, and it exists for the same reason as its siblings: a silent
capability claim cannot appear without failing a named test.

## What it verifies

- Six entries, each pinning the exact code, the exact document pointer and the
  exact message of its outcome. All six began as refusals and have since been
  flipped to assert acceptance instead — flipped rather than deleted, so a
  retirement is proved rather than merely no longer contradicted.
- The two placement modes and the three non-default run modes now round-trip
  whole, with their fields surviving, alternatives keeping their order, and the
  canonical bytes stable across the round trip. The observability settings do
  the same, and the block reaches the parsed document.
- Four positive controls make the rest mean something, so a future edit that
  refuses too much fails here as loudly as one that refuses too little: the
  unperturbed base definition, the run mode that has always executed, the
  observability defaults that state the status quo, and the catalog block, which
  is inert — never refused, and preserved exactly rather than quietly dropped.
- Document errors are kept distinct from withheld capabilities. A run mode
  outside the vocabulary is still refused, a counted schedule without its count
  is still refused, a counted schedule carrying an interval is still refused,
  and an unknown display value is still refused by the schema. These survived
  every retirement because they were never capability refusals.
- Every case is built to be valid in every respect except the one under test,
  with definitions assembled in memory and put through the codec, which keeps
  each case one fact away from a valid document and off the model-resolution
  path none of these rules concern.

## Running

```bash
ctest --test-dir build -R '^pf_RefusalInventory_Workbench$' --output-on-failure
```

The target requires the transport-free configure, `-DPF_BUILD_PROBLEM_INPUT_TESTS=ON`.
