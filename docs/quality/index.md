# Philosophy & methodology

<!-- dc:status=polished dc:owner=DC4a -->

This section is about how PlasticFog is verified, and why the test suite has the
shape it does. This page states the principles; the rest of the section shows
the mechanisms, the harness, and the tests themselves.

The short version: tests were written with the features they pin rather than
after them, the suite is layered so that most of it runs in seconds, and no
objective a solve reports is ever checked against the system that produced it.

## Tests are written with the feature they pin

Every capability in this framework arrived with the test that holds it to
account, and the two were reviewed together. That ordering has a consequence
worth stating plainly: a capability that could not be tested was not landed. The
clearest examples are the ones where a field was *deliberately not added* —
carrying a value that nothing yet reads would be, in the project's own words, "a
shape no test could hold to account."

The same rule runs the other way. When a refusal is retired and a document that
used to be rejected starts to parse, the value it carries becomes a value a
reader consumes, and the structure that carries it lands in the same change as
the test.

## The suite is layered

Three layers, and the boundaries between them are about what a test needs in
order to run.

**Fast unit tests.** Most of the suite is plain C++ test binaries that link a
unit and check it directly. They need no network, no daemon and no solver
constellation, and they are labelled `fast` for that reason.

**Targets that need no transport.** The problem-input library — the document
codec, the JSON layer, the content hash — links no DDS, no COIN-OR and no
SQLite, and the build carries an option that configures it and its tests alone.
So the entire authoring contract can be tested on a machine with none of the
runtime installed. The same property is why several higher layers, including the
control API's framing and verb table, are unit-testable "without a socket,
without a catalog, and without a running constellation."

**End-to-end lanes.** The rest is what only a running system can answer: a real
DDS constellation, real services, real solvers, and a real answer compared
against an independent one. These are the slowest tests and the ones that prove
the claims a user cares most about.

The counts, each enumerated from the file that defines it:

| Thing | Count | Where it is defined |
|---|---:|---|
| CTest test names | 50 | `add_test(NAME ...)` in `CMakeLists.txt` |
| — driven by a C++ unit-test binary | 41 | the command names a build target |
| — driven by a shell script | 9 | the command names a script under `tests/` |
| Unit-test source files | 40 | `tests/unit/` plus three at the repository root |
| End-to-end lanes | 32 | `tests/tools/lanes.txt` |
| End-to-end assertion scripts | 39 | `tests/e2e/assert_*.sh` |
| End-to-end runner scripts | 10 | `tests/e2e/run_*.sh` |
| `assert(` occurrences in unit-test sources | 553 | counted across the 40 sources |

Forty-one binary-driven names over forty source files is not an arithmetic
error: one source file is registered twice, under two names, because it takes a
flag that selects which half of it runs. The [test index](tests/index.md)
reconciles the two columns row by row.

The last row is a lower bound on cases rather than a count of them. A single
test function commonly asserts several independent facts, and the end-to-end
assertions are not in the figure at all.

## Verification is independent, by design

**A decomposition that agrees with itself proves nothing.** That sentence is the
premise the whole verification strategy rests on. Every lane asserts an objective
against a number, and a number derived by the same reasoning that built the model
is not evidence that the model is right.

So the objectives are checked against an independent oracle: the same problem
written out as one monolithic model, compiled with the vendored Zimpl and solved
with a vendored CPU solver, cross-checked on a second solver. No lane's expected
value was read off the system that produces it.

That method is a tool rather than a habit. A user can assemble the monolith for
their own document and gate on the comparison; one of the shell-driven tests runs
the comparison across every document in the tree that carries a recorded oracle.
[Engineering practices](practices.md) describes what that catches — including the
failure mode this project treats as the worst one, a wrong answer that arrives
well-formed and labelled `optimal`.

## How a claim is established

Claims about this system are distinguished by how they were established, not by
how confident their author was. Three kinds recur:

- **Derived by hand** — worked out on paper before the machinery that produces
  the number existed, and reproducible from the derivation alone.
- **Measured** — read off a green lane and recorded in the report of the run
  that produced it, reproducible by running the lane named beside it.
- **Recorded** — measured once, on real hardware, asserted by nobody. Evidence
  about what happened, and deliberately not an oracle for what must happen next.

The distinction exists to protect one rule, which the project states in a single
line: **an oracle a runtime disagrees with is a finding to stop on with both
numbers, and an assertion adjusted to fit a runtime is a fabrication.** A
disagreement is a result. Editing the expectation until the machine agrees with
it destroys the only evidence the test was carrying.

## Labels, as the build file defines them

CTest labels come from `set_tests_properties(... PROPERTIES LABELS ...)` in
`CMakeLists.txt`. Forty-six of the fifty registered names carry labels; four do
not.

| Label set | Names |
|---|---:|
| `unit;fast;public` | 38 |
| `integration;distributed;public` | 5 |
| `integration;public` | 2 |
| `unit;integration;public` | 1 |
| *(no labels)* | 4 |

`fast` and `distributed` mean what they say: a `fast` test needs nothing but the
binary, and a `distributed` one starts a constellation. `public` reflects a
design intent recorded outside the code — that the open regression and
conformance suite is the trust anchor, with any proprietary assurance tier kept
separate — and it currently appears on every labelled test.

**This is not a clean taxonomy, and it should not be presented as one.** Three
names driven by shell scripts carry `unit;fast;public`, because what they do is
cheap and deterministic even though they are not C++ binaries. One name carries
both `unit` and `integration`. Filter by label to select a set of tests, not to
infer what a test is.

## What this section contains

[Engineering practices](practices.md) covers the verification mechanisms: the
independent oracles, the red/green gates, the review discipline, and the
machine-checkable reporting behind them.

[Test harness & fixtures](tests/harness.md) covers how the end-to-end tests run:
staged copies, an isolated domain, the lane taxonomy, the fixtures and the tools.

[Test index](tests/index.md) lists every unit test and every lane, with a page
for each.
