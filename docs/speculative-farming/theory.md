# Theory

<!-- dc:status=polished dc:owner=DC3 -->

This section states the ideas speculative farming is assembled from, one topic
per page. It assumes linear programming and duality; it assumes nothing about
decomposition, and defines what it needs. The [Overview](index.md) is the
shorter route if you want the argument before the machinery.

## The one-sentence synthesis

Dantzig–Wolfe column generation asks a block two questions in one call, and
they have wildly different costs. *"Here is a column"* is a proposal, and a
proposal is cheap to verify — a dot product the master computes for itself.
*"There is no improving column"* is the negative claim, it cannot be verified
by inspection because there is no artefact to inspect, and it is the only claim
in the exchange whose falsity changes the answer.

The division of labour follows directly:

> **Inexact engines farm. Exact engines certify. Certification is budgeted and
> audited rather than uniform.**

## The four topics, and how they compose

**[Column generation & pricing](theory/column-generation.md)** establishes the
loop and the asymmetry. It defines master, block, column and reduced cost,
explains why pricing is the hot loop, and shows the arithmetic the master
performs on every proposal it is offered. Everything else on this page is a
consequence of that asymmetry.

**[First-order LP & inexactness](theory/first-order-lp.md)** says what makes an
engine *inexact* in a precise sense, in fair terms. First-order methods reach
an approximate primal–dual pair through cheap, highly parallel operations,
which is why a GPU suits them and why they do not finish holding a basis. The
page then shows where that distinction is written down in the runtime: one
capability bit per engine, defaulting to the untrusting value.

**[Proof debt & certification](theory/proof-debt.md)** is the accounting. If
inexact engines may not close the loop, every unproven emptiness claim is a
liability, and the framework tracks it: policy modes decide which
certifications happen inline, the master keeps a ledger, and a structural
terminal invariant guarantees that no run converges on an unproven,
uncertified claim. An audit failure — a certification that finds a column where
the claim said none existed — escalates the rest of the run.

**[K-exchange farming](theory/k-exchange.md)** is the speculation strategy: how
the master obtains K candidates per block per round by sending K views of the
block's prices, how those views are generated deterministically, and which
candidates survive re-verification.

## How they fit together

The first two topics are the *premise*: verification is asymmetric, and some
engines are entitled to make the negative claim while others are not. The last
two are the two things the framework does with that premise — one to gain speed
(farm more proposals per round) and one to keep exactness (certify the claims
that matter, and account for the rest).

They are independent in configuration and complementary in effect. A document
may farm without any certification policy, carry a policy without farming, or
do both; they touch different fields, and neither changes the answer a run
returns.

## What none of it buys

Farming buys columns per round, which shortens a run when the pricing call is
the bottleneck and the master is not. A certification policy buys certification
calls not made, which removes an exact solve from the inner loop of a run whose
engine cannot certify.

Neither buys a better bound, a tighter formulation, or a different answer. The
answer is identical; only the path to it and the cost of the path change. Any
measurement showing otherwise is a defect, and the test lanes described under
[Testing](testing.md) are built to say so.

**See also:** [Using speculative farming](using.md) ·
[Competitive analysis](competitive.md)
