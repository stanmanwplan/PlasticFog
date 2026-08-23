# Upcoming features

<!-- dc:status=polished dc:owner=DC1 -->

This page lists work that is planned, designed or partly prepared but **not
built**. Nothing on it describes current behaviour. Two items are given at
length because they are the largest structural changes ahead; the rest is a
consolidated ledger of what the project has explicitly deferred and why.

## Parallel branch-and-price over the ALPS search tree

Today a pricing round is a coordinator that walks its blocks. The pre-hook on
DIP's pricing loop already lets one round's blocks be priced together rather
than one after another, so the remote solves overlap. What it does not do is
parallelise the *search*: one branch-and-price tree is explored at a time.

The intended next step is parallel branch-and-price over the ALPS search tree,
so that several tree nodes are active at once and each carries its own pricing
traffic. That means every pricing request and every reply has to say which
search node it belongs to, because a reply that cannot be attributed to a node
is a reply that cannot be used.

One piece of preparation is already in place, and it is the only part of this
item that exists. Both pricing structures on the wire carry a reserved
search-node field. The contract around it is deliberately trivial while it is
unused: producers write zero, replies echo the request's value, and validation
is log-only — an echo mismatch emits a structured warning and the reply is
still accepted. The field was added at the one moment the wire was already
changing for other reasons, on the reasoning that adding it later would cost a
second break. It is provably constant today and buys the option cheaply.

### In-memory integration, and the precedent for it

The second half of this item is to stop going through the filesystem where a
process boundary is no longer needed. The precedent is the Zimpl work, and it
is worth stating plainly because it is the shape the ALPS work would follow.

Model compilation used to run the Zimpl command-line binary as a child process
against staged files. It now runs in process, against the Zimpl library, and
the compiled artifacts are held in a cache that performs **no filesystem write
during a solve** — no periodic flush, no write-behind, no write-on-eviction, no
write-on-shutdown, no spill file. Persistence exists but is explicit and
opt-in, and its snapshot writer renames the manifest last so a reader sees
either the old snapshot or the new one and never a mixture.

The step that was deliberately *not* taken is the one that names the pattern.
Zimpl exports a public hook for registering input files in memory, and its
semantics have been surveyed and pinned: register before the compile, repeat
per compile, match the model's own spelling of each name exactly, and register
an include under its resolved name. It is the better design — no staging, no
cleanup obligation, no temporary-filesystem assumption — and it was still left
out, because staging real files kept everything except the process boundary
identical while byte-for-byte parity against the command-line compiler was
being established. A parity failure then has one candidate cause instead of
two. Adopting the in-memory seam is a small, independently verifiable step
against goldens that are already trusted.

That is the discipline the ALPS work inherits: prove the new path against the
old one first, on unchanged inputs, and move the boundary afterwards.

## Transport abstraction and multi-vendor DDS

The runtime speaks OpenDDS directly today. The repository also carries a
transport abstraction layer: logical channels distinct from transport-native
topic names, a transport message envelope, a transport-agnostic quality-of-service
model, a transport interface and a manager over it, with adapter skeletons for
Cyclone DDS and Fast DDS beside the OpenDDS one, plus a null adapter and an
in-process loopback bus for tests.

**None of it is in the service build, and no shipped behaviour goes through
it.** It is a design skeleton with a design addendum behind it, and the
addendum's own stated posture is incremental and two-plane: keep the legacy
solver plane on OpenDDS while new integration traffic moves onto the abstracted
plane. Cyclone DDS is named there as the preferred future backend, with Fast
DDS supported either as a second backend or through a bridge.

Beyond DDS, the addendum sketches non-DDS integration targets and partner edge
clients. Those are strategy rather than schedule, and the specifics in the
design material are older than the current implementation, so this page
describes the direction and not the particulars.

There is a concrete near-term test of whether the abstraction is real. One
subsystem's evidence seam is transport-neutral by contract and asserted to be
so, but its only implementation reads endpoint presence directly. Migrating it
is what would show whether the neutrality holds.

## The consolidated ledger

The remaining items are grouped by the area they belong to. Each is named as
owed, deferred or unbuilt.

### Engines

The engine seam dispatches per binding, and the near-term work is mostly about
making its refusals derivable rather than restated.

- **Measure the NVIDIA cuOpt dual orientation** against the hand-computed instance the
  cut algebra is checked against, as was done for HiGHS. Until that exists, one
  row-negation rule stays a labelled hypothesis at three sites.
- **Capability-driven refusal, generally.** This has been done once, for dual
  rays. Several of cuOpt's refusals are derivable from its declared capabilities
  rather than restated by name.
- **A capability/implementation agreement test**, asserting that every
  registered engine's declared LP and MIP support agrees with whether the
  corresponding operation is actually overridden.
- **Reaching DIP's own choice of integer solver.** DIP selects it internally and
  a binding's engine setting cannot reach it, which is why a price master
  accepts only the DIP engine. Reaching it would make the price master a
  dispatch site like the other roles — and the larger version of the same idea
  is a native column-generation master, which would make a price master an
  engine question rather than a coordinator question at all.
- **A routing adapter.** cuOpt's routing solver is a different problem class
  with a different interface, and there is no seam site for it today.
- **Dual rays from more engines.** Each additional ray-capable engine widens
  what a resource child may bind to without a fallback, and each one needs its
  own measurement against the cut convention.
- **A remote mode.** The cuOpt adapter is in-process only.
- **Multi-GPU.** The current probe answers "is there a device", not how many and
  not which — so this is a placement question as much as an engine one.
- **Warm start.** No engine in the registry honours a warm start today.
  Honouring one means holding solver state across rounds and giving up the
  fresh-instance rule, which is a design decision rather than a setting.

### Workbench

Highest first: **per-run correlation identifiers**; **a background campaign**,
which unblocks status of a campaign in flight, overlap against a genuinely
running run, and live streaming at once; **a live event writer**; **a second
staged master directory**, without which a nested topology cannot be spawned;
**restart policies**; **retention**; and a terminal interface over the same
verb set.

A resolve-only mode of the application is also owed. There is no non-perturbing
registry probe short of a submission today, which is why a discovery or attach
action checks reachability on its own clock and lets the submission's own
registry query confirm per-service registration — and why the status row says
which of the two it is rather than claiming a check that was not made.

### Composition

- **Multi-cut Benders**, one epigraph per child. Aggregation is correct but
  converges more slowly at wide fan-out; the blocker is a schema decision about
  how per-child epigraphs are named and declared.
- **Recourse-cost promotion.** Nothing chooses the weight at which a mid's
  recourse cost enters a column its parent is already paying for at its own
  prices, and the field does not exist. It is a prerequisite for the next item.
- **Resource-over-price composition** — the mirror of the mixed shape that
  executes today. The cut a mid would return has to be certified against the
  true inner subproblem, not against a restricted master that merely ran out of
  columns.
- **Nested-resource trees.** Nothing relays an allocation through an
  intermediate resource node.
- **Benders cut-pool warm start at a mid.** A feasibility cut is
  objective-independent and could survive a pricing event, but only while the
  recourse models are unchanged, and nothing tracks that.
- **Control-plane parity across paradigms.** Pause has never been published at a
  live resource master, and the control-plane and spot-update lanes are
  price-only.
- **A vocabulary rename window.** The transition table is frozen, and several
  row and action names still read as price-only even though they now serve
  resource rounds too.
- **Reporting an infeasible inner problem upward.** A mid cannot currently say
  "I cannot deliver that" to its parent. This is the mechanism behind two of the
  known limits on [Decomposition paradigms](../architecture/decomposition.md),
  and fixing it retires both.

### Speculative farming

The farming work carries its own ledger of sharpened questions. Among them:
**asynchronous mid-round admission**, where a column that arrives while the
master is still gathering is admitted the moment it lands — out of scope for now
because it changes the master's wait discipline, which the existing
batch-pricing override depends on; **GPU-batched candidate solves**, collapsing
a round's candidates into one device call, which needs **child-side
multi-column replies** first, and those need a wire change because a reply
carries one column today; **feasibility leases**, so a child that has proved its
block infeasible under an allocation need not re-prove it; **disturbance
cones**, a principled replacement for a scalar perturbation parameter; and
**elastic decomposition**, varying the block partition itself as a run proceeds,
which changes the graph rather than the pricing.

Two smaller ones are worth naming because they bound what the current build
reports: no results-envelope field carries a farming stamp or a debt ledger
today — those travel as log events, and promoting one to a document field is a
contract change — and a claim skipped at an interior round is settled only if a
later round happens to make it terminal, so a run where interior claims matter
has no way to ask for them selectively.

### Reliability and observability

- **Enhanced fault handling.** A failure policy resolves a missing child by
  name today, and a certify rider that never answers fails the run loudly with
  the unsettled claim named. What is owed is the layer above those two: faults
  classified by kind rather than handled at the site that meets them, recovery
  attempted before a run is abandoned where the kind allows it, and one policy
  surface over the whole constellation rather than one parent's view of one
  child.
- **A liveliness lease** on the master's rider writer, deferred with its risk
  recorded: the relevant quality-of-service setting is a matched pair, so an
  incompatible one does not degrade — it fails to match, which would turn an
  observability improvement into a silently unpriced change reaching every
  endpoint in a deployment.
- **A mid-level lane** exercising a rider across both faces of a node that is a
  child and a master at once.
- **A blindness sweep** over values that are recorded but deliberately not
  asserted, deciding per value whether an assertion exists that would catch a
  regression in it.
- **Coverage instruments**, handed on as a group: a differential model
  generator, a latency metamorphic suite, and error-surface enumeration.

### Security

The build has no security layer. Nothing authenticates a caller, nothing
encrypts a payload, and nothing constrains what one registered service may ask
of another. The whole of it is unbuilt, and it is named here as one item rather
than several because the intended shape is a seam, not a mechanism.

- **Security plugins.** Authentication, authorisation and transport-level
  protection supplied at a declared plug-in seam rather than compiled into the
  services, so a deployment presents the scheme its own site already operates
  instead of adopting one chosen here. Unbuilt: there is no seam today, no
  default plug-in, and no refusal that names either.

### Integration and plug-in seams

The transport abstraction above is one instance of a wider intent, and the
engine seam is another: that the runtime's outward edges become declared
abstraction layers a deployment fills, rather than choices fixed in the service
build. The items below are direction. None of them has a seam in the tree.

- **Industrial connectivity.** Abstraction layers by which a constellation
  exchanges data with the equipment, controllers and historians of a plant
  rather than only with its own services. Unbuilt; no adapter of this kind
  exists.
- **Additional mathematical solvers**, arriving as plug-ins. The engine seam
  itself is real and dispatches per binding — the [Engines](#engines) items
  above are its ledger — but every engine the registry answers to is named in
  the build rather than discovered at run time, so a solver arriving as a
  plug-in has nowhere to register itself.
- **Additional AI models**, reached at a seam of the same kind: a declared point
  at which a model is called while a problem is being prepared or solved.
  Nothing in the repository calls a language model today, so this is a seam that
  would have to be designed rather than one that would have to be opened.
- **Additional networking transport standards**, beyond the multi-vendor DDS
  work described above. The transport abstraction layer is where a non-DDS
  standard would attach, which makes adopting that layer the prerequisite rather
  than a parallel effort.
