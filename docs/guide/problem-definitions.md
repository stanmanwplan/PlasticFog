# Problem definitions

<!-- dc:status=polished dc:owner=DC2 -->

A **problem definition** is one JSON document, `pf.problem_definition.v1`, and
it is the whole of what you hand PlasticFog. This page is a guided tour of what
it declares — the topology, the logic, the solvers and the methods — with a
small annotated example. Field-level exhaustiveness belongs to
[Schemas](../reference/data/schemas.md); this page is the shape and the reasons.

Two words are used precisely and it is worth fixing them first. A **problem
definition** is the document you author, the whole artifact. A **schema** is
`pf_problem_input.schema.json`, the machine-readable grammar the document has to
satisfy. You do not edit the schema; you satisfy it.

## The four parts

| Part | What it holds |
|---|---|
| `problem` | the identity: id, version, revision, a description, and metadata — put your hand-derived oracle here |
| `resources` | the **models**, one Zimpl program per role, and the **data** they read |
| `topology` | the **nodes**, their **services** and solver engines, and the **boundaries** between them |
| `execution` | iteration limits, tolerances, and what results come back |

Three optional top-level blocks sit beside them: `runSpec` (how many times the
submission executes and on what cadence), `observability` (what streams and how
it is displayed) and `catalog` (inert identity metadata — an application id, a
title, tags).

**A definition is not a model file with a wrapper around it.** The topology is
the part that carries the decomposition, and the decomposition is the part a
reader cannot recover by reading your Zimpl. Which index separates the blocks,
which rows stay at the master, who decides each symbol that crosses a
boundary — those are design decisions, and the document is written *in terms of*
them rather than *about* them. Say which one you chose, in `problem.metadata`.

## The example

The tour follows the press shop from the worked corpus
(`promptpack/examples/natural_language/flat_dw/`). A shop feeds two assembly
lines, east and west. One press gives the shop four press-hours a shift. Each
line runs exactly one of two shift patterns: east runs its normal pattern for 3
at 3 press-hours or a lean pattern for 7 at 1 press-hour; west is 4 at 3
press-hours or 9 at 1. Both lines must run something.

Enumerate the four combinations and the cheap pair is over budget; the optimum
is 11.0 and it is unique. Notice the property that makes the instance worth
decomposing: each line's own cheapest pattern eats 3 of the 4 press-hours, so
the uncoordinated sum of the per-line minima is 7 — strictly better than the
true optimum and unreachable. A run that failed to coordinate could not land on
11.0 by accident. That sentence belongs in `problem.metadata`, and in the
document it is exactly where it is:

```json
"problem": {
  "id": "pp_press_shop",
  "version": "1.0.0",
  "revision": 0,
  "description": "A press shop prices two assembly lines against one shared bottleneck press...",
  "metadata": {
    "expectedObjective": "11.0",
    "oracle": "Hand-derived by exhaustive enumeration of all four pattern combinations...",
    "whyCoordinationIsRequired": "Each line's own cheapest pattern consumes more of the single press budget than the pair can afford..."
  }
}
```

`problem.id` is a stable identifier — spellable in a path and in a topic name.
`revision` is owned by the manager, not by you: a patch may not modify it, and a
successful update assigns the next one exactly once.

## Topology: what is cut apart, and how

`topology` names a `rootNodeId`, a map of `nodes`, and a map of `boundaries`.
Every node declares its `role` (`master`, `mid` or `subproblem`), its `level`
(the root is 0 and each step down adds one), and the **services** it hosts. A
service is one of four roles — `priceMaster`, `priceSubproblem`,
`resourceMaster`, `resourceSubproblem` — and carries the model it runs, the
solver engine it runs on, its placement, and the data it declares.

```json
"topology": {
  "rootNodeId": "press_shop",
  "nodes": {
    "press_shop": {
      "role": "master", "level": 0,
      "services": {
        "priceMaster": {
          "modelRef": "press_master",
          "solver": { "kind": "cpu", "engine": "dip", "options": {} },
          "placement": { "explicit": { "serviceIds": [1038] } },
          "dataRefs": []
        }
      }
    },
    "line_east": {
      "role": "subproblem", "level": 1,
      "services": {
        "priceSubproblem": {
          "modelRef": "press_line",
          "solver": { "kind": "cpu", "engine": "symphony", "options": {} },
          "placement": { "explicit": { "serviceIds": [10058] } },
          "dataRefs": ["subprobs", "rmp", "patterns"]
        }
      }
    }
  }
}
```

The validator requires that the topology be exactly one connected rooted tree:
one parent per non-root node, no cycles, no unreachable node, declared levels
equal to actual depth, and roles consistent with position. Those are semantic
rules the C++ layer enforces rather than the JSON grammar, and each has its own
refusal code.

### Nesting, and mixing paradigms

The four service roles are what make **nesting** expressible. A mid-level node
can be a subproblem to its parent and a master to its children — a
resource-directed subproblem above, a price-directed master below, or the
reverse — because the two directions are two different modules on the same
logical node. That is how a decomposition spans processes and physical nodes:
each service binding resolves to a service id, and a service id is a process in
the constellation.

One restriction applies downward only. **All of one node's child boundaries must
carry the same paradigm.** A node that masters some children price-directed and
others resource-directed would have to run two decomposition algorithms over one
model at once, and the runtime has no shape for that; the validator says so by
name (`topology.mixed_downward_paradigms`). The restriction says nothing about
the up direction. [Decomposition paradigms](../architecture/decomposition.md)
covers which nested shapes execute.

### Boundaries: the method, declared

A boundary names its parent and child, its `paradigm`, its `binding`, and its
coupling contract. The paradigm is the **method**: `price_directed`, where the
master hands prices down and receives column proposals back, or
`resource_directed`, where the master hands an allocation down and receives cuts
back. The binding names the algorithm.

```json
"boundaries": {
  "shop_to_line_east": {
    "parentNodeId": "press_shop",
    "childNodeId": "line_east",
    "paradigm": "price_directed",
    "binding": "dantzig_wolfe",
    "coupling": { "mode": "authoring_convention", "declarations": [] }
  }
}
```

`coupling.mode` says how the symbols that cross the boundary are identified.
`side_declaration` requires an explicit list, each declaration naming the
parent's spelling and the child's spelling of one symbol, and the resource path
uses it: the master publishes an allocation in its own names, the child fixes
columns in its own, and the child translates in both directions. A resource
boundary also carries the **epigraph** — the master's own recourse variable,
canonically `pf_theta` — as the declaration whose coupling key is `epigraph`.

`authoring_convention` leaves symbol discovery to the naming conventions the
models already encode, and it is what every price boundary uses. Nothing in the
runtime consumes coupling declarations on a price boundary, so a declaration
list there would be visible in the document and ignored by the runtime — which
is worse than no list, because it reads as a contract and is not one.

A declaration's owner must be the parent or the child of *that* boundary. A
sibling is not an owner and a grandparent is not an owner; the refusal is
`coupling.owner_outside_boundary`. A declaration can also participate in a
multi-level promotion chain, using a stable promotion id and the ordered roles
`origin`, zero or more `pass_through`, and `terminus`.

## Placement: which process runs this service

Four placement forms are spellable. `explicit` names resolved service ids.
`query` names a selector the registry answers at submit — a service type, a
count, required capability tokens, and an ordering policy. `spawn` says the
submitting side will start and own local processes for this binding. `auto` is
an ordered list of at most four alternatives, tried until one resolves, and it
may not nest.

**Use `explicit` if you want the deep gate.** A dry run contacts no registry, so
it cannot resolve a query placement; rather than compile a graph whose service
ids you never wrote, the reviewer refuses with
`placement.deep_requires_explicit`, one item per query-placed binding and
without compiling anything. The two repairs answer different questions: rewrite
the placements as `explicit` if you want the deep gate, or leave them and
validate without `--deep` if you want discovery. Nothing else changes — the same
models, the same data and the same topology compile clean either way.

## Logic: the models, and inline sources are first class

`resources.models` maps a model id to a Zimpl program. `resources.data` maps a
data id to a data resource and says how it is distributed.

**A source may be carried inline in the document, and that is the preferred
form.** An inline document is the whole artifact: one JSON file, nothing beside
it, and no source root to stage. Nine of the ten worked goldens are all-inline,
and the runtime executes that shape directly. The one exception is a rule rather
than a lapse: the nested-price golden carries its mid's own child ids as a file,
because that name is fixed and the document-wide collection already claims it.

Inline sources are named by rule, and the names are load bearing:

| What | Its staged name |
|---|---|
| an inline **master** model | `Pf.zpl` |
| an inline **child** model | `<modelId>.zpl` — its own key in `resources.models` |
| an inline **data** resource | `<dataId>.data` |
| a `file` source | its bare basename |

The child's staged name is the name the master's `include` line must use. A
child at `resources.models.press_line` is included as `include "press_line.zpl";`
and nothing else will resolve.

```json
"resources": {
  "models": {
    "press_master": { "language": "zimpl", "source": { "inline": "...\ninclude \"press_line.zpl\";\n" } },
    "press_line":   { "language": "zimpl", "source": { "inline": "subto sub000_001: forall <s> in subprob_ids ..." } }
  },
  "data": {
    "subprobs": { "format": "zimpl_data", "distribution": "per_service_id", "source": { "inline": "10058\n10048\n" } },
    "rmp":      { "format": "zimpl_data", "distribution": "all_nodes",      "source": { "inline": "# press hours available per shift\n4\n" } },
    "patterns": { "format": "zimpl_data", "distribution": "all_nodes",      "source": { "inline": "..." } }
  }
}
```

A `file` source is a relative path, confined to the source root, with no `..`
and no empty components. Either form may carry a `sha256` pin: when the codec
resolves content it computes the digest and emits it in the canonical document,
and a digest you supplied is authoritative — a mismatch rejects the transaction
rather than being silently absorbed.

Two rules about the models themselves are the ones first-time authors meet.
**A master's data files are declared on its children**: the distribution
collects every data module attached to each of a master's children and hands the
whole set to the master's compile, so a `read` in a master model resolves
against files declared on that master's children, and the master's own
`dataRefs` may be empty. And **the master's file has three parts in order** —
declarations, then the constraint regions holding the rows that are the master's
alone, then one `include` per child template — because each child's model is
built as the master's file with the includes and the constraint regions removed,
followed by that child's own template. [Zimpl reference](zimpl.md) covers both
in full, along with the naming convention the block generator reads.

## Solvers: engines by role

Each service binding may name its solver: a `kind` (`cpu` by default, or `gpu`),
an `engine`, and an opaque `options` object whose shape belongs to the engine.
When `solver` is absent the engine defaults by role, and the codec materializes
that default in the canonical document — so omitting the block and stating the
role default produce identical canonical bytes and therefore the same content
hash.

[`pf capabilities --json`](workbench.md) is the authority on what this build
executes, and the
prompt pack carries the same document byte for byte. The table below is the
narrower statement: every name in it is in the snapshot as executable **and has
been run at that role by a test lane**.

| Role | Run-proven | Default |
|---|---|---|
| `priceMaster` | `dip` only | `dip` |
| `priceSubproblem` | `symphony`, `highs` | `symphony` |
| `resourceMaster` | `cbc`, `clp`, `highs` | `cbc` |
| `resourceSubproblem` | `clp`, `highs` | `clp` |

`dip` is the only engine at a price master because it is a coordinator that
selects its own integer solver; an accepted-but-rerouted engine would be a
silent lie about what ran. At a resource subproblem the recourse must be
continuous — its cuts are LP duals, and an integer column makes them certify
nothing — so integer-capable engines other than `highs` are refused there by
name.

Selecting an engine a role does not accept is `solver.engine_role_incompatible`.
A `kind: gpu` selection is an assertion about a machine that no document can
settle, so it is a warning rather than an error, silenced by a placement query
that requires the capability.

A binding may also state what the answer must certify. `solver.guarantee` names
a `requirement` — `exact_required` by default, or `best_effort` — and what to do
when a result is uncertified: refuse, or fall back to a named engine. A fallback
must name its engine, and that engine must itself be legal for the role, because
a fallback onto an engine the role cannot run is a fallback that would fail the
moment it was taken.

## Execution, and repeated execution

`execution` carries the solve policy: iteration limits, a time limit, a
convergence tolerance, an inner-solve policy, and a `results` block saying which
scope reports, where the results document is written, how long to wait, and
whether to filter variables or report interim progress.

```json
"execution": {
  "maxIterations": 0,
  "timeLimitSeconds": 0.0,
  "convergenceTolerance": 1e-06,
  "innerSolvePolicy": "converged",
  "results": { "return": "overall", "output": "results.json", "waitSeconds": 900, "returnScopes": ["overall"] }
}
```

`returnScopes` defaults to `["overall"]`, the reserved scope naming the root
node's master. Any other entry must name a declared node carrying a master-side
role: a mid qualifies, because its master half is a real coordinator reporting
for its own subtree; a leaf subproblem does not, because it holds no results
envelope of its own.

`runSpec` is separate from `execution` because it is about repetition rather
than about one solve: a `mode` of `once`, `counted`, `continuous` or `interval`,
with `count` required exactly when the mode is `counted` and an interval
required exactly when it is `interval`, an overlap policy, a warm-start policy,
and stop conditions. Both if-and-only-if rules are enforced in both directions —
a `count` beside a mode that never reads it is a number the author expects to
matter, so saying nothing would be the worse answer.

An absent `runSpec` and a present one saying `once` mean the same thing
operationally and are deliberately not the same document: the second is an
author stating a choice, and a canonical form that erased the statement would
erase it from the content hash too.

## Updates and commands

The same schema file carries two further document kinds, dispatched by
`schemaVersion`.

A `pf.problem_update.v1` document is a **spot update**: an update id, the target
problem id, the exact base revision it was built against, an optional base
content hash, a mode (`json_patch`, `merge_patch` or `replace`), an interrupt
directive, and the payload. The manager applies every update to a private copy,
reparses and revalidates the whole candidate, and publishes atomically only when
every check passes — a failed update never changes the active definition.

What an update may change is decided against the node it targets rather than
against the run as a whole: each rule walks the target's own subtree and asks
whether any node in it is solving or paused. Changes to models, data and
execution policy are legal against a target that is solving or paused, so a
sub-hierarchy's mathematical logic can be revised while it is working and while
the rest of the problem keeps solving.

Structural changes against such a target are refused rather than applied: a
paradigm or binding change, a placement change, or an engine change on a subtree
that holds a solving or paused node, and the removal of a node with running
descendants. The first three are waived by `interrupt: always`, and the waiver
is recorded as a warning — the waiver halts the affected subtree's masters
before the update is published, so it interrupts those solves rather than
slipping past them. The fourth is not waivable by anything: interrupting a solve
still leaves the removed node's descendants with no parent to report to.

A `pf.problem_command.v1` document is a **control command** — `start`, `pause`,
`resume`, `stop`, `halt` or `request_results` — against a problem already
submitted. It parses standalone: the problem is named by id and the definition
is not required in the same document, so a caller holding only the command can
accept or reject it on shape alone.

## A word on versions

`schemaVersion` has stayed `pf.problem_definition.v1` across capability
additions, and that is a rule rather than an oversight. Every addition has been
optional with a default, and no existing field has changed meaning: a document
written before an addition parses after it and means the same thing, and a
document written after it, read by a consumer that predates it, loses the new
fields and is still a coherent problem. A version bump would be required only if
a field became mandatory or an existing one changed meaning.

New *document kinds* do get their own versions, because they are new documents
rather than new fields — which is why the update and command forms carry theirs.
