# Application flow

<!-- dc:status=polished dc:owner=DC1 -->

This page follows one problem from the document you author to the results you
read back: validation, placement, graph construction, distribution, the
distributed solve, and the results plane. It describes what the runtime does,
not how to drive it — [Your first problem](../getting-started/first-problem.md)
is the user-facing walkthrough.

## The shape of a run

A run has six stages, and each one can refuse.

1. **Definition.** You write a `pf.problem_definition.v1` document.
2. **Validation.** The document is checked against the schema and the
   structural rules, and optionally compiled.
3. **Placement.** The document's placement queries are resolved against the
   live registry.
4. **Graph build.** The resolved snapshot is projected into the runtime's
   internal graph, and anything this runtime cannot execute is refused here.
5. **Distribution.** The graph is published; the overall-problem service turns
   it into per-node models and data and hands each one to its service.
6. **Solve and results.** The constellation runs the decomposition; results
   come back as an envelope.

The ordering matters more than it looks. Every check that can be made without
touching the transport is made before a DDS participant exists, so a document
that is going to be rejected is rejected without disturbing a running
constellation.

## Definition and identity

The document carries its own identity: a problem id, a version, a revision, and
a content hash over the canonical form. The runtime mints a correlation id for
each submission by combining them —

```
<problemId>@r<revision>.<contentHash[0..11]>-<appServiceId>.<sequence>
```

— so that the leading component is deterministic and greppable across runs
while the trailing components supply cross-process and in-process uniqueness.
Every log line and every artifact a run produces can be traced back to the
exact revision of the exact document that caused it.

## Validation

Validation is two gates in a fixed order. The first checks the document against
the machine-readable schema and against the structural rules the schema cannot
express — that the topology is one connected rooted tree, that levels and roles
agree, that each coupling declaration is owned by a node on its own boundary,
that each engine is legal for the role it sits at, that the constraint markers
in each model are paired and ordered. This gate never runs the Zimpl compiler.

The second gate does. It stages every compile unit the runtime would build,
compiles each in process, and then inspects the compiled artifacts for the
authoring conventions the compiler itself cannot see. It stops short of
solving: it contacts no registry and starts no service.

Both gates run in the application binary itself, on a path that creates no DDS
participant. That is deliberate. The authority for "will this document run" is
the real binary on a dry run, not a status recorded when the document was first
filed away.

## Placement

The document does not name machines. Each service in the topology carries a
**placement**, which is either an explicit list of service ids or a query — a
service type, a count, required capabilities, and whether to consider only
available services.

At submit, those placements are translated onto the registry's request protocol
and resolved over DDS. The submission waits on a synchronisation gate for the
registry's answers, and the wait is bounded. Two failures that look alike from
outside are kept apart here: a placement that could not be translated into a
well-formed query at all is one outcome, and a well-formed query for services
that simply are not present is another. They need different responses from an
operator, so they get different exit codes.

## Graph build

The committed placement snapshot is projected into the runtime's graph — the
object model of modules and the edges between them. This is where the
document's abstract nodes become concrete: an RMP module bound to a service
host and to its Zimpl source and data collections, one subproblem module per
child bound to its own host, source and data.

Two things happen at this stage that are worth calling out.

**Verbs are attached by role.** A master module receives the setup and solve
verbs; a subproblem module receives setup only. That asymmetry is the
Dantzig–Wolfe contract, not an oversight: a subproblem that solved on arrival
would be solving with no reduced-cost vector to solve against, would park in
its running state, and would then reject the genuine prices when they arrived.
The overall problem itself receives no verbs, and the builder creates no module
for it — it is an identifier, not a participant.

**Anything unexecutable is refused before publication.** The build compares
what the document asks for against what this runtime can actually do, and a
shape it cannot execute is refused with a named code pointing at the offending
part of the document. Refusing is the only answer that cannot silently solve
something other than what was written.

## Distribution

The application publishes the overall problem, carrying the graph, to the
overall-problem service. That service is the fan-out point. It processes the
graph, derives the per-node Zimpl source and configuration for each master and
each subproblem — the master's coupling rows are stripped out of the source the
children receive — and publishes each resulting module to the service that will
host it.

Distribution is hierarchy-aware rather than flat. Before publishing anything,
the service recovers the tree from edges already in the graph and from the
attributes the builder stamped on it, resolving every master's hosting service
once, up front. With more than one master in the graph, a child's report-to
relationship cannot be inferred from whichever master happened to be published
last, so it is not inferred at all. A child that names a master absent from the
graph aborts the submission rather than being quietly re-parented.

The data a node receives is narrowed on the way out. A data collection declared
as per-service-id is cut down to the recipient's own id before it is published
to that recipient.

## Solve

With models and data staged, the solve verb starts the loop. The master prices;
the subproblems solve in response to prices and answer with proposals; the
master reprices. Whether a given boundary is price-directed or
resource-directed is a property of that boundary rather than of the run, and
[Decomposition paradigms](decomposition.md) describes both and how they nest.

A **mid** node — one that is a master to its children and a subproblem to its
parent at the same time — executes as a single service holding both halves. The
runtime requires the two halves to be placed on the same service and refuses a
topology that splits them, because the two halves share one object, the inner
model: the master half prices over it and the subproblem half reports on it.
Split across two processes there is no single inner model for either sentence to
be about.

Status flows back continuously on the service-status plane, which is also how
the run is paused, resumed and stopped. [Services & control
plane](services.md) covers that side.

## Results

Results return as an envelope carrying, per node, which engine solved it, how
that engine terminated, and what it proved. The `execution.results` block of
the document decides which node's answer is returned, where it is written, how
long the submission waits, whether variables are filtered, and whether interim
progress is reported.

Alongside the results the submission writes a **topology snapshot** — the
resolved placements and the problem document as submitted. It is written on a
timeout as well as on a completed run, because a constellation that did not
answer is exactly the one an operator then wants to address a command to, and
a stale snapshot would leave them pointing at pre-solve state.

The exit status distinguishes outcomes that a script needs to branch on:

| Code | Meaning |
|---:|---|
| 0 | optimal or feasible |
| 2 | infeasible or unbounded |
| 3 | timed out waiting for results |
| 4 | definition invalid, unsupported by this runtime, or bad usage |
| 5 | placement unresolvable |
| 6 | transport or publish error |
| 7 | solver-reported error |
| 8 | required services are not available |
| 9 | a service reported a structured failure that ended the solve |

Codes 8 and 9 exist because their absence was a real diagnostic loss. A
constellation missing a subproblem service and a constellation whose subproblem
service died mid-solve both used to arrive as "timed out" — true of the symptom,
useless as a diagnosis, and calling for completely different operator responses.

## Where the flow runs

The submission flow lives in the application binary, `pf_App`. The resident
daemon does not call it in process; it starts `pf_App` as a child process with
the documented flags and consumes the results document that comes back.

That is a considered choice with one decisive reason. Every path through the
submission flow ends by shutting down OpenDDS's process-global service
singleton, and that shutdown is one-way. A resident daemon that served one
submission in process could not serve a second: the first would take the whole
process's DDS service down with it, and every later request would fail in a way
that looked like a transport fault rather than the design error it was. A
second reason points the same way — the discovery endpoint is pinned at the
first factory call for the life of the process, so a participant-holding daemon
could not serve per-deployment discovery at all.

The consequence is visible and intended: the daemon holds no DDS participant of
its own. It holds the domain and discovery port as configuration and passes
them to each child. A participant created in the daemon would join the
constellation's discovery for the daemon's whole lifetime and be used for
nothing, which is a claim rather than a capability.

## Two other entry points

The same binary carries two variants of the flow.

**Control-plane invocation.** Given a command document and the topology
snapshot a previous run wrote, the application re-parses the problem document
embedded in that snapshot — no filesystem access, since the referenced models
and data belong to the submitting run's source root — validates the command
against that definition, expands it to its targets, resolves node ids to service
ids through the snapshot's placements, and publishes one recipient-keyed command
per target. It then collects acknowledgements until the wait expires. The
submission exit codes are reused rather than given a second vocabulary, so a
script branching on the exit status does not have to know which mode produced
it. Three verbs — start, stop and halt — have carried no lifecycle report for
years, and for those, success means the command was published, not that it took
effect. The runtime says so at the point it matters rather than leaving the
reader to infer it from an exit code.

**Update against a live constellation.** A definition can be revised and
redistributed to a constellation that is already up, producing a new revision
of the document as an artifact of the update. What the revision may change is
decided against the node it targets — against what is solving or paused beneath
that node rather than against the state of the wider run — and only the modules
whose generated content actually changed are republished. [Services & control
plane](services.md) covers those rules and the walk-up that decides the set.

**The original demo path.** Invoked with no document argument, the application
runs a hardcoded demonstration graph that predates the generalized path. It is
still the clearest end-to-end read of the runtime, and the generalized path was
written to match what it actually sends rather than what it was assumed to
send.
