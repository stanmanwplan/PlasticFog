# Decomposition paradigms

<!-- dc:status=polished dc:owner=DC1 -->

This page explains the two decomposition paradigms PlasticFog implements —
price-directed (Dantzig–Wolfe) and resource-directed (Benders) — how they nest,
how they compose with each other, and what the current runtime executes and
refuses. It assumes you know linear and mixed-integer programming; it assumes
nothing about this framework.

## The two directions

Both paradigms split one large problem into a coordinating **master** and
several **subproblems**, and both iterate. What differs is what travels between
them.

In a **price-directed** decomposition, the master holds the linking constraints
and hands the children *prices* on the shared resources. Each child answers
with a **column** — a complete proposal for its own part of the problem,
attractive at those prices. The master collects proposals, re-optimises over
the ones it holds, and hands down new prices. A column is a proposal the master
may decline.

In a **resource-directed** decomposition, the master holds the linking
*variables* and hands the children an *allocation* — a decision, not a price.
Each child solves its own recourse problem under that allocation and answers
with a **cut**: a constraint on the master's variables, saying either "no
recourse exists for this allocation" or "the recourse for this allocation costs
at least this much". A cut is not a proposal. The master adopts it or abandons
correctness.

That asymmetry — proposals that may be declined against constraints that must
be adopted — is the reason the two are implemented differently rather than as
two configurations of one loop.

Three terms sit at three different levels, and the rest of this page keeps them
apart. **Price-directed** names the coordination family — prices down, priced
proposals back — rather than one algorithm, and Dantzig–Wolfe column generation
is the realization of it that PlasticFog ships. Sibling methods coordinate
through the same signals: Lagrangian dual decomposition also hands prices down
and reads proposals back, which is why a `lagrangian` binding is spellable in a
document at all, although this runtime carries no implementation of one and
refuses it with a note.

**DIP** is the decomposition framework beneath the price path rather than a
solver, and it exposes several algorithm variants. The one PlasticFog reaches is
its price-and-cut algorithm, and that is fixed in the RMP service rather than
selected by the document: the branch-and-cut variant is reachable in the code
only behind a parameter the service never sets, and DIP's remaining variants are
never constructed. **SYMPHONY**, **CBC**, **CLP**, **HiGHS** and **NVIDIA
cuOpt** are engines — they solve the LPs and MIPs a decomposition poses at a
master or at a block, and none of them performs any decomposition itself.

## One bound, two representations

Price-directed methods in DIP share a single underlying object. Splitting the
constraints into a tractable relaxation and a set of complicating rows defines
the convex hull of the relaxation's integer points; the improved bound every
method below computes is the optimum over that hull intersected with the
complicating rows. What varies is how the hull is represented.

Inner methods build it from the inside, as convex combinations of extreme
points the subproblem oracle proposes — Dantzig–Wolfe column generation is the
primal form and Lagrangian relaxation its dual. Outer methods build it from the
outside, as an accumulation of valid inequalities, using the same oracle to
separate: a point that cannot be expressed as a convex combination of the
hull's points yields a certificate, and the certificate is a cut.

The two arrive at the same bound, and the hybrids run both at once — which is
what the names in DIP mean. Price-and-cut adds outer cuts to the inner master;
relax-and-cut adds them to the Lagrangian; the pure cutting-plane method is the
outer method alone. PlasticFog's shipped price-directed path is DIP's
price-and-cut; the outer-only realization exists in DIP and is not reachable
through a problem definition today.

None of this is Benders: the outer method here works the same structural split
as column generation, while Benders decomposes along a different one.

## Price-directed: Dantzig–Wolfe

`paradigm: price_directed`, `binding: dantzig_wolfe` — the two fields a
[problem definition](../guide/problem-definitions.md) sets on a boundary to ask
for this shape.

The shape to recognise is several units, each with its own internal choices,
contending for something the parent hands out. The authoring guide's worked
example is a radio station with two studios sharing one night engineer who
gives the building five hours. Studio A can broadcast live at a cost of 2,
consuming 4 engineer-hours, or taped at 6, consuming 2; studio B is live at 3
for 4 hours or taped at 5 for 1 hour. Both studios must broadcast.

Enumerate the four combinations and two are over budget; the cheapest feasible
pair costs 7. Now notice the property that makes the instance worth
decomposing: each studio's *own* cheapest choice is live, and the sum of the
two independent minima is 5 — strictly better than the true optimum, and
unreachable. The engineer-hour row is exactly what the two studios cannot see
about each other, and pricing it is exactly what makes them see it. A run that
failed to coordinate could not land on 7 by accident.

In the runtime, the master is a restricted master over the columns its children
have proposed so far, driven by COIN-OR's DIP, and the children are separate
services solving their own blocks. The master's coupling rows are the ones the
author marks; everything else belongs to a block, and the block a row belongs
to is read out of the row's own name. A child solves only in response to
prices — it is given no standing instruction to solve — which is why a
subproblem service receives a setup verb and no solve verb.

## Resource-directed: Benders

`paradigm: resource_directed`, `binding: benders`.

Here the master decides the linking variables `y` and carries one epigraph
variable, `pf_theta`, standing for the recourse cost. For a fixed allocation,
each child faces

```
z(y) = min  d'x   s.t.  A x >= b - B y,   x >= 0
```

with dual

```
max  u'(b - B y)   s.t.  A'u <= d,   u >= 0
```

If the recourse is feasible, an optimal dual `u*` gives, by weak duality, a
valid bound for *every* `y`, and so a row the master must respect:

```
theta + (u*'B) . y  >=  u*'b
```

If the recourse is infeasible, a Farkas ray `r` certifies it, and every
allocation that admits a recourse must satisfy

```
(r'B) . y  >=  r'b
```

The two families share one core — coefficients are a multiplier dotted with the
linking columns, the right-hand side is that multiplier dotted with the row
bounds — and differ only in that the optimality cut additionally carries the
epigraph column. They are implemented as one core with a flag precisely so the
two cannot drift apart in sign.

Two conventions are worth stating because implicit ones are how sign errors
survive. All subproblem rows are put in `>=` form: a `<=` row is negated when
the linking system is built, and an equality is split. And a Farkas ray is
defined only up to positive scaling, so the implementation normalises it by its
largest absolute component — a solver returning `(2,2,2)` and one returning
`(1,1,1)` then produce the same row.

The optimality cut also carries a built-in check. Evaluated at the allocation
that produced it, it must reproduce that allocation's recourse cost. No sign
error survives that identity, and it is asserted as a test rather than assumed.

### The Benders master is implemented outside DIP

DIP is a column-generation framework: its relaxed-solve call asks a block for a
column, and its master is a restricted master over columns, grown by columns. A
Benders master is a different object — an LP or MIP over the linking variables
plus an epigraph variable, grown by rows.

Projecting one onto the other means either telling DIP that a cut is a column,
which it is not, or reimplementing DIP's master inside it. So the Benders
master is its own loop, and the price path's pricing arithmetic is untouched by
it. Nothing in the resource path reuses that arithmetic.

### One epigraph, one aggregated cut

The master's epigraph variable stands for the **total** recourse cost of all
children, and that makes a round's optimality cuts a correctness question
rather than a bookkeeping one.

Installing each child's optimality cut as its own row would make the epigraph
bound only the *largest* child's cost — every such row reads "theta is at least
my cost", and a set of them is satisfied by the maximum, not the sum. The
master would converge to the linking cost plus the largest child's recourse,
report it as optimal, and be wrong by exactly the other children's costs.

So a round's optimality cuts are summed into one row before installation, and
that row is installed only when *every* child answered and every one was
feasible. A missing or infeasible child contributes no bound, and summing what
is left would understate the total and let the loop stop early on a bound
nothing supports.

Feasibility cuts are not aggregated. Each is a statement about one child's own
recourse, carries no epigraph term, and is strictly stronger installed
separately.

This is recorded plainly because it is the single easiest way to get a Benders
master confidently wrong, and because it was found by running the loop rather
than by reading it.

### Bounds, and what "converged" requires

The master objective is a valid lower bound at every round: the epigraph
underestimates the recourse until the optimality cuts catch up, so the master
is a relaxation. An upper bound is formed as the linking cost plus the sum of
the children's recourse costs — and only when every child answered and every
one was feasible. An allocation one child cannot serve is not a feasible point
of the real problem, and an allocation a child never answered for has an
unknown cost; an incumbent from either would be an upper bound nothing
supports.

Convergence requires **both** halves: a round that installed nothing anywhere
*and* a closed gap. "No cut" alone can mean every child was merely satisfied at
a point the master has not yet costed. A round that installs nothing while the
gap is still open is reported as a **stall** — `feasible`, not `optimal` — with
a diagnostic, because nothing in the next round would differ.

### Integer recourse is refused

Every derivation above uses LP duality. A subproblem with integer recourse has
no such dual: the multipliers a branch-and-bound solve reports certify nothing
about the value function, so the cuts would be **invalid** rather than merely
weak — and an invalid cut is adopted by the master as a constraint and the
result reported as optimal.

The refusal is enforced twice, deliberately, and the two checks are not the
same. The document-level check sees the *document* and refuses an
integer-capable engine selected for a resource-subproblem role. The runtime
check sees the *compiled model* and refuses any integer column in the recourse,
whatever the document said. The second is the authoritative one and the first
cannot replace it, because a document may honestly select a continuous engine
and still supply a model with a binary variable in it.

## Nesting

A node between the root and the leaves is a **mid**: a master to its children
and a subproblem to its parent at the same time. Nesting is how a hierarchy of
more than two levels is expressed.

The rule that keeps nesting tractable is that **coupling is
adjacent-level-only**. A master's stub and include processing — the staging step
the [Zimpl reference](../guide/zimpl.md) describes — runs over its
*direct* children, and nothing else. A node's interface upward is what its
parent's generated stub declares; its interface downward is what its own
boundaries declare. There is no path by which a grandparent's decision reaches
a grandchild except through the node between them.

Two consequences follow. A mid's two halves must be placed on the same service,
and a topology that splits them is refused: the halves share one object, the
inner model — the master half prices over it, the subproblem half reports on it
— and split across two processes there is no single inner model for either
sentence to be about. And a mid's inner model is reconciled from two sources at
build time: the parent's stub, which declares the interface columns the parent
will price, and the mid's own decomposition over its children.

When a mid is priced by its parent, its own objective is **replaced** by the
parent's reduced costs on name-matched linking columns, with zero on every
other column including the epigraph. The order is load-bearing: every column is
zeroed first, then the prices are placed, so a column the parent stopped
pricing this round falls back to zero rather than keeping last round's price.
Pricing a mid's own native objective would return a column that is *wrong*
rather than merely suboptimal. A priced name that matches no column is an
error, not a skip — it means the parent and the mid disagree about the
interface, and pricing the rest would answer a different question than the one
asked.

## Mixed composition

The claim the mixed shape tests is one sentence: **a node's decomposition
paradigm is a local decision, and its parent neither knows nor cares.**

The shape that executes today is a price-directed root over a mid that is a
price-directed subproblem upward and a resource-directed master downward. The
branch between the two paradigms sits at the last point where both still want
the same thing — a price vector arrived and was decoded — and nothing above the
branch, nor anything in the reply path below either campaign, mentions which
side was taken.

One detail is specific to a resource-directed mid. A price mid gets its upward
interface structurally, from the block generator's notion of columns belonging
to no child block. A resource master runs no block generator — it has no blocks
— so its interface is assembled from declared data instead: the union of every
coupling name across its resource boundaries and every name the parent actually
priced. Neither alone is right. The parent publishes only its non-zero reduced
costs, so keying on arrivals alone drops the chosen column exactly when its
price was zero, which is when it is cheapest and most likely to have been
chosen; and the boundary set alone misses a shared column the parent prices
that this mid hands to no child. A declared interface column the incumbent does
not mention is sent as zero rather than omitted, because the master solved and
that column took the value zero.

## What executes, and what refuses

Four shapes execute today, and each is proved by a document run end to end
against an independently derived optimum:

| Shape | Structure | Paradigm and binding |
|---|---|---|
| flat price | root over leaves | price-directed / Dantzig–Wolfe |
| nested price | root over mid over leaves | price-directed / Dantzig–Wolfe at both levels |
| flat resource | root over leaves | resource-directed / Benders |
| mixed | price root over a resource mid | price above, Benders below, pure-feasibility recourse |

Refusals come in two kinds, and the difference matters to an author. A
**compatibility note** means the document is *valid* and this runtime cannot
execute it, so submission refuses it before publishing anything. A **refusal
code** means the document asks for something *unsound*, and it is rejected at
parse or at build. Integer resource recourse, substitution on a resource child,
downward mixing of paradigms in the direction that is not built, results scoped
to a non-master, and a price-over-resource mid with a non-zero epigraph are
refusal codes. A resource boundary above another resource boundary, a
Lagrangian binding, and a subgradient binding carry notes.

**Substitution is refused on a resource child because there is no local
surrogate for a cut.** On the price path there is one: a block whose subproblem
does not answer can be priced by DIP's own fallback, which is a fair
approximation of a column and is recorded as a degradation either way. A
resource child answers with a constraint the master must adopt, and the master
holds no copy of that child's recourse model — a manufactured cut would either
exclude feasible allocations or bound nothing, and both would be reported as
`optimal` rather than as degraded. The resource path's default is therefore
abort, and one consequence is worth stating plainly: pausing a resource-directed
child ends its parent's solve, by design.

Both kinds are held in place by a test that asserts the *exact* note text or
the *exact* code rather than merely that something was refused — because "it
was refused" is satisfied by a document that was invalid for an unrelated
reason, which is how a control silently stops testing what it names. The
purpose of that file, in one sentence: a silent capability claim cannot appear
without failing a named test.

## Known limits

None of the following withdraws a shape. Each is a condition under which a
document *of* a listed shape does not finish, named so that if you meet one you
recognise it instead of doubting the shape. Each has a fixture that pins it.

**A mid cannot report an infeasible inner problem upward.** If a parent prices
a mode the mid's inner problem cannot deliver, the mid has no way to say so; it
re-prices instead and the campaign does not finish. This shows up on both the
nested-price and the mixed shapes — two code paths, one missing capability. A
nested document whose every advertised mode is deliverable runs to its optimum
in seconds.

**A four-leaf flat price campaign on the pinned instance does not converge**
within its window. What is measured is the round count, not a leaf-count rule;
whether the cause is the leaf count, that instance's degeneracy, or the round
rate against the transport is explicitly not settled.

**A flat Benders master over more than one child can stall short of the
optimum.** This one is a runtime defect rather than a shape limit, and its
condition is numeric: when each child's own recourse is individually within the
epigraph but their sum exceeds it, every child answers "no cut", the stall rule
fires, and the loop stops with the true optimum strictly between its own bound
and its own incumbent. The cause is that the master's epigraph stands for the
sum while the decision to send a cut is taken per child against that same
total, and a child comparing its own recourse against an aggregate cannot
decide whether the aggregate cut is violated.

The last one is the one to internalise, and it is also the clearest argument
for the status vocabulary: until it is fixed, read `feasible` with a non-zero
gap as "not proven optimal", which is exactly what it says. A run that reported
`optimal` there would be a worse failure — the loop claiming a proof it does
not have.

## A note on lineage

PlasticFog does not fork DIP. The one place it reaches into the vendored
sources is a pre-hook on DIP's pricing loop. DIP calls the application's
relaxed-solve once per block, and each of those calls publishes to one
subproblem service and blocks until that service answers — so the remote solves
are serialised inside every pricing round, three round trips where one would
do. The hook lets the application answer *all* blocks of a round in one call,
so it can publish every block's prices together and let the remote solves
overlap. It fires only in the rounds where DIP itself is already doing all
blocks; round-robin rounds keep the per-block path untouched.
