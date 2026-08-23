# Files & artifacts

<!-- dc:status=polished dc:owner=DC2 -->

Beyond the JSON documents, PlasticFog reads and writes a small set of files:
the graph pair that carries a projected problem, the model and data files a
service compiles, the compiled products a solver consumes, the staging dump, the
logs, and the results envelope. This page says what each is, where it appears in
the workflow, and what you legitimately do with it.

One thing to know before the list. **Most staged files are virtual.** A compile
unit's sources and data exist as bytes inside a compile request, not as files on
disk; the runtime materializes only what a solver insists on opening by path. A
live run therefore leaves much less behind than it reads, which is why the dump
described below exists at all.

## The graph pair: `.g` and `.gmap`

A validated problem definition is **projected** into a graph of modules — one
module per logical service role, plus the data collections and physical nodes
they attach to — and that graph is what the runtime distributes. It serializes
as a pair of files with the same stem.

A **`.g`** file is the structure alone, in edge-list form: one edge per line, two
non-negative integer module ids separated by a space.

    5380973968732993759 1001
    5380973968732993759 6727070581021351956
    6727070581021351956 2001

A **`.gmap`** file carries the content the ids stand for, structured as the `.g`
file defines. It is a line-oriented format with explicit begin and end tags
rather than JSON or XML, because these files can grow large and the parser is
deliberately specialized: `@bm`/`@em` bracket a module's defining line,
`@bd`/`@ed` a data collection's values, `@br`/`@er` an RMP's Zimpl source, and
`@bs`/`@es` a subproblem's.

A module's line names its type and id, then the attributes the graph builder
stamped on it — the problem id and revision, the logical node id, its role and
level, its service role, the model it references, its solver kind and engine,
and one entry per boundary the node sits on with that boundary's paradigm,
binding and counterpart.

The pair is written per problem and named for the problem it projects; the
repository root carries the pairs left behind by past projections. Read them
when you want to see what your document actually projected to: the module
attributes are the clearest single view of how the topology was interpreted,
and the source sections show exactly which bytes each service was given.

## Models and data: `.zpl` and `.data`

A **`.zpl`** file is Zimpl source — the model for one master or one subproblem.
A **`.data`** file is a textual data collection the model reads, and its format
is whatever the model's `read` statements expect.

Whether these exist on disk depends on how the document carries them. A `file`
source names a real file under the source root, staged under its bare basename.
An inline source is carried in the document and staged under a name the graph
builder assigns: `Pf.zpl` for a master, `<modelId>.zpl` for a child template,
`<dataId>.data` for a data resource. An all-inline document has no `.zpl` or
`.data` on disk at all, and runs anyway.

One data collection is special. A resource distributed `per_service_id` carries
the subproblem service ids, one per line; a master receives the whole collection
and a leaf receives exactly its own id. It reaches every service under the bare
name `subprobs.data`, which is fixed rather than conventional — and which is why
a mid's *own* child ids have to be authored at a distinct path.
[Zimpl reference](../../guide/zimpl.md) covers that rule.

## Compiled products: `.mps`, `.tbl`, `.block`, `.sol`

These are what a compile produces and a solver consumes.

**`.mps`** is the model in the standard MPS format. Its `NAME` field is the
first eight characters of the entry file name exactly as it was passed, which is
one reason a model's staged name is not decoration.

**`.tbl`** is Zimpl's symbol table: the map from the full names of generated
rows and columns to the abbreviated names MPS uses. It is what the block
generator reads to decide which row belongs to which child — the compiled name,
not your source — and it is consumed as a buffer rather than re-opened from
disk.

**`.block`** is the block partition a master hands its coordinator: which rows
belong to block 0, the master's own, and which to each child's. It is generated
after the compile, from the symbol table and the service id collection, and it
is materialized because the coordinator opens it by path.

**`.sol`** holds a solution written by a local solver after a run.

You do not author any of these. Read a `.tbl` or a `.block` when a row landed in
the wrong block and you want to see the compiled names the generator was reading.

## Service directories and `.ini` files

A service runs in its own directory, which holds its binary, its staged model
and data, its compiled products, and the small `.ini` files that identify it
before it can ask anyone: the DDS domain id, the Register service id, and the
service's own id. Each holds a single numeric value, and the value must be
unique across participants in that domain.

A deployment stages those directories and writes the document's own resolved
service ids into them, so a document is not required to have been written
against any particular numbering.

## The registry database

The service registry is a SQLite database holding the registered services, their
types, their capabilities and their lifecycle status. Services register
themselves into it at startup, and a query placement resolves against it at
submit. Queries arrive as structured documents that the registry validates and
turns into parameterized statements — see
[Schemas](schemas.md#pf_service_queryschemajson) — rather than as SQL composed
by the caller.

## The staging dump

A live run leaves nothing behind to compare against, so the staging dump exists
to capture what each service was told to compile, before anything is compiled.

    build/pf_App --problem <doc> --source-root <dir> --dry-run --dump-staging <dir>

It writes one directory per compile unit, named `<serviceId>_<role>`:

| Entry | What it holds |
|---|---|
| `request.txt` | the scalar fields of the compile request — the entry file name, the constraint-name format, whether a symbol table is generated, the storage mode — then one line per source file and one per data file, in request order |
| `sources/<name>` | the exact bytes of each source file the unit compiles |
| `data/<name>` | the exact bytes of each data file it reads |
| `blocks.txt` | **masters only**: one line per associated child, `<serviceId> <block>`, ascending by block. A master that associated no child writes an empty file, and an absent file and an empty one say different things |
| `manifest.json` | the coupling manifest for this unit — every symbol with both its names, the block partition, and the coupling correspondence. It is written when the dump is taken with `--deep`, because the symbol names it records come from the compile |

The block numbering is captured rather than derived because it cannot be
recovered from the request: block *k* is the *k*-th child in arrival order, and
the order is not sortable. A master's `blocks.txt` may legitimately read
`10048 0` then `10038 1`.

This is the artifact to reach for when a document validates and behaves
differently from how you read it. It answers, per service, exactly which bytes
that service compiles — including the master's own file with its includes
resolved and its constraint regions intact, and each child's file as the
distribution assembled it.

The same dump is what a frozen fixture set compares against: goldens captured
from the runtime itself, and two test targets that judge the runtime and the
staging plan against them independently. Neither reads the other's output; the
goldens are the fixed point between them.

## The assembled monolith

    build/pf_App --problem <doc> --source-root <dir> --dry-run --deep \
        --monolith /tmp/monolith.zpl

This writes one Zimpl file equivalent to the whole decomposed problem, with the
data files its units read placed beside it. A `read` cannot be inlined, which is
why the output is a file plus its data rather than a single self-contained
model.

It requires the deep gate, and that is not a convenience: the assembler reads
the plan the reviewer compiles, and a document whose units do not compile has
nothing for a monolith to be equivalent to. A shape the assembler has no rule
for is refused rather than approximated. Use it to check a decomposition against
a single solver — see the agreement protocol in
[Workflow overview](../../guide/workflow.md).

## Logs

Service output is captured by the deployment that started the processes, and
`pf logs` fans it in with each line labelled by service, pid and UTC time. The
router filters structured records by level, can present streams per service in a
terminal multiplexer, and is silent by default.

One log is written outside that path: when the client autostarts a conductor,
the daemon's own output goes to a file beside the control socket rather than to
your terminal, because a background daemon writing onto a foreground command's
output is how a machine-readable stream stops being machine-readable.

## The results envelope on disk

A run writes a **results document** — the file named by the document's own
`execution.results.output`, in that run's directory. It carries one
`pf.results_envelope.v1` object per reporting scope, and it is the run's whole
answer: there is no wire a reader has to be attached to in order to learn what
happened, because the document is written whether or not anyone was listening.

That document is also what the results plane ingests. Ingestion is
document-granular — one row per envelope the document carried, stored as the
document carried it — so what you query later is what the run actually said
rather than a summary of it. `pf results --export <file>.jsonl` writes those
events back out, one compact JSON object per line, with no header, trailer or
summary object, so two exports can be compared line for line.

Each envelope carries per-node entries, and three of their fields are optional
provenance: the engine that solved there, that engine's own terminal status
string, and a proof status. **Absent means "not observed", never "clean."** The
distinction matters most on the last of the three: `unproven` and "not observed"
are different facts, and only the first is something a node said.
[Results](../api/results.md) documents the envelope in full.
