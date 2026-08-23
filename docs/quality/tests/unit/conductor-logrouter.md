# pf_Conductor_LogRouter_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_Conductor_LogRouter_Tests.cpp` · CTest: `pf_Conductor_LogRouter` · Labels: `unit;fast;public`

The log router fans several services' captured output into one stream and
presents it. Everything it decides is decided about text, so the test asserts
against real files it writes into a scratch directory, mixing structured
records with ordinary unstructured service output.

## What it verifies

- The fan-in label is `[service|pid|utc]` followed by the payload, and the
  payload passes through byte for byte — whitespace included. An empty service
  name or empty payload still produces the shape rather than a guess.
- Structured detection: a log record is recognised and its severity read, even
  behind leading whitespace. An ordinary line, an empty line, a JSON object
  with no severity, an unparseable line that starts with a brace, and a
  severity this build does not know are all treated as unstructured rather than
  silently mapped.
- Severity filtering is inclusive at the floor, drops what is below it, and
  always passes unstructured lines — a floor cannot hide output the router
  could not classify. The level vocabulary is lowercase and a near miss is
  refused rather than guessed.
- Fan-in reads sources in configuration order, labels every line with its own
  source's pid, and marks each line structured or not.
- Following returns only what arrived since the last collect; a fragment with
  no newline yet is withheld and then emitted whole once finished, still
  parsing as the record it always was.
- A source that cannot be opened does not stop the others, and no line is
  attributed to it. A file that shrank is rewound rather than seeked past, so a
  follower cannot silently stop following.
- The tmux presentation is asserted as command shape: one command per source,
  the first opening a detached session and later ones splitting it, every pane
  running `tail -F` on the captured file rather than the service, paths
  shell-quoted, and no sources producing no commands rather than an empty
  session.

## Running

```bash
ctest --test-dir build -R '^pf_Conductor_LogRouter$' --output-on-failure
```

The target is built when the tree is configured with either
`-DPF_BUILD_UNIT_TESTS=ON` or `-DPF_BUILD_PROBLEM_INPUT_TESTS=ON`.
