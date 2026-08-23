# K-exchange farming

<!-- dc:status=polished dc:owner=DC3 -->

This page explains the speculation strategy itself: how the master asks a block
for K candidate columns in one pricing round instead of one, how the K views of
the block's prices are produced, and which of the candidates it keeps.

## One round, K exchanges

An ordinary pricing round is one publication of the reduced-cost vector to
every block and one reply from each. A round with a farm of \( K \) is \( K \)
such exchanges, issued in order by the master over the same topics and the same
publish-then-wait discipline.

```
round r:
  exchange k=1   TRUE vector        -> every participating block
                                    <- one column each, or EMPTY
                 (the ONLY exchange that carries an emptiness claim)
  exchange k=2   perturbed view(2)  -> only blocks that answered k=1
  ...                                  with an IMPROVING column
  exchange k=K   perturbed view(K)  <- one column each, or nothing

  master: union of DISTINCT columns -> the solver
```

Three properties of that shape carry most of the design's weight.

**Exchange \( k = 1 \) is unchanged.** Same vector, same publication, same
reply handling, same column. Farming adds candidates *beside* it and never
replaces or re-orders the one column the system has always built — which is
what makes "farming off" and "farming on with everything rejected" produce
identical runs, structurally rather than empirically.

**Only \( k = 1 \) carries an emptiness claim.** A block answering \( k = 1 \)
empty leaves the round's farm at once: perturbing after an empty answer asks a
block to look harder after it has said there is nothing, which turns a claim
into a suggestion. An empty reply to a *perturbed* exchange is not a claim, not
a debt and not recorded as emptiness.

**K exchanges are one round, not K rounds.** The solver state machine is not
touched: the round raises its generated-reduced-costs event once and one
terminal event, both decided by the \( k = 1 \) exchange alone.

## How a perturbed view is produced

Each participating block gets a perturbation of *its own* \( k = 1 \) vector.
Every coefficient is scaled independently:

\[ c'_i \;=\; c_i \,\bigl(1 + \epsilon\, u_i\bigr), \qquad u_i \sim U[-1,1] \]

The draws come from a SplitMix64 stream whose normative definition is the
header `pf_SpeculationPrng.h` — constants, shifts, tuple mix and per-coefficient
read order are fixed there, and a unit test pins them against an independent
re-implementation.

Four inputs enter the mix, all document-carried or structurally determined:
`perturbation.seed`; the subproblem's id, so two blocks do not receive the same
perturbation of different vectors; the round index, so one round does not
repeat the last; and \( k \), so the perturbed exchanges of one round differ
from each other.

**No `runId`, wall clock, process id, address or thread id enters any stream.**
Two runs of one document under one seed farm identically. That is stated as a
rule rather than a hope, because a defect that depends on a per-run value is a
defect nobody can reproduce.

The perturbation is *per coefficient* for a reason worth stating: one scalar
\( u \) would scale every coefficient by the same strictly positive factor,
which cannot move a linear objective's minimiser over a fixed feasible set.
Every perturbed exchange would return the \( k = 1 \) column.

## Which candidates survive

Returned points are deduplicated across \( k = 1 \ldots K \) on a key built
from the column's support and values; the \( k = 1 \) point is always kept.
Every other survivor is re-verified master-side against the round's **true**
dense vector — never the perturbed one that produced it — and COIN-OR DIP's own
untouched acceptance test remains the final arbiter of what enters the master.

The admission threshold is \( \alpha_b \), the block's own convexity dual: the
same inequality the solver applies, evaluated K times per round rather than
once.

Reaching that number was not free. The convexity dual is deliberately *not* a
parameter of DIP's batch pricing hook — DIP subtracts it from every returned
point itself — and it was not reachable from the hook either, so the gate sat
at a conservative `0` at first: a threshold that could decline a farm the
solver would have allowed, but could never admit a column the solver would
reject. The dual was later captured by overriding a vendor virtual DIP already
calls with the round's master dual vector, with no edit to any vendor file.

The honest price of matching the solver's inequality is that a farm now fires
in rounds where the conservative gate declined it, and some of those farms
admit only the \( k = 1 \) column they already had. Detecting inert farms in
advance is an open question.

What each farm did is reported with two counts, not one: `K`, the farm size the
document asked for, and `K_effective`, the exchanges actually issued for that
block that round. A round in which two of five blocks answered \( k = 1 \)
empty farms against three, and a reading of the log cannot overstate it.

## Why the master drives it

A block-side farm — solve K perturbed instances locally, reply once with K
columns — is the cheaper shape in wall-clock terms. It is unavailable: the
reply message carries one column and the message definitions are frozen. The
master-driven shape costs K round trips and buys that freeze.

**Next:** [Using speculative farming](../using.md) · [Overview](../index.md)
