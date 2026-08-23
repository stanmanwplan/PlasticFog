# Results

<!-- dc:status=polished dc:owner=DC4a -->

A solve returns a `pf.results_envelope.v1` object: the outcome, the solution, and
an account of how the answer was produced. This page documents the envelope's
declared shape in `pf_Results_Types.h` and the collector and publisher in
`pf_Results_Gateway.h` that move it between a running constellation and a caller.

The envelope has no `.schema.json` file. It is declared in C++, and this header
is the contract.

## One rule to read the envelope by

**Absent means "not observed", never "clean".**

The header repeats that sentence beside the fields most likely to be misread as
a clean bill of health, and states the consequence: "A reader that treats a
missing entry as 'that node was fine' has invented evidence." The two cases an
empty array cannot distinguish are "the node ran cleanly and had nothing to
relay" and "the node never came up". Only the presence of an entry is
information.

## The envelope

`pf_ResultsEnvelope` is serialized into the payload field the runtime publishes.
Its header notes one property a caller depends on: "Parsing never throws: this
type is decoded inside a DDS listener callback, where an exception would cross a
callback boundary. Every failure comes back as a `pf_Status`." That is the
shared return convention of every surface here; see
[Errors and status](index.md#errors-and-status).

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `correlationId` | `std::string correlationId;` | the campaign this envelope answers |
| `overallProblemId` | `std::uint64_t overallProblemId = 0U;` | the problem's runtime id |
| `scope` | `std::string scope = "overall";` | who is speaking: `"overall"`, `"rmp"`, `"subproblem:<id>"` or `"node:<id>"` |
| `isFinal` | `bool isFinal = true;` | false for an interim envelope |
| `status` | `pf_SolveStatus status = pf_SolveStatus::Unknown;` | the terminal outcome |
| `objectiveValue` | `double objectiveValue = 0.0;` | the objective as reported |
| `bestBound` | `double bestBound = 0.0;` | the best bound |
| `gap` | `double gap = 0.0;` | the gap between them |
| `wallSeconds` | `double wallSeconds = 0.0;` | wall-clock duration |
| `rounds` | `std::uint32_t rounds = 0U;` | how many rounds ran |
| `primalValues` | `std::vector<pf_ResultsVariable> primalValues;` | the solution, as name/value pairs |
| `primalValuesTruncated` | `bool primalValuesTruncated = false;` | the payload cap bound |
| `degradedBlocks` | `std::vector<pf_ResultsDegradation> degradedBlocks;` | blocks priced locally after a failure |
| `diagnostics` | `std::vector<std::string> diagnostics;` | free-text diagnostics |
| `substitutedBlocks` | `std::vector<pf_ResultsSubstitution> substitutedBlocks;` | blocks priced by substitution rather than by their service |
| `serviceErrors` | `std::vector<pf_ResultsServiceError> serviceErrors;` | structured failures that travelled app-ward as data |
| `producerServiceId` | `std::uint64_t producerServiceId = 0U;` | "Producer identity, for auditing" |
| `paradigm` | `std::string paradigm;` | the paradigm this envelope was produced under |
| `feasibilityCuts` | `int feasibilityCuts = 0;` | feasibility cuts, under a resource paradigm |
| `optimalityCuts` | `int optimalityCuts = 0;` | optimality cuts, under a resource paradigm |
| `perNode` | `std::vector<pf_ResultsNodeProvenance> perNode;` | each node's own account of what it did |

Seven members answer questions about the envelope rather than carrying data:

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `toJson` | `pf_JsonValue toJson() const;` | the envelope as a JSON value |
| `serialize` | `std::string serialize() const;` | "Deterministic compact JSON, suitable for the wire" |
| `parse` | `static pf_Status parse(const std::string& payload, pf_ResultsEnvelope& output);` | decode a payload; a failed status on malformed input |
| `degraded` | `bool degraded() const noexcept` | "True when any block was priced locally because a subproblem failed" |
| `pricingDistributed` | `bool pricingDistributed() const noexcept` | "True only when every block was priced by its own subproblem service" |
| `pricingProvenance` | `const char* pricingProvenance() const noexcept` | the wire spelling: `"distributed"` or `"mixed"` |
| `toSummaryText` | `std::string toSummaryText() const;` | "One-line human summary for operator output" |

`pricingDistributed()` is the header's recommended one-line question: false means
at least one block was not priced by its subproblem service.

The cut counts matter under a resource paradigm and are not decoration:
"'Optimal' from a Benders master is a claim that the loop closed its gap, and the
cut counts are what let a reader tell a genuine closure from a master that never
received a single cut and declared its unconstrained relaxation optimal."

### Version stability

The schema version string is a constant:

```cpp
inline constexpr const char* PF_RESULTS_ENVELOPE_SCHEMA_VERSION = "pf.results_envelope.v1";
```

Fields have been added to this envelope more than once, and the version has not
moved. The rule the header states is why: "A bump would be required only if a
field became mandatory or an existing field changed its type or meaning; neither
happened." Every additive field is optional on the wire and emitted only when
set, so an envelope produced today "serializes to the identical byte sequence it
produced before this field existed."

## Terminal status

```cpp
enum class pf_SolveStatus
{
    Unknown,
    Optimal,
    Feasible,
    Infeasible,
    Unbounded,
    TimeLimit,
    IterationLimit,
    Halted,
    Error
};
```

Two free functions convert it: `const char* pf_SolveStatusToString(pf_SolveStatus
status) noexcept;` and `pf_SolveStatus pf_SolveStatusFromString(const
std::string& text) noexcept;`.

`Optimal` is deliberately narrow. The header states that it "is a mathematical
claim about the model that was actually solved, and it stays exactly as it is" —
which is why a degraded or substituted pricing path is recorded in the
provenance arrays instead of being folded into the status. A caller "must
therefore never be unable to tell 5.33-with-all-blocks-priced-remotely from
5.33-with-block-2-substituted."

## Per-node provenance

A tree can compose price-directed and resource-directed levels, and a root "does
not and must not know how its children solved". So each master populates its own
entry, and the root aggregates the entries it can see — from relayed statuses and
from a child's own envelope when that child was named by
`execution.results.returnScopes`.

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `nodePath` | `std::string nodePath;` | "'overall' for the root; otherwise 'subproblem:<serviceId>[/...]'" |
| `paradigm` | `std::string paradigm;` | "The paradigm this node drove DOWNWARD: 'price_directed' \| 'resource_directed'" |
| `status` | `pf_SolveStatus status = pf_SolveStatus::Unknown;` | "This node's own terminal status, as it reported it" |
| `innerTruncated` | `bool innerTruncated = false;` | true when this node's inner loop stopped on a bound rather than on convergence |
| `substitutedBlocks` | `std::vector<pf_ResultsSubstitution> substitutedBlocks;` | "Blocks THIS node substituted, in this node's own block numbering" |
| `degradedBlocks` | `std::vector<pf_ResultsDegradation> degradedBlocks;` | "Blocks THIS node priced locally after a failure" |
| `hasGap` | `bool hasGap = false;` | whether this node produced a gap at all |
| `gap` | `double gap = 0.0;` | that gap, emitted only when `hasGap` |
| `engine` | `std::string engine;` | "The engine that actually solved here, as the solver reported it" |
| `terminationStatus` | `std::string terminationStatus;` | "The engine's own terminal status string, unnormalized" |
| `proofStatus` | `std::string proofStatus;` | "'proved' \| 'unproven' \| 'not_applicable'. Empty is NOT OBSERVED" |

`hasGap` exists so that a node that never produced a bound reports nothing rather
than zero: "writing 0.0 would claim it closed one."

`proofStatus` is the sharpest case of the absent-means-not-observed rule.
"`unproven` and 'not observed' are DIFFERENT facts, and only the first is
something a node said." The vocabulary is closed, and because the decode runs on
a DDS listener thread, a word this build does not recognize is dropped to empty
rather than propagated.

The two vocabularies in play are deliberately different, and the header explains
which question each answers: an envelope's `scope` says which `returnScopes`
entry this envelope is answering, spelled `node:<logicalNodeId>`; a `perNode`
entry's `nodePath` says where in the *running* tree something happened, spelled
in service ids. Only the second can be produced by a root that observed a node
solely through a relayed status, "because a relay carries service ids and not
node ids."

Three helpers make the node-scope spelling safe to construct and parse, and the
header notes why the prefix is checked rather than assumed: "a node id is
operator-authored and a scope string is parsed on a DDS listener thread."

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `pf_NodeScopePath` | `std::string pf_NodeScopePath(const std::string& logicalNodeId);` | "'node:<logicalNodeId>'. An empty id yields an empty string, never 'node:'" |
| `pf_ScopeIsNodePath` | `bool pf_ScopeIsNodePath(const std::string& scope);` | "True when scope is a 'node:<id>' path with a non-empty id" |
| `pf_NodeIdFromScopePath` | `std::string pf_NodeIdFromScopePath(const std::string& scope);` | "The logical node id inside a node path; empty when scope is not one" |

The two scope constants are `PF_RESULTS_SCOPE_OVERALL` (`"overall"`) and
`PF_RESULTS_SCOPE_NODE_PREFIX` (`"node:"`).

## What happened to a block

Two records describe a block that was not priced the way the topology says it
should have been. They are separate types because they are separate facts.

`pf_ResultsDegradation` is "One block whose pricing subproblem did not answer, so
DIP priced that block locally with CBC instead of using the distributed
subproblem service." It carries `blockId`, `subproblemServiceId` and a `reason`
of `"reply_timeout"` or `"empty_reply"`. The header says why the record exists at
all: "Without this record the only evidence is a line in the RMP service's
stdout."

`pf_ResultsSubstitution` is one block priced by substitution under a stated
failure policy.

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `blockId` | `int blockId = -1;` | the block, in this node's numbering |
| `subproblemServiceId` | `std::uint64_t subproblemServiceId = 0U;` | the service that should have priced it |
| `cause` | `std::string cause;` | "'reply_timeout' \| 'write_failure' \| 'reported_failure' \| 'paused' \| 'stopped'" |
| `mechanism` | `std::string mechanism = "dip_cbc_fallback";` | "What was done instead" |
| `policy` | `std::string policy;` | "The effective policy that produced the substitution" |
| `firstRound` | `int firstRound = -1;` | "The pricing round in which this block was first substituted" |
| `roundSkipped` | `bool roundSkipped = false;` | whether the block is skipped now |
| `roundsSkipped` | `int roundsSkipped = 0;` | how many rounds it was skipped for |
| `reincludedAtRound` | `int reincludedAtRound = -1;` | "the round in which a Paused-cause skip was CLEARED, or -1 if it never was" |

Substitution is not always sound, and the header is explicit that the system must
say so: for a block whose data is replicated, a local fallback "is a fair
approximation"; for a block whose data exists only on the remote node, "the same
substitution yields a confidently wrong answer rather than a degraded one."

A substituted block is not published to again for the rest of the solve, which
"turns one reply timeout per round into one per solve at the cost of foreclosing
mid-solve recovery" — and making the skip visible "is what keeps that trade
honest." One cause reverses: a `paused` peer is expected to come back, so its
skip is cleared when the subproblem resumes, while the record itself survives.
Reading `roundSkipped` alone answers "is it skipped now"; the pair
(`roundsSkipped`, `reincludedAtRound`) answers "what happened".

## Structured failures

`pf_ResultsServiceError` is "One structured failure that reached the application
as data rather than as silence."

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `originServiceId` | `std::uint64_t originServiceId = 0U;` | which service produced it |
| `category` | `std::string category;` | the error category string |
| `code` | `std::string code;` | the error code string, e.g. `"transport.timeout"` |
| `scope` | `std::string scope;` | `"overall"`, `"rmp"`, or a `subproblem:<id>[/subproblem:<id>]*` path |
| `iterCount` | `std::uint32_t iterCount = 0U;` | the iteration it arrived at |
| `detail` | `std::string detail;` | free text |

`scope` is a path rather than a single origin "so a nested-decomposition abort
can name its route from the root".

## Payload bounds

Two constants are applied at the publishing site "so a large solution cannot
produce a DDS sample the transport will not carry":

```cpp
inline constexpr std::size_t PF_RESULTS_MAX_PRIMAL_VALUES = 50000U;
inline constexpr std::size_t PF_RESULTS_MAX_PAYLOAD_BYTES = 8U * 1024U * 1024U;
```

These are distinct from the presentation filter an author writes. The header
says which is which: `execution.results.variableFilter` "is a presentation filter
applied by the submitting app; these bounds are what actually protect the wire."

## Collecting results

`pf_Results_Gateway.h` declares the app-side collector, the node-side publisher,
and the container that holds one campaign's arrivals.

`pf_CampaignResults` is "Everything that arrived for one campaign correlation
ID": `haveFinal` and the root `overall` envelope, `subproblemResults`,
`interim`, `nodeResults` for the non-root masters named by `returnScopes`,
`serviceErrors`, and a `nacked` flag with its record.

The `nacked` flag short-circuits a wait that has become pointless: it is true
"when a status with scope 'overall' and a validation or transport category
arrived BEFORE any result", which means the submission was rejected or could not
be distributed, "instead of letting the application sit out its full results
timeout for an answer that was never going to come."

`serviceErrors` is populated "whether or not a result ever arrives, which is the
point: the case this channel exists for is the one where no result is coming."

### `pf_ResultsCollector`

Fed by the results listener, it demultiplexes envelopes by correlation id and
completes a waitable gate when the final `"overall"` envelope arrives. The header
states the concurrency contract: "Every member is thread-safe: envelopes arrive
on a DDS listener thread while the submitting thread waits."

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `expect` | `void expect(const std::string& correlationId);` | "Registers interest in a correlation ID before publishing the problem" |
| `onEnvelope` | `void onEnvelope(const pf_ResultsEnvelope& envelope);` | "Accepts one decoded envelope. Unknown correlation IDs are ignored" |
| `onServiceStatus` | `void onServiceStatus(const std::string& correlationId, const pf_ResultsServiceError& serviceError);` | accept one status record |
| `waitForFinal` | `bool waitForFinal(const std::string& correlationId, std::chrono::seconds timeout, pf_CampaignResults& output, std::size_t expectedNodeScopes = 0U, std::chrono::milliseconds settleWindow = std::chrono::milliseconds(0));` | block until the final `"overall"` envelope arrives or the timeout expires |
| `decode` | `static pf_Status decode(const pfMessenger::OVERALL_RESULTS& message, pf_ResultsEnvelope& output);` | "Decodes a wire message into an envelope. The wire's routing fields override any duplicates inside the payload" |

`onServiceStatus` has one deliberate exception to the ignore-unknown rule: a
record whose correlation id is empty "is delivered to every waiting campaign",
because a producer that never received one — a service rejecting a submission
before it has parsed a correlation id — "would have no other way to reach the
only application that is waiting, and dropping those records would silently
re-create the very silence this channel removes."

`waitForFinal` returns true only when a final envelope was received, and the
output is filled either way with whatever accumulated. When at least one non-root
scope was expected, the wait continues for a bounded settle window after the
root's envelope, "because a mid publishes from its own process on its own
schedule; the root's answer is not evidence that the mid's has landed." The
return value does not depend on that window: a campaign whose mid never answers
still returns true with the root's result and carries no entry for that node,
"which is exactly what 'ABSENT means not observed' requires."

The window's ceiling is declared beside the envelope:

```cpp
inline constexpr std::chrono::milliseconds PF_RESULTS_NODE_SETTLE_WINDOW{2000};
```

It is "A ceiling, not a delay. The wait exits the instant every expected scope is
in hand, so a healthy campaign pays one poll interval."

### `pf_ResultsPublisher`

The node-side publisher, called by solver managers at a terminal solve state.
"A failed results write is reported and swallowed: losing a result must not kill
a solve service that has already done the work."

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `setWriter` | `void setWriter(pfMessenger::OVERALL_RESULTSDataWriter* writer_ptr);` | install the writer |
| `publish` | `pf_Status publish(std::uint64_t recipient, const pf_ResultsEnvelope& envelope);` | encode and publish to the return-to service id, applying the payload caps first |
| `applyPayloadCaps` | `static void applyPayloadCaps(pf_ResultsEnvelope& envelope);` | apply both bounds, setting `primalValuesTruncated` and appending a diagnostic when either binds |

Two free functions read the routing options the submitting app minted:

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `pf_Results_FindReturnTo` | `bool pf_Results_FindReturnTo(pf_Commands& commands, std::uint64_t& returnToServiceId);` | the return-to service id |
| `pf_Results_FindCorrelationId` | `bool pf_Results_FindCorrelationId(pf_Commands& commands, std::string& correlationId);` | the campaign correlation id |

Both return false when the option is absent, "which is the normal case for the
legacy demo path that mints neither."

## Beyond one run

An envelope is what one run returns. The Workbench keeps them: each run's own
results document is ingested into a persistent, hierarchy-aware results plane,
one row per envelope the document carries, "stored as the document carried it".
Ingestion parses that document rather than reading a wire, and the `results.query`
and `results.follow` verbs read it back. See
[Workbench reference](../../guide/workbench.md) and
[Files & artifacts](../data/artifacts.md).
