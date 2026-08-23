# Competitive analysis

<!-- dc:status=polished dc:owner=DC3 -->

This section places PlasticFog beside the other frameworks a prospective user
might reasonably weigh. Each page describes what the other tool is, where it
overlaps with PlasticFog, where the two differ, and when you should prefer the
other one.

## Lineage, not competition

PlasticFog is built on open optimisation infrastructure, and the projects it is
built on are not on the list below.

It uses **COIN-OR DIP** for price-directed decomposition, with a vendored
batch-pricing pre-hook that lets one call answer a whole pricing round.
**SYMPHONY**, **CBC**, **CLP** and **HiGHS** are engines beneath it. **Zimpl**
is the modelling seam. These are foundations. Nothing in this section is a
comparison with them.

## What PlasticFog claims as differentiating

Four things, all of which the current build does:

1. **Nested, mixed-paradigm decomposition** — Dantzig–Wolfe and Benders
   composable, with adjacent-level coupling — expressed as a distributed
   runtime contract among long-lived services, rather than as a single-process
   library call.
2. **Fully-runtime dynamic service placement**, with a live control plane, spot
   updates against a running system, and in-memory Zimpl recompilation.
3. **Speculative farming**: inexact GPU engines run as speculative column farms
   while exact engines certify claims, with proof debt tracked explicitly, so
   inexactness is managed rather than terminal.
4. **Introspective artifacts as first-class evidence** — machine-checkable run
   reports, independent monolith oracles, schema-validated problem documents.

The third is this section's subject; the first is what makes it hard to
replicate elsewhere.

## How to read these pages

The comparisons are made at the level of **what a framework's contract is**,
not at the level of benchmark numbers. There are no performance tables here,
because there is no measurement of another framework that this documentation
has made and could stand behind.

Where a page says PlasticFog differs, it is describing a different layer of the
stack rather than a better implementation of the same layer. Several of the
tools below are excellent at what they do, and more than one of them is
complementary to PlasticFog rather than an alternative to it. Where that is
true, the page says so.

Some statements on these pages describe third-party projects that move
independently of this documentation. Those are flagged for re-verification
before publication rather than presented as current fact.

## The pages

| Approach | Overlap in one line |
|---|---|
| [Plasmo.jl](competitive/plasmo.md) | graph-structured modelling with distributed solves — the closest overlap in spirit |
| [Coluna.jl](competitive/coluna.md) | branch-and-price as a framework, over JuMP |
| [SDDP.jl](competitive/sddp.md) | nested Benders for multistage stochastic programs |
| [Scenario decomposition frameworks](competitive/scenario-decomposition.md) | distributed subproblem solves over batch jobs |
| [GPU-first solvers](competitive/gpu-first.md) | the engine class PlasticFog embeds |
| [Monolithic solvers](competitive/monolithic.md) | no structural overlap; engines beneath the orchestration layer |

## On novelty, stated carefully

PlasticFog's own record is explicit that the mathematics here is not new.
Multiple columns per iteration is the opening observation of the column
generation survey literature; pricing against modified duals is what the
stabilization line has done for decades; drawing several perturbed vectors from
a neighbourhood of the true dual to obtain diverse columns is close to Interior
Point Stabilization; and pricing heuristically then verifying exactly is
classical branch-and-price engineering. The published GPU work in this area is
about making the LP solve fast, which is a different question from what a
decomposition should ask K times per round.

What is claimed as new is systems work: a trust boundary between a block that
claims and a master that adjudicates, with the claim carried on the wire as a
proof token, unproven claims ledgered as debt, riders issued to settle them, a
terminal invariant no policy value can switch off, and escalation when a claim
turns out to be false. Those are the parts that make the guarantees
non-vacuous, and they are the parts a paper about column selection does not
need to have.
