# Column generation & pricing

<!-- dc:status=polished dc:owner=DC3 -->

This page explains the pricing loop of a Dantzig–Wolfe decomposition, what a
*reduced cost* is, and why one of the two things a pricing call reports is
cheap to check while the other is not. That asymmetry is the foundation the
rest of speculative farming is built on.

## The loop

A price-directed decomposition splits a problem into a **master** and several
**blocks**. The master holds the constraints that link the blocks — a shared
machine, a shared budget, a shared crew; the blocks hold what is private to
each of them. Rather than enumerate every combination of block decisions, the
master works over a *restricted* set of block proposals and asks for more when
it needs them.

A **column** is one such proposal: a complete, feasible choice for one block,
expressed as the contribution that choice makes to the master's rows. The
master solves its restricted problem, reads the dual prices of its linking
rows, and sends each block a **reduced-cost vector** — the block's own costs
adjusted by what the shared resources are currently worth. The block answers
with its cheapest proposal at those prices. That exchange is one **pricing
round**, and the loop repeats until no block can improve the master.

Pricing is the hot loop: it runs once per block per round, and each call is a
full optimisation of the block. Speeding up a column-generation run therefore
means making each pricing call cheaper, or needing fewer rounds of them.

## The two questions, and their very different costs

A pricing call answers two things at once.

The first is **"here is a column."** A proposal is cheap to *verify*. Given
the round's true reduced-cost vector \( d \) and a proposal with support
\( S \) and coefficients \( x_i \), its reduced cost is a dot product:

\[ \bar{c} \;=\; \sum_{i \in S} d_i \, x_i \]

The master can compute that itself, without trusting the block's solver, its
version, its arithmetic or its hardware.

The second is **"there is no improving column."** That is a negative claim,
and nothing about it is cheap. There is no artefact to inspect — the claim is
precisely that no artefact exists. It is also the claim that *ends the loop*,
and the only claim in the exchange whose falsity changes the answer: accept a
false emptiness claim and the master stops early and reports an optimum that is
not one.

## What the master actually checks

PlasticFog re-verifies every speculatively produced column master-side before
it becomes a variable, against the round's *true* reduced-cost vector — never
the perturbed vector that produced it. The check is `pf_VerifyColumn` in
`pf_ColumnVerifier.h`, written as pure arithmetic over plain types so it can be
tested without a solver, a document or a running constellation.

It is the same inequality the solver itself will apply. A candidate is admitted
when

\[ \bar{c} \;<\; \alpha_b - \varepsilon \]

where \( \alpha_b \) is the block's convexity dual and \( \varepsilon \) is
DIP's own `RedCostEpsilon`, read from DIP rather than re-typed. A column the
verifier admits still faces COIN-OR DIP's untouched acceptance test as the
final arbiter of what enters the master.

The verifier reports four outcomes and never collapses them: `admitted`,
`rejected_nonimproving`, `rejected_cost` and `rejected_malformed`. The second
is benign — a perturbed view found a vertex the true view does not want. The
third means a block's claim about a column's cost disagreed with the master's
recomputation, which is a defect in transport, indexing or engine arithmetic
rather than a fact about the problem. Keeping them apart is what makes a farm
with a broken engine fail loudly instead of reporting a plausible rejection
rate.

## Where the pricing call happens

In the distributed runtime, blocks are separate long-lived services and a
pricing round is one publication to every block followed by a reply from each.
That batching rests on a pre-hook, `solveRelaxedAll`, over vendored COIN-OR
DIP: DIP's own `solveRelaxed()` contract is one block at a time, and answering
a whole round in one call is what lets the remote solves overlap instead of
serialising. A **mid** node — a block to its parent and a master to its own
children — answers a pricing call by running its own inner decomposition;
that path is `pf_MidPricing`.

**Next:** [First-order LP & inexactness](first-order-lp.md) ·
[Overview](../index.md)
