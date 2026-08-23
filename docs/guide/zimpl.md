# Zimpl reference

<!-- dc:status=polished dc:owner=DC2 -->

PlasticFog models are written in Zimpl. This page covers the compliant subset:
the conventions that make a model decomposable, which language features have
been measured to run, the difference between unsupported and merely unproven,
and the two documented limits a compliant model can still meet.

## How a model reaches the solver

Models are compiled **in process**. The two solver managers call an embedded
Zimpl compiler rather than shelling out to `zimpl(1)`, so a staged model is a
set of bytes in a compile request rather than a set of files on disk, and the
only bytes that still reach a filesystem are the ones a solver insists on
opening by path.

The compiler is the vendored Zimpl front end linked into the build, driven the
same way the command-line tool drives it, and its products — the MPS model and
the symbol table — are consumed as buffers. Compiles are content-addressed and
cached per service, so an unchanged model recompiled in a later round is a cache
hit rather than a second compile.

## The master's file has three parts

In this order:

1. **the declarations** — sets, params, vars, and the objective;
2. **one or more constraint regions**, bracketed by `#@begin_constraints` and
   `#@end_constraints`, holding the rows that are the master's alone;
3. **the includes** — one `include "<name>";` per child template.

Parts 1 and 3 are what a price child sees. Part 2 is what it never sees: each
child's model is built as *(the master's file, with every include line and every
constraint region removed)* followed by *(that child's own template)*.

That is why the absence of markers is legal and, in a decomposed model, wrong.
A master with no markers has its whole declaration block prefaced into every
child, every variable it declares is declared a second time, and the compiler
refuses the model with `Name "..." already in use`.

The marker rules are exact, and the codec checks them before anything is
compiled: a marker line must be exactly the directive with no leading or
trailing text, regions must be paired, must not be nested and must not be
reversed, and `#@begin_constraints` must not be the first line of the file. The
listener searches for the directive after a newline, so a first-line region is
never stripped. The same mechanism applies to includes: an `include` must not be
on the first line, and the quoted name must be the only thing on its line.

## Constraint names carry the decomposition

The block generator reads the **compiled** symbol table, not your source. Two
rules, both absolute:

* a row whose full name begins `rmp` belongs to the master — name master rows
  `rmp_<nnn>`;
* every other row must carry, **as a substring of its full name**, the service
  id of the child it belongs to — name them `sub<nnn>_<mmm>`.

Indexing a row over the child index set is what puts the id in the name. A
scalar row emits a full name carrying no service id, and the block generator
refuses the master's compiled artifacts with `zimpl.block_unassigned`. This
row —

    subto sub000_002_feature: forall <s> in subprob_ids with card({<s,c> in choices}) > 0 do
      <the feature>;

— emits a name carrying the child's id and routes. The same row written as a
scalar `subto sub000_002_feature: ...` does not, and that single mistake
accounted for every failure in the first draft of fifteen measured documents.

Those two spellings also satisfy the generator's own length bound as a side
effect: it measures the *compiled* name, so a short label like `c1` fails where
`rmp_001` passes.

A row relating a master variable to a child variable, or two children's
variables to each other, **is the master's row**: name it `rmp_*` and put it
inside the markers. Naming it `sub*` pushes a master variable into a child's
block, and a name carrying two ids is assigned to whichever id the substring
scan reaches first — which is the silent defect `zimpl.row_spans_two_children`
exists to catch.

## Two guards that look optional and are not

**Guard every per-child row** with `with card({<s,c> in <this level's data>}) >
0`. Without it a level generates a row over an empty set and the compiler
refuses the model with `Error 106: Empty LHS, constraint trivially violated`.

**Scope every objective** to its own level's ids, `with <s> in subprob_ids`. The
objective travels into every child, and Zimpl keeps a column carrying a non-zero
objective coefficient even when no row mentions it — so an unscoped objective
leaves a sibling's columns alive in a child's compiled model. That is
`zimpl.objective_leaks_sibling_columns`, and it is the second of the two silent
defects: the run completes, reports `optimal`, and gives the wrong number.

Both are distribution requirements rather than filters. At the master each is a
no-op; at every child it is load bearing.

## Where the data comes from

A master's data files are declared on its **children**. The distribution
collects every data module attached to each of a master's children and hands the
whole set to the master's compile, so a `read` in a master model resolves
against files declared on that master's children, and the master's own
`dataRefs` may be empty.

Data paths arrive under their **bare** names: a resource authored at
`inner/subprobs.data` is opened as `subprobs.data`. That is what makes the one
awkward case work. A mid needs its own children's ids under the bare name
`subprobs.data`, but `subprobs` is already the document-wide `per_service_id`
collection whose authored bytes are discarded and replaced by every subproblem
id in the document — so the mid's own is authored as a **file** at a distinct
path with `distribution: all_nodes` and declared on the mid's children. That is
a rule rather than a lapse, and the nested-price golden is its worked example.

## The feature matrix

Eighteen Zimpl language features were each written into a minimal flat
price/Dantzig–Wolfe document **twice** — once in the master and once in a leaf —
and each of the resulting thirty-five documents was put through the deep gate
and then run end to end against a hand-derived objective. The matrix below is
that measurement.

**"Supported" here means it ran to its oracle.** Not a clean compile, not a
zero exit status, not an argument from the grammar.

| Feature | Master | Leaf | Where it is not supported |
|---|---|---|---|
| `vif` | supported | supported | — |
| `vabs` | supported | supported | — |
| `sos1` | **refused at the solve** | **refused at the solve** | see below |
| `sos2` | **refused at the solve** | **refused at the solve** | see below |
| `soft` (`separate`) | supported | supported | see the note on `soft` below |
| `implicit` | supported | supported | — |
| `startval` | supported | supported | — |
| `priority` | supported | supported | — |
| `do check` | supported | supported | — |
| `do print` | supported | supported | — |
| objective offset | supported | *n/a* | a child template carries no objective statement: the master's is prefaced and the campaign replaces it with reduced costs |
| ranged constraint | **refused at the solve** | supported | see below |
| `defset` / `defnumb` | supported | supported | — |
| `powerset` / `subsets` | supported | supported | — |
| `argmin` | supported | supported | — |
| `param ... default` | supported | supported | — |
| string functions | supported | supported | — |
| `read` + `skip` / `use` / `comment` | supported | supported | — |

Thirty of the thirty-five cells reached their oracle, and **all thirty-five
passed the deep gate with a zero exit status and no diagnostic**. That is worth
stating on its own: the reviewer accepts every one of the eighteen features, so
the deep gate is not where any of this is caught — which is exactly why the
matrix exists.

Two details of the measurement bound what the matrix claims. Every verdict is
about one minimal document shape — a flat price root over one leaf — on this
build; a feature refused at a price master here may behave differently at a
resource master, which no cell tests. And the `read` cell exercises `skip`, `use`
and `comment` together; `match` is a fourth option of the same clause, is not
separately measured, and is therefore not claimed.

A note on `soft`. Zimpl 3.8 has **no weighted soft-constraint form** — that is a
fact about the language rather than about this build. Its constraint-attribute
list carries `scale`, `separate`, `checkonly`, `indicator`, `qubo` and a set of
penalty attributes, and no `weight`. The matrix therefore exercises `separate`,
the nearest thing to a soft row, and a reader looking for weighted soft
constraints will not find them.

## The two documented limits

Both non-supported results in the matrix are refusals **at the solve**, not by
the compiler, and each is pinned by a fixture under
`tests/fixtures/zimpl_features/`.

**A ranged constraint in the master ends the campaign.** COIN-OR answers `Range
constraints are not yet supported`, the run reports an error status with no
objective, and the campaign stops. The identical row in a child template runs to
its oracle. Write ranged rows in leaves, or break a master's into two
inequalities.

**`sos1` and `sos2` fail at both positions, and the position is a fiction.** An
`sos` is a *declaration*, not a `subto` row, so it cannot live inside the
constraint markers — which means it travels into every child, and the leaf is
where both cases fail. Both rows of the matrix are the same experiment, and the
staged child source shows the `sos` statement arriving there. There is no
master-only `sos`.

These two are limits of the *language subset*. They are separate from the
runtime's shape limits — the conditions under which a document of an executable
shape does not finish — which are covered in
[Decomposition paradigms](../architecture/decomposition.md).

## Unsupported, unproven, and how to tell them apart

Three words, three different facts, and the report tells them apart without your
having to read the prose.

**Unsupported** is a refusal. The shape or the binding has no code path in this
build, the report line begins `error`, the exit status changes, and there is
nothing to suppress. A resource boundary above anything or below another
resource boundary, a node mastering some children price-directed and others
resource-directed, and a non-zero recourse cost under a price parent are all
refused by name; so are the `lagrangian` and `primal_subgradient` bindings.

**Unproven** is an advisory. `coverage.unproven_shape` says your definition is
valid and executable, and that one dimension of it — a depth, a shape, an engine
at a role and level, or a placement form — has never been run end to end by any
test lane. Nothing in the repository can tell you it works, and nothing tells
you it does not.

    warning [coverage.unproven_shape] /topology/nodes/leaf_l/services/priceSubproblem/solver/engine: engine clp@priceSubproblem@1 is EXECUTABLE and UNPROVEN: no lane ... has run this engine at this role and this level. Proven at this role and level: highs, symphony. This is INFORMATIONAL and changes no exit status ...

Tell it from an error by two machine-readable facts rather than by reading: the
line begins `warning`, never `error`, and the code family is `coverage.`. It
never appears without `--deep`, it never changes the exit status, and neither
import nor run reads it.

!!! warning
    Do not repair an advisory by editing the document toward a proven
    combination. Picking a different engine to silence it would change what you
    asked for in order to quiet a message that explicitly says nothing is wrong.
    If you want the noise gone for one run, `--no-advisories` suppresses
    `coverage.` items and only those.

The advisory shrinks by itself. A clean end-to-end run prints the coverage row
the document proved and how to record it, and a recorded row removes the
advisory for everyone.

**Executable** is a third statement again, and it is the snapshot's. An engine
can be listed executable at a role and still not appear in the run-proven table
in [Problem definitions](problem-definitions.md): executable is a statement
about the capability document, the table is a statement about runs, and where
they differ the runs win.

## Where the rules come from

Every convention on this page is derived from the code that enforces it, and
each has a refusal code and a pointer.
[Problem input](../reference/api/problem-input.md) lists them code by code:
which gate raises each, the JSON Pointer it fires at, and a one-line repair.
