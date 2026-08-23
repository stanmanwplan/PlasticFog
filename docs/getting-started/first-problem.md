# Your first problem

<!-- dc:status=polished dc:owner=DC1 -->

This page walks the whole path once, at story level: decide what you are
decomposing, write the problem definition, put it through the two gates,
submit it to a running constellation, and read the results back. Each step
links to the User Guide page that documents it properly; nothing here is a
substitute for those.

You need a build (see [Installation](installation.md)) and, for the last two
steps, a running constellation.

## Know the answer before you ask the question

Start with an instance small enough to solve by hand, and solve it by hand
first. The authoring guide's worked example is a community radio station with
two studios sharing one night engineer who gives the building five hours.
Each studio broadcasts every night in one of two formats: for studio A, live
costs 2 and consumes 4 engineer-hours, taped costs 6 and consumes 2; for
studio B, live costs 3 at 4 hours, taped costs 5 at 1 hour. Four combinations,
two of them over budget, and the cheapest feasible pair costs 7.

That enumeration is your **oracle**, and it does more than give you a number to
check against. Notice that each studio's own cheapest choice is `live`, and
that the sum of the two independent minima is 5 — better than the true optimum,
and unreachable. A run that failed to coordinate the two studios could not land
on 7 by accident. That property is what makes an instance worth decomposing
rather than solving flat, and it is what you should write into the document's
`problem.metadata` so the next reader knows why the shape is what it is.

## Name the shape

Two units, each with an internal choice, contending for one budget that a
parent hands out, is the price-directed shape: Dantzig–Wolfe. The station is
the master holding the single shared-resource row; each studio is a
subproblem. Root over leaves with nothing in between — the flat shape.

If instead the parent were fixing a decision the children then had to live
with, and the children were sending back constraints on that decision rather
than proposals, you would be looking at the resource-directed shape: Benders.
[Decomposition paradigms](../architecture/decomposition.md) explains the
difference and what nests inside what.

## Write the definition

A **problem definition** is one JSON document conforming to
`pf.problem_definition.v1`, and it carries four parts: `problem` (identity,
description and metadata), `resources` (the Zimpl models and the data they
read), `topology` (the nodes, their services and solver engines, and the
boundaries between them), and `execution` (limits, tolerances and what results
come back).

The part that matters most is the one that is easiest to underestimate. A
definition is not a model file with a wrapper around it. Your Zimpl says what
the arithmetic is; the topology says how the problem is cut apart — which rows
stay at the master, which index separates the blocks, who owns each symbol that
crosses a boundary. A reader cannot recover those decisions from the model
alone, which is why they live in the document rather than in a comment.

[Problem definitions](../guide/problem-definitions.md) is the anatomy of the
document, part by part. [Zimpl reference](../guide/zimpl.md) covers the model
side: the constraint markers that separate master rows from block rows, the
naming convention the block generator reads, and what the embedded compiler
supports.

You have three routes to a first draft, and all three end at the same document.
You can write it by hand, copying the closest of the ten worked examples under
`promptpack/examples/` — a natural-language story, a mathematical statement, a
legacy Zimpl model, a foreign algebraic modelling language, and a patch against
an existing document are all represented. You can hand a model generator the
prompt pack, built with `pf promptpack build --mode <mode>`, and review what
comes back; [Authoring with an LLM](../guide/llm-authoring.md) describes that
route and how it is evaluated. Or you can start from one of the shipped example
documents under `examples/` and edit it down.

Models may be referenced as files or carried inline in the document itself. An
all-inline document is what a model generator naturally emits, and the runtime
executes it directly — a fixture in the test suite exists precisely to hold that
path honest.

## Gate one: the codec

    pf spec validate --file <doc> --source-root <dir>

The codec gate proves that the document satisfies the schema; that the topology
is one connected rooted tree with consistent levels and roles; that every
coupling declaration is owned by a node on its own boundary; that placements and
the run spec are internally consistent; that every engine is legal for the role
it sits at; and that the constraint markers in each model are paired, unnested
and in order.

It proves nothing about whether your models compile. The codec never runs
Zimpl. That is deliberate: the codec runs first so that a document it refuses
never reaches the compiler, and a schema error and a compile error therefore
never arrive in the same report to confuse each other.

Repair against the refusal codes rather than against the prose, and re-run.

## Gate two: the deep gate

    pf spec validate --deep --file <doc> --source-root <dir>

`--deep` stages every compile unit the runtime would build and compiles each one
in process, then reads the compiled artifacts and checks the authoring
conventions the compiler itself cannot see: that no row carries two children's
ids, that no unit's objective leaves a sibling's columns alive, that master rows
are inside the markers and block rows outside, that the block generator accepts
the master's compiled model, that every coupling symbol on a resource boundary
is a real column on its own side, and that a resource child's recourse is
continuous.

!!! warning
    `--deep` is compile-and-stage, not solve. It never solves anything, it never
    contacts a registry, and it says nothing about whether your arithmetic is
    the arithmetic you meant. A clean `--deep` is a statement about text and
    structure.

Re-run **both** gates after every repair, not just the one that failed. The two
are genuinely coupled: renaming a model to satisfy a codec refusal changes the
name every `include` of it must use, and deleting a marker to silence a compile
complaint produces a marker-pairing refusal instead.

If you are driving the app directly rather than through the Workbench, the same
gate is available as a dry run, and `--deep` requires `--dry-run` there:

    build/pf_App --problem <doc> --source-root <dir> --dry-run --deep

## Optional: check the decomposition against a monolith

Before you submit anything, you can have the same document solved twice — once
decomposed, and once as a single assembled model handed to a command-line
solver — and compare both against your hand oracle:

    tests/e2e/run_document.sh --problem <doc> --source-root <dir> \
        --expect <your hand oracle> --agree

A decomposition that agrees with itself proves nothing. A decomposition that
agrees with a separately solved monolith proves that it decomposed *the problem
you wrote*. Whether the problem you wrote is the problem you meant is what the
hand oracle is for, which is why the protocol compares against your enumeration
rather than replacing it. [Workflow overview](../guide/workflow.md) covers the
agreement protocol and how to read a disagreement.

## Submit

Register the document with the catalog, then run it:

    pf spec import <doc>
    pf run <app[@rev]>

`pf` is a thin client. It holds no catalog and no runtime state of its own; every
question that needs the store or the constellation to answer it goes to the
conductor, which is a resident daemon. If no conductor is running, `pf` starts
one and connects to it — a missing socket is not an error — and the conductor it
started outlives the command that started it.

A reference like `<app>` or `<app>@<rev>` may match more than one catalog
revision. When it does, `pf` prompts you interactively and fails non-zero
non-interactively with the candidate list printed, rather than picking the
highest-ranked match. A script that silently got whichever revision ranked
highest is a script that will one day run the wrong model.

If the services are not up yet, `pf deploy plan <app[@rev]>` shows what would be
started and `pf deploy start <app[@rev]>` starts it. See
[Services & control plane](../architecture/services.md) for what the
constellation consists of, and [Workbench reference](../guide/workbench.md) for
the full verb surface.

## Read the results

    pf results <app>
    pf results --run <id>

A plain query returns the rows that a run produced. Adding `--follow` streams
them instead, as events from a resumable cursor — the two are distinct verbs on
the wire rather than one verb with a flag, because they answer differently.

What comes back, and how much of it, is set by the `execution.results` block of
the document you wrote: which node's answer you want, where it is written, how
long to wait, whether to filter to particular variables, and whether interim
progress is reported. [Results](../reference/api/results.md) documents the
envelope, including the per-node provenance that records which engine solved
each node and how it terminated.

While a run is in flight, `pf status` reports what the constellation is doing,
`pf logs` tails the deployment's streams, and `pf command pause|resume|stop`
reaches the run itself.

## Where to go next

[Workflow overview](../guide/workflow.md) is the same loop at working depth,
and the page to read second. [Application flow](../architecture/app-flow.md)
follows one document through the runtime, from validation to the results plane,
if you would rather understand the machine before writing another document.
