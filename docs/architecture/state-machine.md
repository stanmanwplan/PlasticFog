# State machine

<!-- dc:status=polished dc:owner=DC1 -->

This page describes the formal solver state machine: the two machines, the
states and triggers they are defined over, how a dispatch is resolved, and how
the resource-directed loop shares the price-directed states. The two paradigms
themselves are described under
[Decomposition paradigms](decomposition.md). It is the current
description of the machine and supersedes earlier published accounts of
PlasticFog's solver states.

## Two machines over one state set

There are two machines — one for a master and one for a subproblem — and they
share a single state enumeration:

| State | What it means |
|---|---|
| `st_NONE` | no problem is currently being solved |
| `st_READY` | a problem is prepared and ready to solve; zero iterations have started |
| `st_RUNNING_SOLVER` | a solver is running; zero or more iterations have started |
| `st_SENDING_PRICES` | the master is publishing downward what it generated |
| `st_WAITING_COSTS` | the master is waiting for its children to answer |
| `st_SENDING_COSTS` | the child is publishing its answer upward |
| `st_WAITING_PRICES` | the child is parked between rounds |
| `st_COMPLETED` | the solve finished and results are available |

Four of those identifiers are frozen legacy names whose wording predates the
vocabulary the project now uses, so the machine carries both spellings and can
translate between them:

| Frozen identifier | Corrected name |
|---|---|
| `st_SENDING_PRICES` | `st_SENDING_REDUCED_COSTS` |
| `st_WAITING_COSTS` | `st_WAITING_SUBPROB_SOLUTION` |
| `st_SENDING_COSTS` | `st_SENDING_SUBPROB_SOLUTION` |
| `st_WAITING_PRICES` | `st_WAITING_REDUCED_COSTS` |

`stateName()` returns the corrected spelling, `legacyStateName()` the frozen
one, and `stateFromName()` accepts either. The other four states carry one name
each.

The distinction the corrected names restore is a real one. What a master sends
down is a **reduced-cost vector**. What a child sends back is a **subproblem
solution** — a column proposal, not a cost vector. And a child waiting between
rounds is waiting for the next reduced-cost vector from its master; a
subproblem never waits on another subproblem.

The machine names carried in structured errors are
`pf_RmpSolverStateMachine` and `pf_SubprobSolverStateMachine`.

## The transition table

The table is a fixture: a CSV of 76 rows — 41 for the master machine and 35 for
the subproblem machine — carrying, per row, the machine, the from-state, the
trigger, an optional guard, an action name, and a to-state. The machine's
in-code table is transcribed from that fixture in fixture order, so that a diff
of one against the other reads line by line. Rows whose trigger cell names a
group of commands expand to one table entry per command.

Triggers are of two kinds. **Commands** (`cmd_SETUP`, `cmd_SOLVE`, `cmd_HALT`,
`cmd_UPDATE`, `cmd_RESULTS`, and the asynchronous group `cmd_ADD`,
`cmd_REMOVE`, `cmd_LOAD`, `cmd_SAVE`, `cmd_ALERT`, `cmd_MESSAGE`) arrive from
outside. **Runtime events** (`ev_generated_reduced_costs`,
`ev_reduced_costs_published_ok`, `ev_all_subprob_solutions_received`,
`ev_subprob_solution_timeout`, `ev_solver_failure`, and their subproblem-side
counterparts) are raised inside the [service](services.md).

### Outcomes

A dispatch returns one of five outcomes:

| Outcome | When | Effect |
|---|---|---|
| `Applied` | an ordinary row fired | run the action, then adopt the to-state |
| `NoOp` | the row's action is the explicit no-op | nothing happens, by design |
| `Deferred` | the row's action queues the command | queue a copy with a release tag; the state is unchanged |
| `PolicyDependent` | the row's to-state is decided by policy | the owner resolves the destination |
| `Rejected` | no legal transition | the state is unchanged and a structured error is emitted |

Deferred commands wait on one of three release tags —
`until_completed_or_none`, `until_waiting_costs`, `until_waiting_prices` — which
come from the action names in the fixture rather than from a second vocabulary.

**Rejection distinguishes two cases,** and the distinction is what keeps two
different error codes meaningful. A trigger that appears nowhere in this
machine's table at all is an unsupported operation. A trigger that appears in
the table but not out of the current state is a rejected command, and the error
carries the machine, the state and the trigger by name.

### Guards

A row with an empty guard always fires. A row with a boolean guard consults a
resolver supplied by the owning service; if the guard is false, the state does
not change and the dispatch is rejected — except for the alert rows, where the
fixture prescribes the else-branch explicitly, and a non-high-priority alert is
queued rather than rejected.

One guard is not boolean: the reply-timeout rows carry a policy guard, which is
recognised by its form, never passed to the boolean resolver, and produces a
policy-dependent outcome with the state unchanged until the owner resolves it.

## The price-directed loop

Read as a walk, the master's cycle is: from `st_NONE`, a setup or select
command prepares the problem and moves to `st_READY`. A solve command begins the
decomposition solve and moves to `st_RUNNING_SOLVER`. From there the solver
either generates a reduced-cost vector — publishing it and moving to
`st_SENDING_PRICES` — or generates terminal decisions and moves to
`st_COMPLETED`. A successful publish arms the wait and moves to
`st_WAITING_COSTS`; when the awaited subproblem solution arrives, the master
resumes its iteration back in `st_RUNNING_SOLVER`. A reply that never comes
raises the timeout, and the destination is chosen by the failure policy.

The child's cycle mirrors it: setup to `st_READY`; an arriving reduced-cost
vector begins a solve and moves to `st_RUNNING_SOLVER`; a ready solution is
packaged and moves to `st_SENDING_COSTS`; a successful publish moves to
`st_WAITING_PRICES`, where the child rests between rounds; the next
reduced-cost vector starts the cycle again. Note where a leaf waits — a child
between rounds sits in `st_WAITING_PRICES`, not back in `st_READY`.

From every non-idle state, a halt command returns the machine to `st_NONE`, a
results command returns the most recent results, and the asynchronous command
group is either handled without a state change or queued under the deferral
rule.

## The resource-directed rows

The resource-directed loop has the same shape as the price-directed one — the
master generates an allocation instead of a reduced-cost vector, publishes it,
and waits; each child answers with a formal cut instead of a column proposal; a
child that does not answer hits the same reply timeout and the same policy hook.

Ten rows were appended to the fixture for it, and **no existing row changed**.
Crucially, the rows reuse the existing states rather than adding new ones. The
states are named for their price-side use but *defined* by their structural
position — "the master is publishing downward", "the master is waiting on its
children" — and both descriptions are exactly true of the resource loop. Adding
a second pair of states would encode the same two positions twice, and would
then need every halt, alert, update and deferral row mirrored onto them:
roughly twenty more rows carrying no new behaviour, each one an opportunity to
differ from the row it was copied from.

Because a transition is keyed on machine, from-state and trigger, reusing
states makes one property load-bearing: no appended row may name a trigger that
already has a row out of that state on that machine. Every one of the ten
triggers is new — `ev_generated_allocation`, `ev_allocation_published`,
`ev_allocation_published_failed`, `ev_resource_responses_received`,
`ev_resource_response_timeout` on the master side, and
`ev_allocation_received`, `ev_cut_ready`, `ev_cut_published`,
`ev_cut_published_failed` on the child side — so no existing row's meaning
changed, and a dispatch that used to match a row still matches exactly that row.

The reply-timeout rows on both sides share one action deliberately: one policy
hook, one resolution path. That substitution is not a legal response for a
resource child — there is no honest local surrogate for a cut — is enforced in
the failure policy and at validation, not as a second table row.

## Threading and ownership

The machine is standalone by construction. It depends on the state and command
enumerations, the runtime-event enumeration and the standard library, and knows
nothing about DDS, about DIP or SYMPHONY, or about either solver manager.
Everything service-specific arrives through two callbacks supplied at
construction: a guard resolver and an action sink.

**The action sink is a trace sink, not the action.** It is invoked from inside
the dispatch, which the owner calls with its machine mutex held, so it must not
do work. Each manager runs the real action body from the returned action name
*after* the dispatch returns and the lock is released. This is not a stylistic
preference: the master's begin-solve action calls into the decomposition solver,
which blocks until a subproblem has replied, and those replies arrive on a
receive thread that needs the same mutex to raise its event. Running the action
under the lock deadlocks the solve.

The current state is atomic, but a dispatch is a read-modify-write across the
table plus a guard call plus an action call, so concurrent dispatches are
serialised by the owner. Both managers hold a mutex for exactly the duration of
a dispatch, and never across a publish or a solver call.

Authoritative state storage stays on the module rather than on the manager. The
machine holds its own atomic state and is the only writer; each manager mirrors
the post-transition state into the module field immediately after a transition
is applied, so existing readers keep working.

### One real race, handled explicitly

The master publishes the reduced-cost vector and only *then* dispatches the
event that moves it from sending to waiting. A reply can in principle be
accepted by the receive thread in the window between the publish returning and
that dispatch — a legal-looking event arriving one instruction early, which the
table would reject.

The resolution is a flag rather than a hope that the network is slow. The
accept path takes the machine mutex; if the machine is still in the sending
state it records a pending arrival and returns without dispatching. The
publish-succeeded dispatch, under the same mutex, checks that flag and
immediately dispatches the deferred arrival. The mutex is never held across a
publish, so transport threads cannot be blocked by it.

### The subproblem event loop

On the subproblem side the listeners are thin: each parses its sample,
snapshots it, enqueues it and returns. A queue owned by the service main thread
— a mutex, a condition variable and a deque of small tagged events for an
arriving module, an arriving reduced-cost vector, and a stop request — is the
wakeup. The solve and the reply publish run on the service main thread, not
inside a DDS callback. The wait is bounded so the loop re-checks its stop flag
even when idle.

One ordering property is deliberate: an arriving reduced-cost vector is
enqueued only after the staleness check, so a stale vector never reaches the
event loop and never costs a solve.

## Where the table and the running system differ

Three places are worth knowing about, because the table is a transcription of
the original design and the running system is not obliged to have matched it.

**"All subproblem solutions" is one solution.** The row that resumes a master
iteration is named for a fan-in barrier. The running system has no such
barrier: the master's relaxed solve is called once per block, arms one expected
reply, and blocks until that single reply arrives. The behaviour implemented is
the proven one — the event fires when *the* awaited reply is accepted — and the
plural row name is kept because it is the canonical name.

**An update command from an unprepared state is now rejected.** The legacy code
accepted it from any state and set the ready state unconditionally. Under the
table it is legal only from the states that spell it, which is a deliberate
tightening.

**A failed publish of a reduced-cost vector ends the solve.** The table sends
that event to the idle state, in keeping with the rule that error paths reset
to idle. The earlier behaviour was narrower: a failed write degraded one block,
which the decomposition solver then priced locally, and the solve carried on.
The change in blast radius is real and is stated here rather than discovered.

That last one has a cautionary history attached, which is the clearest argument
on this page for having a formal machine at all. A publisher in the tree was
passing an uninitialised instance handle to the writer, so whether a write
succeeded depended on what the stack happened to hold. Adding one call ahead of
the publish changed the frame layout, and every reduced-cost write began
failing. The visible symptom was almost nothing: the scenario still reported an
optimal status and still reported the right objective, because the
decomposition solver silently priced every block locally instead. The only tell
was that the subproblem services never published. The defect was latent, not
new — but it stayed invisible for as long as no component was keeping an
explicit account of what should have happened.
