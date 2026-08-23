# Scenario decomposition frameworks

<!-- dc:status=polished dc:owner=DC3 -->

This page covers the family of frameworks that decompose a stochastic program
by scenario and solve the pieces in parallel — the mpi-sppy and PySP lineage,
progressive hedging implementations, and the block-annotation facilities in
commercial modelling systems such as GAMS and AMPL.

## What they are

A scenario-decomposed stochastic program splits into one subproblem per
scenario, coupled by non-anticipativity: the first-stage decisions must agree
across scenarios. Progressive hedging and its relatives enforce that agreement
iteratively, with a penalty term and a multiplier update, while the scenario
subproblems solve independently. Because those subproblems are genuinely
independent within an iteration, the natural implementation distributes them —
typically over MPI, as a batch job on a cluster.

This is a well-established and effective approach, with a substantial
literature and production use.

## Where they overlap

Distributed subproblem solves under a coordinating step. Both PlasticFog and a
scenario-decomposition framework fan work out to many processes, wait for the
answers, and use them to update what the coordinator holds.

## Where PlasticFog differs

**Two differences, and the second is the more consequential.**

The first is structure. Scenario decomposition is specialised to
scenario-structured stochastic problems, where the blocks are copies of one
model under different data and the coupling is non-anticipativity. PlasticFog
targets general nested and mixed structures, where blocks are different models,
the coupling is a shared resource or an allocation, and the paradigms compose.

The second is the execution substrate. These frameworks are typically batch
jobs: the topology is fixed when the job is launched, the processes exist for
the duration of the run, and the shape is a property of the submission script.
PlasticFog's blocks are long-lived services on a live control plane, with
placement resolved at run time, topology that can change while the system is
up, and spot updates applied to a running constellation that redistribute only
what actually changed.

## When to prefer them

Prefer a scenario-decomposition framework when your problem is a stochastic
program with scenario structure and you have a cluster and a scheduler. That
combination is exactly what the MPI batch model is good at, the algorithms are
well understood, and the operational story is one you probably already run.

PlasticFog is the better fit when the topology is not fixed for the run's
duration, when blocks are heterogeneous models rather than scenario copies, or
when an inexactness contract over the block solvers is part of what you need.

*Comparison as described here reflects the landscape as of August 2026 and
remains subject to further verification.*
