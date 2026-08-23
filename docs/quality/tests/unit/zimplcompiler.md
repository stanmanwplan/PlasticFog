# pf_ZimplCompiler_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_ZimplCompiler_Tests.cpp` · CTest: `pf_ZimplCompiler` · Labels: `unit;fast;public`

Compiling a Zimpl model in-process, inside a long-lived service, is what makes
this unit risky: a library written as a command-line program may exit, leak or
leave global state behind. A parity harness proves the compiled bytes; this
test covers what exists only because the compile happens in a process that must
survive it.

## What it verifies

- The error path is caught rather than fatal: a failed compile reports a
  non-zero status, produces diagnostics and no artifacts at all, and a good
  compile immediately afterwards succeeds in the same process and is
  byte-identical to the golden.
- Repeat compiles do not grow without bound — peak memory plateaus across two
  hundred alternating good and failing compiles, with every good one yielding
  the golden outputs and every failing one leaving no artifacts.
- Global compiler state is reset on every compile: one constraint-name format
  does not change the next compile, asserted by producing the second format's
  golden output immediately after the first. Both storage modes behave as
  documented — one leaves its outputs on disk and reports its staging directory,
  the other removes it and reports no path — and nothing reaches the process's
  own standard output.
- The request digest identifies a request: it is a hex SHA-256, insensitive to
  input file order, and it moves when any input byte, an input name, a define,
  the constraint-name format or the translation-table request changes — while a
  define the model ignores changes no output byte. Both backends report the same
  digest for one request.
- Names and defines are kept away from a shell: absolute and nested paths,
  parent-directory references, over-long names, shell punctuation and the
  leading characters that would open a pipe or start an option are rejected,
  with the refusal explaining itself and producing no artifacts, while ordinary
  model and data names are accepted.
- The alternative backend compiles the same fixture to the same golden outputs,
  reports the child process's output, and applies the same refusal to a define
  carrying shell punctuation.

## Running

```bash
ctest --test-dir build -R '^pf_ZimplCompiler$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
