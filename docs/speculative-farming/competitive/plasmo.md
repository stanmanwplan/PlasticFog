# Plasmo.jl

<!-- dc:status=polished dc:owner=DC3 -->

Plasmo.jl is the closest overlap in spirit to PlasticFog on this list, and the
comparison is worth making carefully because the two operate at different
layers rather than at the same one.

## What it is

Plasmo.jl is a Julia package for graph-structured algebraic modelling. A model
is expressed as an **OptiGraph**: nodes carry their own variables, constraints
and objectives, and edges carry the linking constraints between them. That
graph can then be partitioned, aggregated and handed to solvers, and through
RemoteOptiGraph a partitioned graph's solves can be distributed across worker
processes.

It is a strong tool with an active user base, and the graph abstraction is a
genuinely good way to express a structured model.

## Where it overlaps

Both projects start from the same observation: real problems have structure,
that structure should be first-class rather than discovered by a presolver, and
the pieces can be solved on different machines.

## Where PlasticFog differs

**Plasmo distributes the model; PlasticFog's contract is the decomposition
algorithm itself.** In Plasmo, the graph describes the problem and the solution
algorithm comes from the solvers attached to it. In PlasticFog, the distributed
contract *is* the algorithm: pricing exchanges, cut exchanges, control,
placement and certification are the protocol that long-lived services speak to
one another. Nesting Benders inside Dantzig–Wolfe, running heterogeneous
engines across the blocks of one problem, and carrying a proof token on a
pricing reply are properties of that protocol, not of a model object.

The consequence for a user is a different unit of work. A Plasmo user assembles
a graph and calls a solve. A PlasticFog user submits a problem definition to a
running constellation of services, which may be placed dynamically and updated
while the system is up.

## When to prefer Plasmo.jl

Prefer Plasmo when you are working in Julia and want a graph-structured
modelling layer over the JuMP ecosystem, when your solution method is one your
attached solver already implements, or when you want the whole thing in one
process without operating a service substrate. Its abstraction is lighter, its
dependency footprint is smaller, and for a large class of structured models it
will get you to an answer with much less machinery.

Prefer PlasticFog when the *algorithm* is the thing that has to be distributed
and heterogeneous — when you need mixed-paradigm nesting across machines, a
different engine per block, or an exactness contract over inexact engines.

*Comparison as described here reflects the landscape as of August 2026 and
remains subject to further verification.*
