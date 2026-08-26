# Workflow overview

<!-- dc:status=polished dc:owner=DC2 -->

This page is the working loop: what you author, the two gates it has to pass,
the optional agreement check, the submission itself, and how results come back.
Every step names the Workbench verb that performs it and links to the page that
documents that step in full.

## The loop

    write                                      the problem definition
      ->  pf spec validate                     gate 1, the codec
      ->  repair
      ->  pf spec validate --deep              gate 2, the reviewer
      ->  repair
      ->  run_document.sh --agree              optional: the agreement protocol
      ->  pf spec import  /  pf run            submit and execute
      ->  pf results                           read the answer back

The order of the two gates is not advice. The codec runs first, and a document
it refuses never reaches the reviewer — so a schema refusal and a compile
failure never arrive in the same report. Repair the codec refusal and run again
to find out what the compiler has to say.

## Author

What you write is one JSON document, `pf.problem_definition.v1`, called a
**problem definition**. It declares four things — the identity of the problem,
the models and data it reads, the topology that carries the decomposition, and
the execution policy — beside its `schemaVersion` and three optional blocks,
`runSpec`, `observability` and `catalog`.
[Problem definitions](problem-definitions.md) is the tour of the document;
[Zimpl reference](zimpl.md) covers the model side.

There are three routes to a first draft and they end at the same document.

**By hand, from the corpus.** `promptpack/examples/` holds ten worked triples —
a request, a response envelope and the document it carries — one per input shape
and mode. Every one is validated on each test run, so a golden that stopped
being correct would turn the suite red. Copy the one whose shape matches yours
and change the story.

**With a chat model.** `pf promptpack build --mode <mode>` assembles a single
text bundle for the kind of input you are holding — prose, a written
formulation, a model in another algebraic modelling language, a flat Zimpl
model, or a change to a definition already submitted. You paste the bundle in
front of your request and the model answers with one JSON object carrying the
document inside it.

**With a coding agent.** The repository carries a skill file an agent can be
pointed at, which tells it to build the pack, draft the response, run both
gates itself, repair against the report at most three times, and then stop and
show you what it got. [Authoring with an LLM](llm-authoring.md) covers both
model-assisted routes.

Whichever route you take, the gates are the same.

## Gate one: the codec

    pf spec validate --file <doc> --source-root <dir>

The codec proves that the document satisfies the schema; that the topology is
one connected rooted tree with consistent levels and roles; that every coupling
declaration is owned by a node on its own boundary; that the placements and the
run spec are internally consistent; that every engine is legal for the role it
sits at; and that the constraint markers in each model are paired, unnested and
in order.

It proves nothing about whether any model compiles. The codec never runs Zimpl.

Every refusal names a **stable code** and the exact JSON Pointer it fired at:

    error [run_spec.count_required] /runSpec/count: Run mode 'counted' requires 'count'.
           ^ code                    ^ pointer      ^ message

Match on the code. Edit at the pointer. Never key a repair on the message's
wording — it is human text and may be reworded between builds. Every code, its
pointer form and a one-line repair are in
[Problem input](../reference/api/problem-input.md).

## Gate two: the reviewer

    pf spec validate --deep --file <doc> --source-root <dir>

`--deep` stages every compile unit the runtime would build and compiles each one
in process, then reads the compiled artifacts and checks the authoring
conventions the compiler cannot see: that every unit compiles; that no row
carries two children's service ids; that no unit's objective leaves a sibling's
columns alive; that master rows sit inside the constraint markers and block rows
outside; that the block generator accepts the master's compiled model; that
every coupling symbol on a resource boundary is a real column on its own side;
and that a resource child's recourse is continuous.

!!! warning
    `--deep` is compile-and-stage, not solve. It never solves anything, it never
    contacts a registry, and it says nothing about whether your arithmetic is
    the arithmetic you meant. A clean deep gate is a statement about text and
    structure.

A deep-gate compile failure carries one field the codec's refusals do not, and
you match on it too:

    error [zimpl.compile_failed] /resources/models/press_line/source: ... cause=syntax
                                                                          ^ cause

The `cause=` token is one of `syntax`, `data_unresolved`, `include_unresolved`
or `other`, **and the cause is the repair**. An unresolved include and an
unresolved data file produce the same diagnostic shape — a master resolves its
includes out of the data files of its own compile request — so the token is the
only thing that tells them apart.

Two of the reviewer's checks catch defects that are otherwise **silent**. A run
that carries a row spanning two children, or an objective that leaves a
sibling's columns alive, completes, reports `optimal`, and gives the wrong
number. No lane catches either. They are not cosmetic.

**Re-run both gates after every repair.** A repair aimed at a codec code can
break a compile: renaming a model changes the name every `include` of it must
use, and moving a row out of a constraint region puts it into every child. A
repair aimed at a compile code can break the codec: deleting a marker to silence
a duplicate-name complaint produces a marker-pairing refusal instead.

## What a refusal is not

Two report items look like defects and are not.

`placement.deep_requires_explicit` says the document uses **query placement**,
which resolves service ids against the registry at submit. A dry run contacts no
registry, so the reviewer refuses rather than compile a graph whose ids you
never wrote. There are exactly two repairs and they answer different questions:
rewrite the placements as `explicit` with real service ids if you want the deep
gate, or leave them alone and validate without `--deep` if you want discovery.
Changing the models or adding data is not a repair.

`coverage.unproven_shape` is an **advisory**. It says the definition is valid
and executable, and that one dimension of it — a depth, a shape, an engine at a
role and level, or a placement form — has never been run end to end by any test
lane. The line begins `warning`, never `error`; the family is `coverage.`; it
never appears without `--deep` and it never changes the exit status. Do not
repair it by editing the document toward a proven combination: that changes what
you asked for in order to quiet a message that says nothing is wrong.
`--no-advisories` suppresses `coverage.` items and only those.

## The agreement protocol

Before you submit, you can have the same problem solved twice and compare.

    tests/e2e/run_document.sh --problem <doc> --source-root <dir> \
        --expect <your hand oracle> --agree

The lane runs the document end to end on a private constellation derived from
the document's own service ids, then assembles **the same problem as one Zimpl
model**, solves that with a command-line solver, and prints three lines:

    objective=<what the decomposed run reported>
    oracle=<your hand oracle> agree=<yes|no>
    monolith=<what one solver got from the whole problem> solver=<name> agree=<yes|no>

A decomposition that agrees with itself proves nothing. A decomposition that
agrees with a separately solved monolith proves it decomposed *the problem you
wrote*. Whether the problem you wrote is the problem you meant is what the hand
oracle is for, which is why the protocol compares against your enumeration
rather than replacing it — so derive the answer by hand where the instance is
small enough, and put the enumeration in `problem.metadata`.

An `agree=no` means one of exactly two things, and which side matches your
oracle is what tells them apart. The lane prints the diagnosis itself when you
pass `--expect`:

| monolith vs oracle | run vs oracle | What you have found |
|---|---|---|
| agrees | disagrees | a **runtime limit** — your document is right and this build did not solve it |
| disagrees | disagrees | suspect the **assembler** first, then your **document** |

The assembled model is available on its own, without the run:

    build/pf_App --problem <doc> --source-root <dir> --dry-run --deep \
        --monolith /tmp/monolith.zpl

A shape the assembler cannot express is refused with
`monolith.unsupported_shape`, never approximated — so a file you get back is one
you can trust. [Decomposition paradigms](../architecture/decomposition.md) lists
the runtime limits a disagreement may have found.

## Submit and run

    pf spec import <doc>
    pf run <app[@rev]>

`pf spec import` puts the document in the catalog, which is immutable,
content-hashed and parent-linked: a revision is never edited, and re-importing
identical bytes records a new revision of the same content rather than
overwriting anything. `pf run` resolves a reference to one revision and executes
it. If the services are not up, `pf deploy plan` shows what would be started and
`pf deploy start` starts it.

The document's own `runSpec` decides how many times a submission executes and on
what cadence — once, a fixed count, continuously, or on an interval — and
`pf campaign start` is the verb that activates a revision under that policy.
[Workbench reference](workbench.md) is the whole verb surface, with a worked
example per verb.

## Read the results

    pf results <app>
    pf results --run <id>

A plain query returns the rows a run produced; `--follow` streams them as events
from a resumable cursor. Results are persisted per run, one row per envelope the
run's own results document carried, stored as the document carried it.

What comes back is decided by the `execution.results` block of the document:
which node's answer you want, the file it is written to, how long to wait, and
whether to filter to particular variables.
[Results](../reference/api/results.md) documents the envelope,
[Files & artifacts](../reference/data/artifacts.md) covers where it lands on
disk, and `pf logs` tails the deployment's streams while a run is in flight.
