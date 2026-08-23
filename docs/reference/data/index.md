# Data & files overview

<!-- dc:status=polished dc:owner=DC2 -->

PlasticFog's on-disk surface is small and divides cleanly: documents you author,
documents the runtime emits, and the files a model and a solver exchange. This
page says which families exist and which page covers each.

The dividing question throughout is **who writes it**. A contract that an author
satisfies and a contract that the runtime fills in are different kinds of thing,
and confusing them is how a reader ends up looking for a schema file that does
not exist or hand-editing a file nothing reads.

## Authored documents

**The problem definition** is the one document you write:
`pf.problem_definition.v1`, carrying the problem's identity, its models and
data, the topology that holds the decomposition, and the execution policy. Two
further authored kinds share its schema file and are dispatched by their version
string — a **spot update**, which is a patch against an exact base revision of a
submitted problem, and a **control command**, which acts on a running problem and
parses standalone. [Schemas](schemas.md) gives all three their top-level fields;
[Problem definitions](../../guide/problem-definitions.md) is the guided tour.

**The registry query** is authored in a narrower sense: it is the structured
document a client sends the registry to ask which services match a selector, and
five of its fields correspond one for one with the query-placement block of a
problem definition. It replaced an earlier option that carried raw SQL composed
by the caller.

## Emitted documents

**The results envelope**, `pf.results_envelope.v1`, is how a run's answer comes
back: one object per reporting scope, with per-node entries that may carry the
engine that solved there, its terminal status and a proof status. It is declared
in C++ rather than in a schema file, and there is no `.schema.json` for it.
[Results](../api/results.md) documents it; [Files & artifacts](artifacts.md)
covers the document it is written into and how the results plane ingests that.

**The runtime topology summary**, `pf.runtime_topology.v1`, is the runtime-side
view of a submitted problem: per node, its role, the paradigms above and below
it, its engines, its resolved service ids, and its run state. It exists so that
an update can be validated against a live solve rather than against the document
alone. Nothing in the schema layer produces one — populating it from real
service state belongs to the submitting application.

**The coupling manifest**, `pf.coupling_manifest.v1`, records what one compile
unit's model is made of and how its symbols correspond to the decomposition
around it. It is emit-only: nothing in this build reads one, and no exit status
depends on one. It exists because the answers it collects otherwise live in four
different files in four different formats.

## Model and solver files

**The graph pair.** A validated definition is projected into a graph of modules,
serialized as a `.g` edge list and a `.gmap` carrying the content those ids stand
for — including each service's own model source and the attributes the builder
stamped on it.

**Models and data.** A `.zpl` file is Zimpl source for one master or one
subproblem; a `.data` file is a data collection it reads. Both may be carried
inline in the document instead of existing on disk, and the all-inline form is
what the worked examples use.

**Compiled products.** A compile produces an `.mps` model and a `.tbl` symbol
table; a master additionally gets a `.block` partition saying which row belongs
to which child, and a local solver writes a `.sol`. Most of these are consumed
as buffers rather than as files — the runtime materializes only what a solver
insists on opening by path.

**The staging dump** is the deliberate exception to that. It writes out, per
compile unit, exactly what that unit was told to compile: the request, the
source bytes, the data bytes, the block numbering, and the coupling manifest. It
is the artifact to reach for when a document validates and behaves differently
from how you read it.

**Service directories** hold a service's binary, its staged files, its compiled
products and the small `.ini` files that identify it — the domain, the registry,
and its own service id — and a **registry database** holds the services that
have registered and what they can do.

[Files & artifacts](artifacts.md) covers all of these, along with the logs and
the assembled monolith.

## The two prompt-pack contracts

The prompt pack ships two schemas that constrain a *model's* output rather than
anything the runtime reads: the response envelope a generated answer must be,
and the shape of one clarification question. They are described under
[Authoring with an LLM](../../guide/llm-authoring.md) and listed with the others
in [Schemas](schemas.md).
