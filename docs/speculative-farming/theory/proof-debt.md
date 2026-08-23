# Proof debt & certification

<!-- dc:status=polished dc:owner=DC3 -->

This page explains how PlasticFog accounts for emptiness claims it has not
proved. A skipped certification is a **debt**: carried, counted, reported and
settled before a run terminates, never quietly assumed.

## Claims, and who is entitled to make them

When a block answers a pricing round with no improving column, that is a
**claim**: "my improving set is empty at these prices." Only the exchange
carrying the true reduced-cost vector can carry one; a perturbed view that
offers nothing has said nothing about the true view.

The claim travels with one word of provenance: the reply carries `proven` or
`unproven`, and that is the entire wire vocabulary. It is the one fact the
master cannot compute for itself — whether the block's own engine proved the
block's own claim. Everything else on this page is a decision the *master*
makes, so no reply is allowed to assert it.

The master then adjudicates. A reply is a claim when it carries no point, or
when its recomputed true reduced cost fails the same inequality COIN-OR DIP is
about to apply — the block's convexity dual \( \alpha_b \) against DIP's own
`RedCostEpsilon`. Using DIP's test rather than a near-equivalent matters: a
ledger built on a different test would record claims the solver does not
believe in and miss claims it does.

## The policy: which certifications happen inline

An unproven claim can be certified on the spot by an engine entitled to certify
it. The budget for that is one field,
`solver.guarantee.certification.policy.mode`:

| Mode | Behaviour |
|---|---|
| `always` | certify every unproven claim inline; semantically identical to the whole block being absent |
| `terminal_only` | skip every inline certification, stamp a debt event, settle at the terminal interception |
| `sampled` | certify each unproven claim with probability `sampleRate`; otherwise stamp a debt event |

`mode` is required with no default, because each is a different cost and none
is obviously right. The master keeps the ledger, per block per round, with a
running total carried through the run: a debt only the block knew about would
be a debt nobody could settle.

## The terminal invariant

> **No run converges on an unproven, uncertified claim.**

This is structural. It is not a mode, not a default, and no combination of
policy values switches it off.

It can be cheap because an uncertified claim is only dangerous in one place. At
an interior round a wrong claim costs at most an extra round. At the moment the
master would act on "no block has anything" by ending the loop, it costs the
answer. So that is where the debt is settled: when every participating block
has claimed empty and any claim is uncertified, the master does not return
empty — it re-issues the same true vector to exactly the uncertified blocks
with a **certify rider** attached, and returns empty only once every claim in
the round is proven or certified.

`terminal_only` is therefore not a mode that skips certification. It is a mode
that defers all of it to the one round where it is load-bearing.

## Audit failure and escalation

An **audit failure** is a certification that finds an improving column where
the claim said there was none — a counterexample, not a disagreement about a
value. It is the most informative event the system can emit: direct evidence
that this engine's emptiness claims are not to be trusted on this problem, at
this tolerance, which no static capability declaration could have supplied.

The response is run-scoped and does not de-escalate: from the first audit
failure onward every emptiness claim is certified whatever the policy says, and
no sampling draw is taken for the rest of the run. A system that noted the
counterexample and carried on sampling would be turning a measurement into a
statistic instead of a decision.

## What is reported

Certification decisions are emitted as named events on the structured log
stream — `certified_inline`, `terminal_skip`, `sampled_skip`,
`certified_at_terminal`, `audit_fail` and a once-per-run `terminal_settle` —
each carrying the running `proof_debt` count. Named events rather than a
boolean, because "certified", "skipped by policy" and "skipped by a draw" are
three different reasons for the same outcome.

The settlement reports how many claims the run saw and how each was accounted
for, and *names* the **residual debt** rather than merely counting it: the
unsettled interior claims are listed by block and round, because a debt a
reader cannot locate is a number rather than a record. Residual debt is not a
gap — the policy decides *when* a claim is checked, never *what* the answer
is.

## And silence is never proof

A certify rider that never comes back is a timeout, and no option of the
timeout contract may treat a timeout as a certification. The run fails loudly
with the unsettled claim named, rather than concluding anything.

**Next:** [K-exchange farming](k-exchange.md) ·
[Using speculative farming](../using.md) · [Overview](../index.md)
