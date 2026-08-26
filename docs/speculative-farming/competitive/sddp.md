# SDDP.jl

<!-- dc:status=polished dc:owner=DC3 -->

SDDP.jl is the strongest available tool for the problem class it targets, and
that class is narrower than PlasticFog's by design. The two are complementary
rather than competing.

## What it is

SDDP.jl implements stochastic dual dynamic programming for multistage
stochastic programs, with the problem expressed as a **policy graph**: stages
as nodes, transitions as arcs, and uncertainty realised stage by stage. The
algorithm is a nested Benders decomposition over that graph, refining a
piecewise-linear value-function approximation at each node from cuts generated
along sampled forward passes.

It is mature, well documented, and widely used in the domains that have this
structure — hydro-thermal scheduling above all.

## Where it overlaps

Nested decomposition through a mid. PlasticFog's Benders paradigm passes an
allocation down and receives a cut back, and its **mid** nodes are simultaneously
a master to their children and a subproblem to their parent — the same nesting
shape SDDP.jl's policy graph expresses stagewise.

## Where PlasticFog differs

**SDDP.jl is specialised to stagewise stochastic structure, and that
specialisation is its strength.** Because it knows the structure is stagewise
and the uncertainty is stage-independent, it can reuse value-function cuts
across stages, sample forward paths, and bound the policy — none of which is
available to a framework that does not assume the structure.

PlasticFog targets general nested and mixed structures instead: a price-directed
master over blocks that run their own Benders loops, coupling between adjacent
levels, heterogeneous engines across the blocks of one problem, and services
placed at run time. It gains generality and gives up everything a framework can
only do by knowing that its stages are stages.

## When to prefer SDDP.jl

Prefer SDDP.jl whenever your problem *is* a multistage stochastic program with
stagewise structure. If the policy graph is a natural description of your
problem, use the tool built for it — a general nested decomposition will do
more work to reach a weaker statement.

PlasticFog is the answer when the nesting is structural rather than temporal:
sites within a network, cells within a line, departments within an institution,
where the levels are organisational and the coupling is a shared resource
rather than a transition between stages.
