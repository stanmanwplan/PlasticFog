# Coluna.jl

<!-- dc:status=polished dc:owner=DC3 -->

Coluna.jl is a branch-and-price framework, which makes it the closest
comparison on this list at the level of *algorithm*: it is a column-generation
framework, and so is part of PlasticFog.

## What it is

Coluna.jl implements branch-and-price — and branch-price-and-cut — over JuMP,
with the decomposition expressed through BlockDecomposition annotations on the
model. The user annotates which parts of a JuMP model form the blocks and which
constraints link them, and Coluna builds and runs the column-generation and
branching machinery over that structure.

It is a serious, well-engineered implementation of a hard algorithm, and it
gives a JuMP user access to branch-and-price without writing the loop.

## Where it overlaps

Dantzig–Wolfe column generation as a *framework* rather than as something each
user re-implements. Both projects take the position that the decomposition
algorithm is infrastructure, and both make the block structure something the
author declares rather than something a solver guesses.

## Where PlasticFog differs

**Coluna is an algorithmic framework within a process; PlasticFog is a
distributed runtime.** Coluna's blocks are objects in one Julia session. In
PlasticFog a block is a long-lived service that may be on another machine, and
a pricing round is a publication to every block and a reply from each. That
difference is the origin of most of what is on the
[Theory](../theory.md) pages: proof tokens on the wire, a master that
adjudicates claims it cannot recompute, timeouts on certifications, and a trust
boundary between the process that proposes and the process that decides.

Two further differences follow from the same root. PlasticFog composes
paradigms — a Dantzig–Wolfe master over a block that runs its own Benders loop
— across processes, and it places services at run time, with a live control
plane and updates against a running system.

## When to prefer Coluna.jl

Prefer Coluna when your model lives in JuMP, when your problem fits comfortably
in one process, and when what you want is branch-and-price rather than a
service substrate. Coluna will give you branching over the column-generation
tree, which is a substantial piece of machinery, with far less operational
surface than a distributed runtime carries.

Prefer PlasticFog when the blocks genuinely need to be separate processes, when
they need different engines, or when an inexact engine's claims need an
exactness contract around them.

*Comparison as described here reflects the landscape as of August 2026 and
remains subject to further verification.*
