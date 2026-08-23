# pf_ProblemInput_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `pf_ProblemInput_Tests.cpp` · CTest: `pf_problem_input` · Labels: `—`

This is the acceptance half of the problem-definition library: what a valid
document may say, how it canonicalises, and how an update against a running
system is judged. It links no transport, so the surface is exercised in one
process against the committed example documents.

## What it verifies

- Reading, writing and re-parsing a document reproduce the same content hash,
  through text and through a file, so the canonical form is stable rather than
  merely lossless.
- Successive submissions increment the revision and classify what changed,
  distinguishing an update that requires interrupting a solve from one that does
  not, while a replayed or stale update is rejected without disturbing the
  active snapshot.
- Parsing details that decide whether two readers agree: duplicate keys are
  rejected in strict mode and last-wins in permissive mode, JSON text must be
  valid UTF-8, and numeric tests compare exact integral values without rounding
  through a double.
- A file-backed resource cannot escape its declared root through a symbolic
  link, a replacement may take a new root from call options or omit its revision,
  and a mutation that would disconnect the topology is rejected transactionally.
- A document stating no solver comes back carrying each binding's role default,
  defaults are materialised in canonical JSON so a re-parse is byte-identical,
  and each role accepts every engine its table allows, with explicit engines and
  opaque options surviving the round trip.
- A node may present a different paradigm upward and downward. Results scopes,
  the control-command document and its accept matrix, command target expansion
  over a three-level tree, and the runtime summary round trip are each asserted,
  as is validating a command against the document embedded in a written-and-read
  topology snapshot, with an accept and a reject case per rule.
- Every optional block parses, canonicalises and round-trips byte-stably, and a
  definition stating none of them canonicalises to exactly the bytes it did
  before those blocks existed. Blocks the compatibility rules refuse are still
  preserved exactly: a refusal is not a reason to lose what the author wrote.

## Running

```bash
ctest --test-dir build -R '^pf_problem_input$' --output-on-failure
```

The target requires the transport-free configure, `-DPF_BUILD_PROBLEM_INPUT_TESTS=ON`.
