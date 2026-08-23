# Using speculative farming

<!-- dc:status=polished dc:owner=DC3 -->

This page is the practical route: what you write in a problem definition, what
the runtime does with it, what comes back, and how to design, test and deploy a
solution that uses it. It assumes you have read the [Overview](index.md) and
have run a problem before — if not, start with
[Your first problem](../getting-started/first-problem.md).

## Before you start

Speculative farming has two independent halves, and you can use either without
the other.

A **farm** (`solver.speculation`) is legal only on a `priceSubproblem` binding
whose engine reports the `lp` capability. Any other role is refused as
`solver.speculation_role_incompatible`, and an engine without `lp` as
`solver.speculation_lp_capability_required`. Both are document errors that
never retire: a farm perturbs a reduced-cost vector, which exists at no other
role, and solves the perturbed view as an LP.

A **certification policy** (`solver.guarantee.certification.policy`) sits
inside `solver.guarantee`. It refines the guarantee rather than repeating it:
the guarantee says an answer must be certified, and the policy says which
certifications happen inline and which become tracked debt.

**Reach for a farm** when your pricing subproblems are cheap relative to the
master solve and to the round trip, so paying for K solves to save a round is a
good trade. **Reach for a policy** when certification is a material share of
your run's cost and most of your claims are made at interior rounds. **Do not
reach for either to change your answer** — they cannot.

## The worked example

Every number on this page is a measurement on `pfe006`, the reference fixture
for this machinery. It is a small, hand-derived instance chosen so that every
number is checkable: a price-directed problem with one master and two child
blocks, each choosing one option from its own list against one shared capacity
row.

Its optimum, **−61.0**, was derived by hand — four independent ways, including
the full undecomposed LP through its Lagrangian dual and the Dantzig–Wolfe
trace — *before any of this machinery existed*, and confirmed by three
independent solvers. Its baseline round count at K = 1, **six**, was derived
from the same trace. That is what makes it a validation fixture rather than a
benchmark: the answers were known first, and the runtime is checked against
them.

!!! warning "These are fixture properties, not projections"
    Every figure below is a property of `pfe006`. It is a hand-derived
    validation instance, not a benchmark, and none of these numbers is a
    performance projection for your model.

## Step 1 — design the farm

The speculation block goes on the child's `priceSubproblem` binding:

```json
"solver": {
  "engine": "highs",
  "speculation": {
    "columns": 4,
    "perturbation": { "epsilon": 0.2, "seed": 20260815 }
  }
}
```

| Field | Domain | Required? | Meaning |
|---|---|---|---|
| `columns` | integer, 2 to 16 | yes, no default | Candidates per block per round, the k = 1 exchange included. A farm of one is the absence of this block; above 16 is a refusal, not a truncation |
| `perturbation.epsilon` | number, strictly between 0 and 1 | yes, no default | Every coefficient of the reduced-cost vector is scaled by `(1 + epsilon*u)`, `u` uniform on `[-1, 1]`. `0` perturbs nothing; `1` admits a sign flip, which is a different problem rather than a neighbouring view of this one |
| `perturbation.seed` | integer ≥ 0 | no, default `0` | The document-carried seed, mixed with the subproblem id, the round index and the exchange index `k` |

**There is no default farm size, deliberately:** a farm size the author did not
state is a cost the author did not choose.

**Reproducibility is a property, not an accident.** No run identifier, wall
clock, process id or address enters the random stream. Two runs of one document
under one seed farm identically, which is what makes a farmed run's defect
reproducible.

On `pfe006` with `columns: 4` on both children, the farm takes the run from
**six pricing rounds to five**, and the objective is **−61.0** either way.

## Step 2 — design the certification policy

```json
"solver": {
  "engine": "highs",
  "guarantee": {
    "requirement": "exact_required",
    "certification": {
      "policy": { "mode": "terminal_only", "seed": 20260816 }
    }
  }
}
```

| `mode` | What it does | Certifications on `pfe006` |
|---|---|---|
| `always` | Certifies every unproven claim inline. Semantically identical to the whole block being absent | **5** |
| `terminal_only` | Skips every inline certification, stamps a debt event per skip, settles at the candidate-terminal interception | **2** |
| `sampled` | Certifies each unproven claim with probability `sampleRate` | **4** at `sampleRate` 0.5 |

`mode` is required with no default, because each mode is a different cost and
none of them is the obvious one. `sampleRate` lies in `(0, 1]` and is required
exactly when `mode` is `sampled`, and refused beside any other mode.

`pfe006` presents five unproven emptiness claims. `terminal_only` buys the
whole guarantee for two certifications instead of five — on a fixture with six
rounds and one terminal round. That ratio is not a property of the fixture: the
terminal invariant is load-bearing at exactly one round of any run, so the
saving grows with the round count.

**Residual debt is reported and named.** `terminal_only` on `pfe006` leaves
three interior claims unsettled, and the runtime names them by block and round
rather than only counting them. Those are claims the run never acted on. Only a
terminal claim that is wrong can cost the answer, and the terminal invariant
guarantees no terminal claim is left unsettled.

Every figure above comes from one place, and that place is reproduced below in
full so the worked example is checkable end to end rather than on trust: the
fixture's own per-round derivation, with every dual, every admission test and
every emptiness claim.

??? note "Full per-round ledger (pfe006)"

    **The round table.** `t` is the shared capacity row's dual; `alpha_A` and
    `alpha_B` are the two blocks' convexity duals; "A's min" and "B's min" are
    the folded pricing minima the master's admission test compares against the
    corresponding `alpha`.

    | round | phase | `t` | `alpha_A` | A's min | A | `alpha_B` | B's min | B | RMP value |
    |---|---|---|---|---|---|---|---|---|---|
    | 1 | I | (`y0 = -1`) | 0.5 | 0 | **`a3` in** | 0.75 | 0 | **`b6` in** | 1.0 (phase-I obj) |
    | 2 | II | 212 | 1 | -1 | **`a2` in** | 7 | -17.5 | **`b2` in** | -45 |
    | 3 | II | 1256/5 | 1 | 1 | EMPTY | 7 | 0.4 | **`b5` in** | -274/5 |
    | 4 | II | 238 | 1 | 1 | EMPTY | -1.25 | -4 | **`b3` in** | -239/4 |
    | 5 | II | 736/3 | 1 | 1 | EMPTY | -1/3 | -1 | **`b4` in** | -182/3 |
    | 6 | II | 248 | 1 | 1 | EMPTY | 0 | 0 | EMPTY | **-61** |

    The restricted values `-45, -54.8, -59.75, -60.667, -61` decrease
    monotonically to `z*` from above, which is what a restricted master's dual
    must do and is an arithmetic check on the whole table.

    **The exhaustion table — every emptiness claim, marked.**

    | child | round | claim | kind | why |
    |---|---|---|---|---|
    | A | 3 | EMPTY | **INTERIOR** | B still produces (`b5`); the run does not end |
    | A | 4 | EMPTY | **INTERIOR** | B still produces (`b3`) |
    | A | 5 | EMPTY | **INTERIOR** | B still produces (`b4`) |
    | A | 6 | EMPTY | TERMINAL | both children empty; the run converges |
    | B | 6 | EMPTY | TERMINAL | the same round |

    Child A's improving columns are exhausted at the end of round 2, three
    rounds before the run converges at round 6, and it therefore makes exactly
    **three interior emptiness claims**. That is what a `terminal_only` or
    `sampled` policy needs in order to differ from `always` at all: with one
    child every empty claim is terminal and both policies degenerate. The
    baseline round count at K = 1 is therefore **six**.

    **The child-side stamp against the trace.** The stamp
    `no_improving_column` compares the pricing objective against zero; the
    master's admission test compares it against `alpha`. They agree only when
    `alpha` is 0.

    | round | A's objective | stamp | truth | B's objective | stamp | truth |
    |---|---|---|---|---|---|---|
    | 2 | -1 | improving | improving | -17.5 | improving | improving |
    | 3 | 1 | EMPTY | EMPTY | 0.4 | EMPTY | improving — **disagrees** |
    | 4 | 1 | EMPTY | EMPTY | -4 | improving | improving |
    | 5 | 1 | EMPTY | EMPTY | -1 | improving | improving |
    | 6 | 1 | EMPTY | EMPTY | 0 | EMPTY | EMPTY |

    The single disagreement is B at round 3, and it is unavoidable rather than
    a design slip: round 3's dual `251.2` is the one round whose `t` overshoots
    `t*`, `m_B` is non-decreasing in `t`, and so `m_B(251.2) > m_B(248)`. No
    choice of cost anchor can make B's stamp read "improving" at a round where
    its folded minimum exceeds its value at the optimum while also reading
    "empty" at the optimum. It is recorded rather than hidden, and it is a fact
    about the current runtime's stamp, not about the fixture.

## Step 3 — decide what happens if a certification never comes back

A **certify rider** is the exchange that settles a deferred claim.
`riderTimeout` is its timeout contract, and it is legal **only** beside a
deferring policy mode — `terminal_only` or `sampled` — because only those modes
issue riders. Anywhere else it is refused as
`solver.rider_timeout_pairing`.

```json
"certification": {
  "policy": { "mode": "terminal_only", "seed": 20260816 },
  "riderTimeout": {
    "deadlineSeconds": 5.0,
    "retries": 2,
    "onExhaustion": "fail_run"
  }
}
```

| Field | Domain | Required? | Meaning |
|---|---|---|---|
| `deadlineSeconds` | number > 0 | yes, no default | How long the master waits for one rider reply |
| `retries` | nonnegative integer | yes, no default | How many times the rider is re-issued after an expiry. `0` means the first deadline is also the last |
| `onExhaustion` | `fail_run` \| `degrade` | yes, no default | What happens once the deadline expired and every retry is spent. Only `fail_run` executes — see below |

All three are required with no defaults, on the same ground `mode` is: a
timeout contract the author did not state is a cost the author did not choose.

Two behaviours are worth knowing before you pick a deadline. The wait you get
is `min(deadlineSeconds, PF_SUBPROB_REPLY_TIMEOUT_SECONDS)`, rounded **up** to
whole seconds — that reply timeout, 600 seconds by default, is a deployment-wide
ceiling a document may lower and may not raise, and rounding up never
manufactures a timeout you did not ask for. And each re-issue goes out at a fresh exchange iteration, so every
attempt is a genuinely new exchange rather than a repeated wait.

`fail_run` ends the run with a named error in the results envelope, a nonzero
application exit, and the unsettled claim named. `degrade` is spellable and
refused, as `solver.rider_timeout_not_executed`; the refusal names what would
have to become true rather than naming a date.

!!! warning "The fail-loud rule"
    No option of `onExhaustion` may treat a timeout as a certification. Silence
    is not proof. This binds every value the field will ever carry.

Omitting the block entirely is the default and changes nothing: the master
waits one full reply deadline and, if nothing arrives, leaves the claim
unsettled.

## Step 4 — validate before you run

Both blocks are validated at submit, and the order is fixed: legality, then
domains, then capability. A document that is illegal is not a capability the
build is withholding, and reporting both at once would tell you a document will
work later when it will not.

Validate a definition without standing anything up — no participant is created
and no registry is contacted — using the Workbench's validate verb, which
delegates to the real binary on a dry-run path. See
[Workbench reference](../guide/workbench.md) for the verb surface and
[Workflow overview](../guide/workflow.md) for where validation sits in the
loop.

## Step 5 — run it, and read what comes back

All farm and certification output goes to the structured **stderr** log stream.
Not one byte of it goes to stdout, which is a harness-parsed path.

**The farm stamp**, one per block per round:

```
{ engine, K, K_effective, proposed, distinct, admitted,
  rejected_nonimproving, rejected_cost }
```

`K` is what the document asked for and `K_effective` is what was actually
exchanged for that block that round. `proposed` counts candidates received
including k = 1, `distinct` counts survivors of the deduplication, and
`admitted` counts the variables actually built. `rejected_nonimproving` is
benign — a perturbed view found a vertex the true view does not want.

**`rejected_cost` must be zero.** A nonzero value means a block's claimed cost
disagreed with the master's recomputation, which is a defect in transport,
indexing or engine arithmetic rather than a fact about your problem. All the
counts are emitted, rather than the two a reader usually wants, because
`proposed >= distinct >= admitted + rejected_*` holds by construction and a
stamp that violates it is a defect you want to see.

**The certification events**, one per decision: `certified_inline`,
`sampled_skip`, `terminal_skip`, `certified_at_terminal`, `audit_fail`, and a
single `terminal_settle`. Each carries `proof_debt`, the running count of
unsettled claims at the moment it was emitted, so the debt is legible at every
point in the log rather than only at the end.

**The settlement**, once, at the terminal interception — how many claims the
run saw, how many were certified inline, how many were skipped, how many
settled at the interception, how many audits failed, whether the run escalated,
and the residual debt, named.

**The failure record**, one line per rider expiry, on the timeout path only. It
is transport-neutral by contract — no transport noun appears in any value or in
the message text, and the lanes fail on one — and it never fabricates a
measurement: a block that has never answered produces "not seen" rather than an
age of zero, because a zero age would read as "just now".

## Step 6 — deploy

Nothing about speculative farming changes how a solution is deployed. A farmed
exchange and a certify rider are ordinary reduced-costs cycles: no new solver
state, no new transition, no change to the message definitions, and no new
field in the results envelope. Placement, the control plane and the deployment
planner behave exactly as they do without either block. See
[Services & control plane](../architecture/services.md).

## What the parameters actually gate

Calibration is out of scope, but the mechanics are not. Each of the four fields
gates one specific thing, the four things are independent, and none of them
gates the answer. What follows is read off the code rather than inferred.

**`columns`** is the farm size `K` the binding asks for: one true exchange at
k = 1 plus `K - 1` perturbed ones, with the document domain 2 to 16. It is an
upper bound on exchanges, not a count of them. The master runs a round's
perturbed exchanges as one loop from k = 2 to the largest `K` any farming block
declared, and a block whose own `K` is smaller drops out at the k that passes
it; a block that answered empty at k = 1 has already left the round's farm.
That is why the stamp reports `K_effective` beside `K`. `columns` reaches no
solver setting and no engine parameter — it is a count of exchanges.

**`perturbation.epsilon`** scales the reduced-cost vector that is *sent*, and
nothing else. For each perturbed exchange the master forms
`c'_i = c_i * (1 + epsilon * u_i)` coefficient by coefficient, with `u_i` drawn
in `[-1, 1)` from the stream seeded by the tuple (`perturbation.seed`,
subproblem id, round index, k); the scaling is applied to every model column
*before* the existing nonzero-publish filter, and the child solves that view.
The bound `0 < epsilon < 1` is arithmetic rather than taste: one scalar
multiplier applied to every coefficient would be a positive rescaling of a
linear objective, which does not move its minimiser over any feasible set, so
the perturbation is per coefficient or it is nothing — and at 1 a
coefficient's sign can flip, which is a different problem rather than a
neighbouring view of this one.

`epsilon` does not appear in the admission test. When a candidate comes back,
the master re-verifies it against the round's **true** dense vector, the
unperturbed one published at k = 1, so `epsilon` decides which vertices are
*proposed* and has no influence at all on which are *admitted*. The admission
inequality is DIP's own, and the master applies it byte-for-byte:

```
trueReducedCost = sum over the candidate's support of reducedCost[i] * value[i]
ADMIT iff trueReducedCost < threshold - tolerance
```

`threshold` is the block's convexity dual `alpha`, a property of the round and
the block; `tolerance` is DIP's `RedCostEpsilon`, which is the only engine
tolerance in the expression and is the same one DIP applies to a column no farm
ever touched. A larger tolerance tightens the test, a negative one loosens it.
The claim-mismatch test runs first when a child supplied a claimed cost, before
the improvement test, so a column whose claim disagrees with the recomputation
is rejected as `rejected_cost` whether or not it would have improved.

**`sampleRate`** gates one Bernoulli decision per unproven emptiness claim, per
block per round. Under `mode: sampled` the master certifies inline iff the draw
from the tuple (`policy.seed`, subproblem id, round index) is strictly less than
`sampleRate`; there is no k in that tuple, because the certification decision is
made once per block per round about the k = 1 reply, the only exchange that
carries an emptiness claim at all. It gates nothing else — not the farm, not
the admission test, not the terminal invariant. And it stops being consulted
entirely once a run has escalated after an audit failure: from that point every
claim is certified and no draw is taken, whatever the rate says.

**`deadlineSeconds`** gates one wait, downward only. The wait the master takes
for one rider reply is `min(deadlineSeconds, PF_SUBPROB_REPLY_TIMEOUT_SECONDS)`,
rounded up to whole seconds, with anything below one second becoming one second.
The reply timeout is a deployment-wide ceiling over every subproblem exchange,
so a document may ask to wait less than the deployment allows and may not ask to
wait more. The rounding goes up because the wait must never be shorter than the
document asked for: a deadline shortened by rounding would manufacture a timeout
the author did not request, which is the one direction a detector must not err
in. A document carrying no `riderTimeout` block gets the reply timeout
unchanged and unrounded.

## What this documentation does not cover

**Calibration is out of scope.** Choosing `columns`, `epsilon`, `sampleRate` or
`deadlineSeconds` for *your* model is not addressed here. Tuning guidance will
follow from measurements on a broader problem corpus; until those exist there
is nothing to offer but a heuristic invented for the occasion. The figures
above are measurements on one small hand-derived fixture and are not tuning
advice. What each parameter *gates* is mechanical, and is stated above.

Two further limits are worth stating plainly. There is **no way to ask for an
interior claim selectively**: a claim skipped at an interior round is settled
only if a later round happens to make it terminal, and no field asks for one
named claim to be settled where it was made. That is correct under the terminal
invariant. What a run whose interior claims matter can do is set the `always`
policy, which defers nothing and so settles every claim at the round it is
made — at full certification cost, which is the cost the deferring modes exist
to avoid. The missing thing is the choice between the two, not the settlement
itself.
And the price of matching the solver's own admission inequality is that some
farms admit only the column they already had — on `pfe006`, moving the gate to
the block's convexity dual took the run from three farm stamps to six and from
nine farmed exchanges to eighteen, of which nine buy nothing. The objective,
the round count and the counter identities are unchanged across that move.

**See also:** [Theory](theory.md) ·
[Proof debt & certification](theory/proof-debt.md) · [Testing](testing.md)
