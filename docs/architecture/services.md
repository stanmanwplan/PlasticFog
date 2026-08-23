# Services & control plane

<!-- dc:status=polished dc:owner=DC1 -->

This page describes the processes a running PlasticFog system consists of, what
each one owns, and the two separate control surfaces that drive them: the
command plane inside the constellation, and the conductor that sits in front of
it. [Application flow](app-flow.md) covers the path one problem takes through
these services.

## The constellation

Five executables make up a running system, and every one of them is an
ordinary process holding a DDS participant; the full configure described under
[Installation](../getting-started/installation.md) is what builds them.

**The registration service** is the directory. It assigns itself a
pre-allocated identifier that the other services already know, so that a
starting service can register by addressing a command to it. It answers two
kinds of request: a registration, sent by every RMP, subproblem and
overall-problem service as it starts, and a request from an application naming
the services it needs — which the registration service fulfils by returning the
matching identifiers.

Its store is a SQLite database of service records. A record carries an
identifier, a type, a user-facing name, a host and endpoint, an availability
flag, and an open-ended list of option key/value pairs; the service types it
distinguishes are the overall-problem, processing, registration, RMP and
subproblem roles. Alongside the original free-form query surface there is a
structured query form with its own machine-readable schema, which is what
external clients and tooling should validate against.

**The overall-problem service** is the fan-out point. It listens for the
problem graph addressed to it, processes it, derives the per-node Zimpl source
and configuration for each master and each subproblem, and publishes the
resulting modules — with their processed data files — to the services that will
host them. Those services turn what they receive into solver input.

**The RMP service** hosts a master. It holds the decomposition driver over
COIN-OR's DIP, publishes prices to its children, reads their proposals back,
and publishes the results envelope. On a resource-directed boundary it holds
the other half of the pair instead: it publishes an allocation and reads the
response.

**The subproblem service** hosts a child. It reads prices, solves against them,
and publishes its proposal; on a resource-directed boundary it reads an
allocation and answers with a response. It has its own event queue, because
what it does with an arriving request depends on what it is already doing.

**The application** is the client. It resolves placements, builds the graph,
publishes the overall problem, and collects results. It is the only one of the
five that is not resident: it runs for the length of a submission and exits.

A **mid** node does not add a sixth executable. It is one RMP service holding
both halves of a node that is a master downward and a subproblem upward, which
is why the runtime requires both halves to be placed on the same service.

## The topics

Services communicate over DDS topics, each keyed by recipient so that a
subscriber sees only what is addressed to it. The families are:

| Topic family | Carries |
|---|---|
| `PF_COMMANDS` | commands addressed to a service |
| `PF_SERVICE` | a service record — registration and directory traffic |
| `OVERALL_PROBLEM` | the problem graph, from the application to the overall-problem service |
| `RMP_MODULE`, `SUBPROB_MODULE` | a per-node module, from the overall-problem service to its host |
| `NODE_MODULE`, `NODES_MODULE`, `DATA_MODULE` | graph nodes and the data collections attached to them |
| `REDUCED_COSTS` | prices, master to child |
| `SUBPROB_SOLUTION` | a proposal, child to master |
| `RESOURCE_ALLOCATION`, `RESOURCE_RESPONSE` | the resource-directed pair, master to child and back |
| `OVERALL_RESULTS` | the results envelope |
| `PF_SERVICE_STATUS` | structured status records |

The modules are published individually rather than inside the graph. When the
overall problem is published, the modules attached to its graph are extracted
and replaced by stubs, so that a subscriber already holding a copy of a module
does not receive it again.

## The command plane

Commands addressed at a live constellation are `pf.problem_command.v1`
documents, delivered over `PF_COMMANDS` and answered over `PF_SERVICE_STATUS`.
Six verbs exist:

| Verb | Reaches | Meaning |
|---|---|---|
| `start` | a master | begin a run |
| `pause` | any node | stop responding or emitting at the round boundary; solve state is preserved |
| `resume` | any node | clear the pause |
| `stop` | any node | halt the active solve |
| `halt` | any node | stop the process |
| `request_results` | a master | emit the current envelope |

The document verbs are named for what an operator means. Underneath, the wire
constants are named for what the original machine does, and the two crossings —
"stop the solve" against "stop the service" — are deliberate rather than
accidental.

**Pause is a flag, not a state.** It does not add a solver state; it is a
boolean read at exactly one place per service, with the state machine untouched
underneath. What pause has to change is not what state a service is *in* but
whether it *answers*: for a subproblem, whether an arriving price request is
solved; for a master, whether another pricing round is started. Both are single
questions at single call sites, and adding a state would have cost the frozen
transition table its authority for no behavioural gain.

The two call sites are chosen carefully. A subproblem checks at the head of the
request, before anything is stored or dispatched, and answers with a status
record rather than falling silent — silence already means something on that
channel, namely a dead peer, and a paused subproblem that went quiet would burn
a full reply deadline and then be reported as a transport timeout, which is a
fabricated cause. It also declines to store the price snapshot while paused,
because storing it would leave a stale vector for a later resume to solve
against at an iteration the master has long since passed.

A master checks at the round boundary, immediately before the next round
begins, which is the only instant at which "the in-flight round has completed
and the next has not started" is true. It cannot live in the service's main
loop: for the duration of a solve that loop is inside the solver and drains
nothing, so a pause visible only there would take effect after the solve it was
meant to pause had finished.

A paused mid publishes both the master-side and the subproblem-side status
codes, because its parent prices it as a subproblem and would otherwise be left
waiting on a deadline.

**`start` against a mid is refused,** with a code of its own rather than a
generic role complaint. A mid's master half carries no application-attached
solve verb; its solve is event-driven, started by the parent pricing it. There
is nothing for `start` to start. Asking a mid for results remains legal, which
is a different question.

**Three verbs carry no acknowledgement.** Pause and resume report themselves on
the status channel and `request_results` answers with an envelope, but `start`,
`stop` and `halt` have carried no lifecycle report for years. For those three,
success means the command was published, not that it took effect — and the
runtime says so at the point it matters rather than leaving it to be inferred
from an exit code.

## What the status channel is, and is not

`PF_SERVICE_STATUS` is a report of **events**, and the header says so of itself:
records are emitted on failure paths, reliable and volatile, with no wait for a
matched subscriber. There is no startup record and no heartbeat on it.

That was measured rather than assumed, with a real registration service and a
real subproblem service coming up and an in-process reader listening through
the whole of their startup: zero status samples were observed during a healthy
start. Two design consequences follow directly, and both are visible elsewhere
in this documentation. Readiness is never established by reading this channel,
because a gate reading it could only ever time out. And silence is never read
as idleness — a service that is quietly solving publishes nothing, so treating
"no record" as evidence of quiescence would be most wrong exactly when the
system was busiest.

## The conductor

In front of the constellation sits `pf_Conductor`, a resident daemon, and `pf`,
a thin client that speaks JSON Lines to it over a Unix domain socket — the
command-line experience the [Workbench reference](../guide/workbench.md)
documents verb by verb. This is a
different surface from the command plane above and the two are not merged: the
command plane addresses services inside a running solve; the conductor API
addresses the catalog, deployments, runs and their artifacts.

`pf` holds no state of its own. Every question that needs the catalog or the
constellation to answer it is asked of the conductor. If no conductor is
running, `pf` starts one and connects to it; the conductor then detaches, so
the CLI process exiting does not take it down.

### What the conductor deliberately does not hold

**A DDS participant.** Every path through the submission flow ends with a
process-global, one-way OpenDDS shutdown, so a resident daemon that served one
submission in process could never serve a second. A probe measured the other
half of the reason: the discovery endpoint is pinned at the first factory call
for the life of the process, so a participant-holding daemon could not serve
per-deployment discovery at all. The conductor therefore starts the staged
application binary as a child process with its documented flags, and consumes
the results document it writes.

### Deployment

Deployment is split into a plan and a supervisor, and the split is the point.

`pf deploy plan` prints exactly what `pf deploy start` would execute and
performs no side effects: it starts no process, creates no directory, opens no
model file and touches no registry. An operator has to be able to read a
deployment before consenting to it, and a plan verb that consulted the registry
to decide could not be run twice with the same answer. A refused plan is
returned as an error carrying the plan, rather than as a success carrying an
error list a caller might not read.

The plan's action kinds come straight from the placement modes the document
already spells: an explicit placement becomes an attach, a query becomes a
discovery, a spawn becomes a spawn, and an automatic placement becomes whichever
arm wins. A fifth kind would be a concept the document cannot express.

`pf deploy start` hands the plan to a supervisor that starts and owns the
processes in dependency order — registration service, overall-problem service,
master, subproblems — and verifies each child's identity through `/proc` after
it is started. The governing invariant is that **the supervisor never signals a
process it did not start**: every signal goes to a process this supervisor
forked and which still passes an identity check read at the moment of the
signal.

Readiness is decided by three kinds, each of which this build can genuinely
observe:

| Kind | Decided by |
|---|---|
| process banner | the service's own startup banner in the log this deployment captured |
| registry registration | the cumulative registration count in the registration service's log |
| registry query | the registry's own answer, for discovered and attached bindings |

There is deliberately no status-channel kind, for the reason measured above.
Naming a readiness kind the build cannot observe would be the plan claiming a
capability it does not have.

Every action carries its own deadline, and a spawned process carries two: one
for the banner that says it started at all, and one for the fact that decides
readiness. The two failures need different next steps, so they are not merged
under one clock — and a deadline that fires always names its service, rather
than reporting a timeout whose cause arrives after nobody is listening.

### Runs, results and logs

Repeated execution is a separate decision engine: once, counted, continuous or
interval; overlapping runs either skipped or queued; stopping on consecutive
failures or a maximum run count; warm start carried when compatible or cold.
Its cadence grid is anchored at the campaign's origin, so a cadence cannot
drift by each run's duration.

The results plane and the log plane are both fed by what the runs themselves
produce. Results ingestion is document-granular — one row per envelope the
run's own results document carries, stored as the document carried it — so no
stream is simulated that the documents do not support. The log router fans in
the supervisor's captured streams with per-service labelling, a structured-only
level filter, optional terminal presentation, and a genuinely silent default.

## Updating a live constellation

A constellation that is already up can be updated in place: an update document
is applied against the topology snapshot a previous run wrote, and only what
actually changed is redistributed.

What an update may change depends on what is running *beneath the node it
targets*, not on whether the wider problem is running. Each rule walks the
target's own subtree and asks whether any node in it is solving or paused, so a
quiet sub-hierarchy accepts a change the same document could not make against a
busy one, and everything outside that subtree keeps solving throughout. Paused
counts as running for this purpose: a caller that wants an update blocked says
solving or paused.

The split is between structure and content. Changes to models, data and
execution policy are legal against a target that is solving or paused. Changes
to the decomposition structure — a boundary's paradigm or binding, a placement,
a solver engine — are refused against one, and the removal of a node with
solving or paused descendants is refused whether or not an interrupt is
authorised, because interrupting a solve still leaves the orphaned descendants
with no parent to report to.

`interrupt: always` waives the first three refusals rather than making them
harmless. The apply flow publishes a halt to the affected subtree's masters
before it publishes the update, so the waiver interrupts the solves it was
granted against. The manager holds no runtime gate of its own: it reports that
an update requires interrupting a solve and leaves the decision to the caller,
which is where the refusal is enforced.

The ordering is chosen so that a refusal is cheap. The snapshot is read and the
definition it embeds reloaded; the live run state is refreshed; the update is
validated against that state; the update is applied, committed and rebuilt, and
put through the compatibility gate; and only then is anything published. The
first four steps create a subscription and no writer, so an update that is going
to be refused costs the running system one subscription and no traffic.

Run state is *observed* rather than read out of the snapshot, and both readings
are printed side by side. The snapshot's values are what was true at the moment
it was written; the rules that decide whether an update is safe all turn on
whether a subtree currently holds a solving or paused node, and answering that
from a file is answering it about a photograph. Nodes nothing was heard from
keep the file's state rather than being demoted to unknown, for the same reason
silence is not idleness.

"Only what changed" is decided by comparison rather than by prediction. The
republish set is every module of every directly affected node, plus every
ancestor master whose *generated* content actually differs — a master compiles
its children's sources and data into its own campaign, so editing one leaf's
model changes what its parent compiles and republishes the parent too. The walk
goes up one boundary at a time and stops at the first ancestor whose generated
text is byte-identical, which is why an update deep in a hierarchy commonly
spares the root.

**Pausing, updating and resuming a sub-hierarchy composes.** A paused leaf is
not excluded from an update: adoption is gated on whether its solver is
genuinely mid-solve rather than on the pause flag, and the flag is written only
by the pause and resume commands, so it survives the re-setup that adopting a
new revision performs. The leaf takes the new definition while paused and runs
it when resumed; a leaf caught mid-solve holds the module and adopts it at the
next safe point instead. Whether the parent's solve survives the pause at all is
the failure policy's decision rather than the update's. End-to-end testing of
this composed sequence is still underway in this pre-release — the mid-run
update and the control commands are each exercised by their own lane, but no
lane yet runs all three against one constellation.

## The transport seam

To be plain about what runs today: **OpenDDS is the transport.** The five
service executables use the OpenDDS and ACE interfaces directly, and the
generated types they exchange come from the project's own IDL.

The repository also carries a transport abstraction layer — a named interface
for a publisher, a subscriber and a transport, with capability queries, channel
and message validation, and a discovery wait, alongside adapter skeletons for
other DDS vendors. It is a design skeleton: none of it is part of the service
build, and no shipped behaviour goes through it. Treat it as roadmap work, and
see [Upcoming features](../roadmap/index.md).
