# Speculative farming

<!-- dc:status=polished dc:owner=DC3 -->

Speculative farming is how PlasticFog uses fast, inexact solvers without giving
up exactness. Fast engines *propose*; exact engines *certify*; and the
framework keeps an explicit account of what has and has not been proved. This
page is the whole idea in plain terms. Everything under
[Theory](theory.md) is the detail behind it.

## The problem it solves

Large optimisation problems are often solved by breaking them apart. One
common way — **decomposition** — splits the problem into a coordinating
**master** and several independent **blocks**. Each block is a self-contained
piece: one production line, one depot, one crew roster. The master holds only
what the blocks share, such as a machine they all queue for or a budget they
all draw on.

In the price-directed form of this, the master does not enumerate every
combination of block decisions. It sends each block a set of *prices* for the
shared resources and asks: at these prices, what is the best you can offer?
A block's answer is a **column** — one complete, feasible proposal for its own
part of the problem. The master collects the proposals, re-optimises over the
ones it holds, sends out revised prices, and repeats. That exchange is a
**pricing round**, and the loop ends when no block can offer anything that
would improve the master's solution.

**Pricing is where the time goes.** Every round asks every block for a full
optimisation of itself. Make those calls faster, or need fewer rounds of them,
and the whole run gets faster.

PlasticFog calls the solver behind any one of these calls an **engine**, and it
can be a different engine for each block: COIN-OR's CLP, CBC or SYMPHONY,
HiGHS, or NVIDIA cuOpt on a GPU. A GPU-resident LP engine is exactly what a
pricing bottleneck looks like it should want. And it is — with one catch.

## The catch: two questions, one call

A pricing call reports two very different things, and only one of them is cheap
to check.

The first is **"here is a column."** That is a proposal, and the master can
verify it in a single dot product against the prices it just sent out. It does
not have to trust the block's solver, its version, its arithmetic or its
hardware. It can simply check.

The second is **"there is no improving column."** That is a *negative* claim.
There is no artefact to inspect, because the claim is precisely that no
artefact exists. And it is the claim that ends the loop: accept a false one and
the master stops early and reports an optimum that is not one.

Fast first-order LP methods — the family GPU solvers such as cuOpt belong to —
stop when the primal residual, the dual residual and the duality gap all fall
below tolerances. That is an excellent approximation of an answer. It is not a
proof that a set is empty. Simplex finishes holding a basis, from which the
negative claim genuinely does follow.

So the two families are good at different halves of the same call.

## The idea

> **Inexact engines farm. Exact engines certify. Certification is budgeted and
> audited rather than uniform.**

**Farming.** Instead of asking each block for one column per round, the master
asks for K of them, by sending K views of the block's prices: the true one,
plus K−1 slightly perturbed ones. A perturbed view sometimes surfaces a
proposal the true view would not have found this round — and the master keeps
it, because a column is a column no matter what produced it. This is where a
fast, inexact engine earns its place: it is being asked for *quantity of
proposals*, which is what it is good at.

Every farmed candidate is re-checked by the master against the *true* prices —
never the perturbed ones that produced it — before it is allowed to become a
variable of the master problem. That is the load-bearing sentence of the
design:

> **"Speculative" describes the generator, never the data.**

The word does not mean the columns are approximate. It means the *process that
produced them* is not trusted, and the framework re-verifies its output rather
than taking its word.

**Certifying.** The negative claim is handled separately, by an engine entitled
to make it. Every engine declares in its own source whether it can certify its
own results, and the declared default is *no* — an engine that says nothing is
read as saying nothing. When a block whose engine cannot certify reports
"nothing here", an exact engine is asked to confirm it.

**Proof debt.** Confirming every such claim immediately is often wasted work.
A claim made at an interior round, if wrong, costs at most one extra round; a
claim made at the *last* round, if wrong, costs the answer. So PlasticFog lets
you defer certifications — and records every deferral as a **debt**: counted,
reported, and settled before the run ends.

One rule is structural, and no setting switches it off:

!!! note "The terminal invariant"
    No run converges on an unproven, uncertified claim. When every block has
    claimed it has nothing and any of those claims is uncertified, the master
    does not end the loop. It goes back and settles them first.

The result is that speed is gained where it is safe to gain it, and the
accounting is visible rather than implicit. If a certification ever finds a
column where a block claimed there was none, that is an **audit failure**: the
run escalates, certifies everything from then on, and says so.

## What it does not change

Farming buys columns per round. A certification policy buys certification calls
not made. Neither buys a better bound, a tighter formulation, or a different
answer.

**The answer is identical.** Only the path to it, and the cost of that path,
change. A measurement showing otherwise would be a defect, and the
[test lanes](testing.md) are built to catch exactly that.

## The class of problems this targets

The shape speculative farming suits is a familiar one: several units, each with
its own internal choices, contending for something scarce that is handed out
centrally. The example corpus this framework is developed and evaluated against
is drawn from that class, and it looks like this:

- **Production and process scheduling** — a press shop feeding two assembly
  lines from one bottleneck press; furnaces choosing melt plans under a shared
  power cap; bakery ovens under a flour budget; glass kilns under a gas
  allowance; plating tanks under one discharge permit; print-shop jobs across
  presses.
- **Logistics and haulage** — leasing depot capacity a year ahead and buying
  in haulage for whatever it cannot cover; mine trucks over haul cases; a
  container yard across zones; warehouse and depot shelving across sites.
- **Crew, fleet and facility assignment** — wind-farm maintenance crews across
  scenarios; ferry charters; university rooms across departments; hospital
  wards; data-centre halls under a power envelope.

These are worked example problems used to exercise and evaluate the framework
across its authoring modes and decomposition shapes — not deployments, and not
customer accounts. They are the *class* of problem the machinery is built for:
blocks with rich internal structure, a thin coupling between them, and a
pricing call expensive enough that getting more out of each one is worth
paying for.

## Where to go next

| You want | Read |
|---|---|
| to configure and run it | [Using speculative farming](using.md) |
| the mathematics and the mechanism | [Theory](theory.md) |
| how it compares to other frameworks | [Competitive analysis](competitive.md) |
| how it is tested | [Testing](testing.md) |
| the decomposition paradigms underneath | [Decomposition paradigms](../architecture/decomposition.md) |
