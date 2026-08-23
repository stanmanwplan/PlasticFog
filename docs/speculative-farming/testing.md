# Testing

<!-- dc:status=polished dc:owner=DC3 -->

This page describes how speculative farming is tested: the fixture-based
approach the tests rest on, the six end-to-end lanes that exercise the
machinery, and the discipline that decides what an assertion is allowed to say.
The lane pages under [Quality & Testing](../quality/tests/index.md) carry the
detail; this page says how the pieces fit.

## The fixture, and why it comes first

The tests for this machinery are built around one reference fixture, `pfe006`.
It was **authored, hand-solved and validated before any of the machinery
existed**, and that ordering is the whole point: the fixture predicts the
numbers the lanes then measure, rather than recording what the runtime happened
to do.

It is deliberately small — one price-directed master over two child blocks,
each choosing one option from its own list against one shared capacity row — so
that every quantity is checkable on paper. Its optimum, −61, was derived by hand
four independent ways, including the full undecomposed problem through its
Lagrangian dual and the Dantzig–Wolfe trace, and independently confirmed by
three vendored solvers on a hand-flattened single-model version. Its baseline
round count at K = 1, six, comes from the same trace.

The instance is *shaped* rather than sampled. Its objective coefficients sum to
exactly zero, which removes a dependence on the C library's random number
generator inside the solver's own initialisation and makes the initial
restricted master hand-derivable rather than machine-dependent.

That is what makes it a validation fixture and not a benchmark. Nothing about
it is representative of a large model, and it is not intended to be.

## The six lanes

| Lane | What it demonstrates |
|---|---|
| [K1](../quality/tests/e2e/k1-engines-pfe006-k1.md) | the baseline: the fixture with no speculation stated anywhere. The hand-derived optimum in the hand-derived number of rounds, and not one farm stamp — the defaults-off proof at lane level |
| [F1](../quality/tests/e2e/f1-engines-pfe006-farm.md) | the column farm: four candidates per child. The farm schedule matches the one derived on paper, and the answer does not move |
| [D1](../quality/tests/e2e/d1-engines-pfe006-debt.md) | deferred certification: nothing certified inline, every claim ledgered, and the terminal interception settling the ones that would otherwise have closed the run uncertified |
| [S1](../quality/tests/e2e/s1-engines-pfe006-sampled.md) | sampled certification: the draws are exactly the pinned ones, the settlement matches the one predicted on paper, and the terminal invariant overrides sampling where it must |
| [X1](../quality/tests/e2e/x1-engines-pfe006-escalate.md) | audit failure and escalation: a child is made to claim it has nothing when it does. The lie is caught, the run escalates, and the true optimum is reached anyway |
| [E1](../quality/tests/e2e/e1-engines-all.md) | the engine matrix: the engine named on each binding is the engine that actually solved it, and the standing engine refusals still refuse |

Each lane pairs a document, a runner and an assert script, and the lane
inventory is reconciled so that no lane, document, assert script or ledger row
exists without the other three. A lane with no document, or a document no lane
runs, is treated as a defect in the inventory rather than an accident.

## How the premises are made reachable

Two of the lanes could not exist without test hooks, and the reason is worth
stating because it bounds what those lanes prove.

The CPU engine both children bind reports that it proves its own results. Every
emptiness claim it makes is therefore proven by the engine that made it, a
deferring policy would have nothing to defer, and the ledger would have nothing
to hold. The debt lanes set an environment hook that marks the named children's
claims unproven, putting them in the state they must be in to be ledgered at
all. The escalation lane goes further and suppresses a column the child
actually found, manufacturing a claim that is *false* — which is the only way
to exercise escalation without waiting for an engine to be wrong.

**The hooks are one-directional, and that is the design.** Nothing can force a
result to be marked proven, nothing can manufacture a certification, nothing
can suppress the terminal interception, and nothing can make a timeout settle a
claim. Every hook makes the system do *more* work and treat *more* claims as
suspect. The worst a hook can do to this build is fail a run loudly.

## What the assertions are allowed to be

Two rules shape every check.

**An oracle is derived before it is measured.** The numbers the assert scripts
check — claim counts and the rounds they arise at, farm stamps and their
thresholds, settlement totals, the residual debt — are computed on paper under
the same admission inequality the runtime applies, and then compared. A
measured value that disagrees with an oracle is a finding to stop on with both
numbers in hand. **An assertion adjusted to fit a runtime is a fabrication.**

**Recorded is not the same as asserted.** Some values are schedule-dependent
and are deliberately *recorded* rather than asserted, because pinning a literal
that a lawful implementation difference could move would be an invented
expectation. Those values are evidence about what happened, not oracles for
what must happen next — and the gap that leaves is itself recorded as an open
question rather than hidden.

## What the lanes prove about the rest of the system

Alongside their own subjects, these lanes carry the negative results that make
speculative farming safe to leave in the build.

A farmed exchange and a certify rider are **ordinary reduced-costs cycles**: no
new solver state and no new transition. The state-transition fixture is
unmoved, and every lane measures zero rejected-command records on every stream.
The message definitions are untouched, no results-envelope field was added, no
vendored file was edited, and a document that states neither block executes the
same instruction stream it did before either feature existed — measured, not
argued, by a byte-stability matrix across the inherited lanes.

**See also:** [Test index](../quality/tests/index.md) ·
[Test harness & fixtures](../quality/tests/harness.md) ·
[Using speculative farming](using.md)
