# First-order LP & inexactness

<!-- dc:status=polished dc:owner=DC3 -->

This page explains what a first-order LP method is, why running one on a GPU
can be fast, and why "fast" and "entitled to end a proof" are different
properties. It then shows where PlasticFog writes that distinction down: a
single capability bit on each engine.

## Two families of LP solver

The simplex method walks vertices of the feasible region. At every step it
holds a **basis** — an explicit algebraic description of the current vertex —
and when it stops, the basis and the dual solution it implies form a
certificate: optimality can be checked from what the method already holds.
Interior-point methods reach the optimal face by another route but likewise
finish with a verifiable primal–dual pair.

**First-order methods** do neither. They treat the LP as a saddle-point problem
and iterate with cheap operations — matrix–vector products, projections, scalar
steps — never forming or factorising a basis. Each iteration costs a small
multiple of one pass over the constraint matrix, and those passes are exactly
what a GPU does well: highly parallel and memory-bandwidth-bound. On large,
sparse problems that can be a substantial speed-up over a method that must
factorise.

**This is a description of the trade, not a criticism.** First-order methods
are a serious and fast-moving line of work, and for many problems they are the
right tool. The point here is narrower: what they hand back at termination.

## What "inexact" means precisely

A first-order method stops when its primal residual, dual residual and duality
gap fall below tolerances. That is an *approximate* optimality statement about
an *approximate* primal–dual pair — usually a very good approximation, but not
a basis and not a certificate that a structural question has been settled.

For column generation the question that matters is not "what is this LP's
objective value" but "**is this block's improving set empty?**" — the negative
claim from [Column generation & pricing](column-generation.md). A residual
below a threshold is evidence about a numerical quantity, not a proof about a
set.

So the division of labour is: **inexact engines farm, exact engines certify.**
An inexact engine is very good at producing candidate columns quickly and in
quantity. It is not entitled to end the pricing loop.

## Where PlasticFog writes this down

The seam is one boolean on each engine's capability snapshot,
`pf_EngineCaps::proofStatuses`, whose declared default is `false`: an adapter
that says nothing is read as saying no. Every engine in the build states the
bit deliberately — `clp`, `cbc`, `symphony` and `highs` set it true, `cuopt`
sets it false — so the default protects no engine that exists today. It
protects the adapter nobody has written yet, untrusted by construction until
its author makes a positive claim in its own source.

The predicate the runtime consults reads that bit and the solve's own status
and nothing else: a result is proved only when the engine claims
`proofStatuses` **and** the solve terminated optimal. A time limit, an
iteration limit or an abandoned solve is never a proof — reading "no improving
column" off one of those is how a column-generation loop declares a convergence
it never reached.

`cuopt` answers false for a stated reason: this build has never measured that
engine's termination vocabulary, and a status nobody has measured is not a
proof. That is a declaration about what has been established, not a judgement
about the solver.

## Three questions that are deliberately not merged

PlasticFog answers three questions about an engine and keeps them apart,
because merging them would let a hardware change widen a mathematical claim.

| Question | Decided by | Moves with the machine? |
|---|---|---|
| **Legality** — may this engine hold this role? | the role table in the codec | no |
| **Availability** — can this build run it here and now? | the run-time probe | **yes** |
| **Capability** — can it produce what this role's answer requires? | the capability snapshot | no |

Availability for `cuopt` is a live measurement, not a build-time fact: there is
no build-time dependency on NVIDIA cuOpt anywhere in the tree, and its API surface is
reached at run time. One probe answers, with four outcomes in a fixed order —
`lib_missing`, `symbol_mismatch:<name>`, `no_gpu`, `ok` — and the same function
answers for the validator and the runtime, so the two cannot drift.

Installing a GPU makes a document *executable*. It does not give an adapter a
capability it never claimed.

**Next:** [Proof debt & certification](proof-debt.md) ·
[Overview](../index.md)
