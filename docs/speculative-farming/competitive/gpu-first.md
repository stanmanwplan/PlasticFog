# GPU-first solvers

<!-- dc:status=polished dc:owner=DC3 -->

This page is different from the others in the section: GPU-first LP and MIP
solvers are not an alternative to PlasticFog, they are the **engine class
PlasticFog embeds**. NVIDIA cuOpt is one of the engines this build carries.

## What they are

GPU-first solvers apply first-order methods — the cuPDLP research lineage and
its descendants — to linear programs, replacing basis factorisation with cheap,
massively parallel operations. On large sparse problems, that can deliver very
fast approximate solves. See
[First-order LP & inexactness](../theory/first-order-lp.md) for why the method
suits the hardware.

## Where they overlap

They do not overlap; they compose. PlasticFog does not implement an LP
algorithm and has no ambition to. A GPU-first solver used inside PlasticFog is
doing exactly what it does standalone, at the pricing call.

## What PlasticFog adds

**An exactness contract around an engine that does not have one.** Used
standalone, a GPU-first solver gives you a fast approximate solve and a
termination status. Inside PlasticFog it is wrapped as a speculative column
farm: the master asks it for several candidate proposals per round, re-verifies
every one of them against the true reduced-cost vector before any becomes a
variable, and refuses to let it end the pricing loop.

The refusal is not a judgement about the solver. `cuopt` declares
`proofStatuses` false in its own adapter source because this build has not
measured that engine's termination vocabulary, and a status nobody has measured
is not a proof. Every emptiness claim it makes is therefore ledgered as proof
debt and settled by an engine entitled to settle it, with the accounting
visible — see [Proof debt & certification](../theory/proof-debt.md).

There is no build-time dependency on cuOpt anywhere in the tree. The adapter
compiles on every machine and a run-time probe decides whether the engine can
actually execute here.

## When to prefer the standalone solver

Prefer the solver on its own whenever you have a single large LP and want it
solved fast, and an approximate answer within your tolerance is the answer you
need. That is the case it is built for, and interposing a decomposition
framework would add coordination cost for nothing.

PlasticFog earns its place when the problem is structured, when the pricing
call is the bottleneck, and when an approximate answer is *not* acceptable as
the final word — because the framework is precisely the machinery that converts
fast-and-approximate into fast-and-certified.

*Comparison as described here reflects the landscape as of August 2026 and
remains subject to further verification.*
