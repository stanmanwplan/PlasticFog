# Test harness & fixtures

<!-- dc:status=polished dc:owner=DC4a -->

The end-to-end tests start a real constellation of services, submit a real
problem, and judge the result. This page describes how that is done safely and
repeatably: what the harness stages, how lanes are named and which ones run when,
what the fixtures are, and which tools support the whole arrangement.

## The harness stages copies

**The harness stages copies and never runs in the tracked directories.** Each
process gets its own working directory inside a run directory; the repository's
service directories are read-only inputs.

That is not tidiness. The services write into their working directory while they
run: the master and subproblem directories receive generated model, data and
matrix files over DDS, the registry creates its database there, and the
application writes its graph files. A test that ran in place would be a test that
rewrote its own inputs.

The whole constellation runs on an isolated DDS domain, and the domain id is
written only into the *staged* copies of the configuration files. Every worktree
contains identical service ids, so two constellations sharing a domain "**will
discover each other and interleave**, silently corrupting both runs." Isolation
is therefore mandatory rather than advisory, and a run directory is always
retained on failure.

## Runners and assertion scripts

Ten runner scripts stage and launch; thirty-nine assertion scripts judge. The
division is deliberate: a runner brings a scenario up and tears it down, and an
assertion script can be re-run on its own against a preserved run directory.

| Runner | What it drives |
|---|---|
| `run_scenario.sh` | the legacy demo path, with the fault-injection modes |
| `run_generalized.sh` | a `pf.problem_definition.v1` submission end to end |
| `run_reuse.sh` | one constellation, two campaigns |
| `run_nested.sh` | the nested topology, with a mid that is master and subproblem at once |
| `run_resource.sh` | resource-directed decomposition |
| `run_workbench.sh` | the `pf` front end, the conductor and the campaign scenarios |
| `run_engines.sh` | the engine matrix and the speculative-farming lanes |
| `run_inline.sh` | the fully inline document |
| `run_document.sh` | any deep-valid document, from a path |
| `run_spec_validate_deep.sh` | the deep validator over the corpus |

`tests/e2e/lib.sh` is the shared library they all use.

## Launch, readiness and teardown

Services are started in dependency order, and each one is gated on evidence that
it is actually up rather than on a delay. The infrastructure process is gated on
its object reference file becoming non-empty; each service is gated on its own
startup banner; and each registrant is additionally gated on the **cumulative
count of registrations observed by the registry**, because a startup banner is
printed before any transport setup and is therefore a weak gate — the
registration count "is the first output that proves a service is actually
discoverable." Completion is a specific line in the master's output, bounded by
a timeout.

Teardown runs on every exit path. It sends `SIGTERM` to every recorded process,
nudges each service's held-open standard input so a blocked read can observe the
stop flag, waits, and only then escalates — and a process that needed `SIGKILL`
is named in the summary, because "needing SIGKILL is a reportable observation,
not a silent cleanup detail." Termination is by recorded process id only; a
pattern-based sweep would reach another worktree's constellation.

Two service behaviours are worked around in the harness rather than changed in
production code: standard input must stay open for the process lifetime, or a
main loop reading from it spins at full CPU on end-of-file; and standard output
is block-buffered when redirected, so every process is launched line-buffered or
a completion marker can sit in a buffer long past the event.

## Assertions, and the false green they exist to prevent

The numeric assertions read the master's output: the objective against a
known-good value, an optimal status, the count of columns priced, and the
route-length values for the contended scenario. A tolerance applies to every
numeric check, because these values print with floating-point accumulation noise.

Those checks share one blind spot, and the harness treats it as the central one.
When the distributed path fails, the decomposition solver prices the missing
block locally with its internal fallback — and the fallback reproduces the
known-good answer exactly. A run has been observed "reporting 5.33, `Optimal`,
generate-vars 7 and the right three path lengths while every `REDUCED_COSTS`
write was failing and no subproblem service had published a single reply."

So a separate section asserts the traffic at the far end of the wire: each
subproblem service must have published its replies the expected number of times.
A count of zero and a count that merely disagrees are separate failures with
separate messages, because "zero means the service never took part, and the
message says in as many words that a correct objective above is not evidence of
participation."

The gate is itself testable. An environment-gated self-test mode kills the
subproblem services at the instant the first pricing request goes out, forcing
the exact blind spot: the solve completes with the **correct** objective, the
first four checks pass, and the participation check fails. That mode refuses to
combine with the other fault-injection flags and runs against one scenario only;
its only purpose is to prove on demand that the assertion can fail.

Fault injection is otherwise driven by explicit flags: a subproblem killed after
its first real reply, a subproblem never launched, a stale reply published with
correct correlation identifiers, and per-subproblem failure policies. Under a
degraded profile the objective is asserted **present and never compared** — "a
degraded run must never count as a 5.33 reproduction" — while the structured
timeout record naming the killed service becomes a hard requirement.

## The lane taxonomy

This is the part most easily misread, so it is stated exactly.

**`tests/tools/lanes.txt` is the canonical enumeration: 32 lines, one per lane,
`<ID>|<invocation>`.** `tests/tools/ag_matrix.sh` reads that file to drive the
whole matrix. For each lane it runs the invocation, filters the output down to
its verdict lines, normalizes them through `tests/tools/norm.sed`, and records a
line count and a digest — so "the matrix is byte-stable" is a claim about
comparable digests rather than an impression.

**One of the 32 lane ids expands to more than one run.** Lane `E1` is
`run_engines.sh --lane all`, and `--lane all` means the default CPU matrix: the
**seven** CPU lanes, run in one invocation. They are named in the script's own
dispatch — `pfe001`, `pfe004h`, `pfe-mixed`, `pfe-cuopt-refusal`,
`pfe-cuopt-stub`, `pfe-certify` and `pfe-fallback`. Running all 32 lane ids
therefore executes more than 32 scenarios.

**The engine runner offers more lanes than `lanes.txt` names.** Five of its
speculative-farming lanes appear individually in the file, as `K1`, `F1`, `D1`,
`S1` and `X1`. Three rider-timeout lanes and two GPU twins do not appear there at
all and are reached only by naming them. None of them is in `--lane all`, and the
script gives the reason: `all` stays the inherited seven "so that the CPU matrix
can be compared byte for byte against its own baseline" across a change to the
service binaries.

**The GPU-gated lanes are outside the matrix and cannot be added to it.** Two
smoke lanes and the two GPU twins require a real device and an installed library.
They run only when a gate variable is set, they are "NEVER part of `--lane all`",
and without the gate they print a skip and exit zero. The script states the
constraint plainly: `all` "runs on machines that have neither."

**The document lane is deliberately not one of the 32.** `run_document.sh` runs
any deep-valid definition end to end from a document path, and it is registered
with CTest under its own name. It is excluded from the lane file because "a lane
whose argument is a document has no one normalized output to be stable against."
It is a tool rather than a matrix anchor, and its runs are recorded rather than
compared against a fixed baseline.

The document lane also splits its checks, and the split is the whole point: the
instance-independent facts are asserted — exit code, an envelope, optimal status,
distributed pricing, no rejected command — while the comparison against the
document's own oracle is **reported**. "A disagreement is a FINDING for the
review. An assert that failed on it would invite editing the golden to go green."

## What the proven-combination table is, and how it is guarded

`tests/e2e/coverage.tsv` holds one row per document combination a lane has
actually run end to end, across five columns: topology depth, the per-boundary
shape walked root-down, the effective engine/role/level triples, the placement
form, and the lane that proved it. It is what the reviewer's coverage advisory is
derived from, and "a proven row removes the advisory for everyone."

A row is a claim that something ran, so only a passing run may add one. The
document lane prints the row a clean run proved and how to add it, and appends it
only when explicitly asked; it never rewrites the file on its own.

The binary does not read that file. A shipped executable "must not depend on a
path inside a source tree", so an identical set of rows is compiled into the
deep-check unit. **The two are held together by an automated guard**: the
`pf_DeepCheck` unit test locates the repository from its own source path, reads
the tracked file, and compares it against the compiled table field for field and
in order — including the lane column, "because it is the evidence for the row."

The guard found drift on its first run. Appending a newly proven row to the
tracked file left the compiled table one row behind, and the next run of the test
said so: `tracked 10, compiled 9`. Both now carry the row.

Three lanes seed no row, and the file says why rather than leaving the absence to
be noticed: two legacy demo lanes and the CLI-backend repeat of one of them
submit no document at all, and the reuse lane republishes an already-published
graph. One further row is deliberately absent even though the combination is
exercised — it is only reachable inside a GPU-gated lane, and "A reader on a
CPU-only machine has not proven it", so the advisory stands.

## Fixtures

`tests/fixtures/` holds what the lanes and unit tests run against.

- **Loose artifacts** for the two legacy scenarios: model, table, block and graph
  files captured from real runs.
- **Fixture directories** — `pf003m`, `pf004b`, `pf005x`, `pfe001`, `pfe004h`,
  `pfe006`, `pfi001`, `wb001`, `wb002`, `wb003` — each carrying the documents,
  models and data one family of lanes submits.
- **The state-machine table**, a tracked CSV of 76 transition rows, which the
  state-machine unit test asserts against row by row.
- **Parity and feature fixtures**: `staging_parity/`, `zimpl_features/`,
  `zimpl_parity/`, and four `known_limit_*` cases that pin what the system
  refuses rather than what it does.
- **`deep_adversarial/`**, 24 case directories, each holding a document, the
  models and data it needs, an `EXPECTED` file naming the code *and* the JSON
  Pointer the reviewer must produce, and a line saying what its single defect is.

The adversarial fixtures are worth a closer look, because their design encodes a
rule. Each case has exactly one defect and is "as small as the defect allows, so
that what fails is the defect and not the surrounding document", and nothing in
the directory is copied from a frozen fixture. Expectations can be negative: a
line may require that a code does **not** appear, which is how one case pins that
the codec refuses a document before the reviewer ever compiles it.

One code in that set is pinned as unreachable on purpose. The reviewer can report
a staging failure, but the one document that would produce it is refused earlier
by the codec — so it appears only as a negative expectation. The code stays in
the reviewer because "a reviewer that dropped it on the floor would be lying by
omission", and the day a document reaches the plan with an unassemblable master,
it is there to say so.

## Tools

`tests/tools/` holds the machinery the lanes and the gates share.

| Tool | What it does |
|---|---|
| `lanes.txt` | the canonical 32-lane enumeration |
| `ag_matrix.sh` | the matrix driver: runs each lane, normalizes, digests |
| `norm.sed` | the output normalizer the byte-stability claim rests on |
| `enc_gate.sh` | the encoding gate — see [Engineering practices](../practices.md) |
| `staging_parity.sh` | staging plan and re-dump parity, registered as two tests |
| `monolith_oracle.sh` | the independent-oracle comparison across every document with a recorded oracle |
| `deep_inventory.sh` | runs the real deep reviewer over every adversarial case and asserts code and pointer |
| `zimpl_parity.sh` | the Zimpl backend comparison |
| `highs_vendor.sh` | the vendored solver check |
| `cuopt_stub/` | a stub that lets the GPU engine's refusal and acceptance paths be tested without a device |
| `pf_InjectStaleCosts.cpp` | the stale-reply injector, built only when the test-tools option is on |

## Prompt-pack conformance

`tests/promptpack/` holds a conformance lane that makes four claims and, in its
own words, "no others": that the pack's two build paths produce byte-identical
output and that the binary path is byte-stable across consecutive runs; that the
capability snapshot the pack injects is byte-identical to what the tool reports;
that every golden and every adversarial document is run through **both** gates,
the codec and the deep reviewer, with each refusal pinned by code and JSON
Pointer; and that each shipped example is a coherent triple whose payload matches
the document beside it.

The order of authority is measured rather than asserted. A document the codec
refuses must produce byte-identical output with and without the deep flag,
because the codec runs first and such a document never reaches the reviewer.

The lane also carries the check most worth quoting. It searches the prompt-pack
trees for the shapes a model call takes — API hostnames, key names, outbound
requests — and fails if it finds one. Its own source is excluded from the search,
and the exclusion is explained rather than hidden: the only place those patterns
appear is the check's own pattern literal, and "a guard people ignore is worse
than no guard." The script's header states the broader claim the check protects:
"THERE IS NO NETWORK AND THERE ARE NO MODEL CALLS. Nothing in this lane, or
anywhere under `tests/`, contacts a language model."

## Running the tests

Each test group sits behind a CMake option that defaults to **off**, so an
ordinary configure builds the shipping executables and nothing else — a property
verified by building the binaries with an option on and off and comparing them
byte for byte. [Installation](../../getting-started/installation.md) lists the
options; turn on the ones you want and run CTest from the build directory:

```bash
cmake -S . -B build -DPF_BUILD_REGDB_TESTS=ON
cmake --build build
cd build && ctest --output-on-failure
```

!!! warning
    **The unit tests check with bare `assert()` — 553 occurrences across the
    forty sources — so a build with `NDEBUG` defined passes them vacuously.** The
    tests README states the consequence for the registration suite in as many
    words: it "is only meaningful in a build where `NDEBUG` is absent", the debug
    preset qualifies, and if the tests are ever run under a release
    configuration, "confirm with a deliberate mutation before trusting a green
    run."

One further trap is documented in the same place, because it wastes an afternoon
otherwise: turning a test option off in a build directory that previously had it
on leaves a stale test registration behind, pointing at a binary that is no
longer rebuilt. The cause is in the build system rather than this project — the
test file is only rewritten when testing is enabled — and the fix is to configure
a fresh build directory rather than reuse one.

Which tests exist, what each covers, and how the CTest names line up with the
source files is the [test index](index.md).
