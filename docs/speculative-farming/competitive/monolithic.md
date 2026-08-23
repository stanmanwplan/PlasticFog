# Monolithic solvers

<!-- dc:status=polished dc:owner=DC3 -->

Commercial and open monolithic solvers — Gurobi, CPLEX, Xpress, FICO, and HiGHS
used standalone — are potential complements to PlasticFog rather than
alternatives to it. This page is short because there is little to compare.

## Where the overlap is not

A monolithic solver takes a model and returns a solution. It may exploit
structure internally — and modern ones exploit a great deal of it — but that
exploitation is not a contract the user holds. There is no user-visible
decomposition to author, no way to place a block on another machine, and no
protocol between the pieces.

PlasticFog's whole surface is that contract: which rows couple which blocks,
which paradigm handles each level, which engine solves each block, where each
service runs, and what each answer is required to certify.

## Where they meet

**Beneath the orchestration layer, as engines.** PlasticFog's engine seam wraps
solver invocations behind one interface, resolved by name from a binding's
`solver.engine`. HiGHS is embedded in the build today, alongside COIN-OR's CLP,
CBC and SYMPHONY. A monolithic solver in this picture is not a competitor to
the framework; it is the thing that solves a block.

The framework also uses a monolithic solve as an *oracle*. An independently
assembled single-model version of a decomposed problem, solved monolithically,
is one of the checks that the decomposition returned the right answer — a use
in which being a different implementation is the entire point.

## When to prefer a monolithic solver

Prefer one whenever your problem fits. If a single solver call returns your
answer in acceptable time, use it. Decomposition is machinery you take on when
the problem will not fit, when the structure is genuinely distributed — pieces
that live in different places, under different owners, on different hardware —
or when the coupling is thin enough that exploiting it explicitly beats solving
through it.

Reach for PlasticFog when the monolith stops being an option, or when the
structure is a fact about your organisation rather than only about your matrix.
