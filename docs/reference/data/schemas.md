# Schemas

<!-- dc:status=polished dc:owner=DC2 -->

Four JSON Schema files in the repository root define the document contracts
PlasticFog reads and writes. This page says what each one is for, who reads and
writes it, and its top-level fields. The schema files themselves are the
exhaustive source; nothing here restates them field for field.

All four are Draft 2020-12, and each is identified by a `schemaVersion` constant
rather than by its filename, so a document names its own contract.

## `pf_problem_input.schema.json`

**Purpose.** The authored contract: the grammar a problem definition, a spot
update or a control command has to satisfy. It is the largest of the four and
the only one an author writes against.

**Who reads and writes it.** Authors and generators write documents against it;
the C++ codec enforces it, and enforces on top of it the semantic invariants
JSON Schema cannot express conveniently — the tree, the roles, the promotion
chains, downward-paradigm uniformity, engine legality by role, results scopes,
placement alternatives, the run spec, solver guarantees and catalog identity.
The same layer refuses at submit every capability that is spellable here and not
executable by this build. The command-line gate that runs it over a file is
`pf spec validate`, in the [Workbench reference](../../guide/workbench.md).

The file's top level is a `oneOf` over three document kinds, dispatched by
`schemaVersion`.

### `pf.problem_definition.v1`

| Field | Type | Meaning |
|---|---|---|
| `schemaVersion` | const `pf.problem_definition.v1` | which contract this document is |
| `problem` | object | identity: `id`, `version`, `revision`, `description`, `metadata` |
| `resources` | object | `models` (at least one) and optional `data` |
| `topology` | object | `rootNodeId`, `nodes`, `boundaries` |
| `execution` | object | solve and result-return policy |
| `runSpec` | object | how many times the submission executes, and on what cadence |
| `observability` | object | what streams, and how it is displayed |
| `catalog` | object | inert identity metadata: application id, title, tags |

`schemaVersion`, `problem`, `resources` and `topology` are required; the rest
are optional with defaults. [Problem definitions](../../guide/problem-definitions.md)
is the guided tour of this document.

### `pf.problem_update.v1`

| Field | Type | Meaning |
|---|---|---|
| `schemaVersion` | const `pf.problem_update.v1` | which contract this document is |
| `update` | object | `id`, `problemId`, `baseRevision`, optional `baseContentHash`, `mode`, `interrupt`, `description` |
| `payload` | any | the change itself; its shape follows `update.mode` |

All three are required. `mode` is `json_patch`, `merge_patch` or `replace`;
`interrupt` is `auto`, `always` or `never`. `baseRevision` is a
compare-and-swap guard rather than a hint, and `baseContentHash` is the stronger
form of the same guard.

### `pf.problem_command.v1`

| Field | Type | Meaning |
|---|---|---|
| `schemaVersion` | const `pf.problem_command.v1` | which contract this document is |
| `command` | object | `id`, `problemId`, optional `baseRevision`, `verb`, `targets`, `applyToChildren` |

Both are required. A command parses standalone: the problem is named by id and
the definition is not required in the same document, so a caller holding only
the command can accept or reject it on shape alone. `verb` is one of `start`,
`pause`, `resume`, `stop`, `halt` or `request_results`; `targets` carries exactly
one of `all` or a non-empty `nodeIds` list.

## `pf_runtime_topology.schema.json`

**Purpose.** The runtime-side view of a submitted problem: what each logical
node *is* — role, the paradigm above it and the one below it, its solver engines
by role, its resolved placement service ids — and what it is *doing*, its run
state. It is persisted beside a results document so that a later spot update can
be validated against a live solve.

**Who reads and writes it.** The update-validation path reads one.
**Nothing in the schema layer produces one**: the types, the codec and the rules
that consume a summary live there, but populating a summary from real service
state is the submitting application's job. A summary derived from a definition
alone carries the shape half only — explicit service ids, because query
placements resolve at submit, and every run state `unknown`.

| Field | Type | Meaning |
|---|---|---|
| `schemaVersion` | const `pf.runtime_topology.v1` | which contract this document is |
| `problemId` | string | the problem this summary describes |
| `revision` | integer | the revision it describes; a summary whose revision differs from the active one is stale and is refused as a basis for update validation |
| `contentHash` | string | optional SHA-256 of the canonical problem document the summary describes |
| `nodes` | object | one summary per node: `role`, `upParadigm`, `downParadigm`, `enginesByRole`, `placementServiceIds`, `runState` |

`schemaVersion`, `problemId` and `nodes` are required. `runState` is one of
`idle`, `setup`, `solving`, `paused`, `stopped`, `failed` or `unknown`, and
`unknown` is the honest default: it is **not** treated as running, because a
summary that cannot say what a node is doing must not block an update by
accident. A caller that wants an update blocked says `solving` or `paused`.

## `pf_service_query.schema.json`

**Purpose.** The structured registry query: the document carried by a request to
the Register service asking which services match a selector. It replaced a
deprecated option whose value was a raw SQL statement composed by the client.

**Who reads and writes it.** A client writes one — five of its fields correspond
one for one with the query-placement selector in a problem definition, so a
placement maps directly onto a registry query. The registry parses it, validates
every field, and composes a parameterized statement; **no value from the
document is ever concatenated into SQL text.**

| Field | Type | Meaning |
|---|---|---|
| `schemaVersion` | enum | `pf.service_query.v1` is canonical; the pre-reversion `rf.` spelling is accepted as a deprecated alias and logged as such, and new clients must not emit it |
| `type` | string | the service type code to match, as the service registered it |
| `count` | integer | the maximum number of services to return |
| `availableOnly` | boolean | restrict to services flagged available and not deactivated |
| `requireCapabilities` | array | every listed capability token must be present on a service for it to match |
| `selection` | enum | ordering policy: `any` or `newest` |
| `name` | string | the grouping label the matching ids are returned under — a key the requester chooses, not a service name |

`schemaVersion`, `type` and `count` are required.

Two properties of the contract are worth carrying. **A short or empty result is
success, not an error**: the registry returns up to `count` services, possibly
fewer, and the requester decides whether a shortfall matters. And the placement
vocabulary's `least_loaded` policy is deliberately **not** accepted here,
because the framework collects no load telemetry — silently serving a different
policy would misrepresent the placement the caller asked for.

## `pf_coupling_manifest.schema.json`

**Purpose.** What one compile unit's model is made of, and how its symbols
correspond to the decomposition around it: every symbol the compiled model
declares with both its authored full name and its abbreviated emitted name, the
block partition, and the coupling correspondence across the boundaries the
unit's node sits on.

**Who reads and writes it.** It is written by the staging dump — one manifest
per unit, beside that unit's request. **It is emit-only: nothing in this build
reads a manifest, no refusal consults one, and no exit status depends on one.**
It exists because the hardest defects in this area are name questions, and the
answers otherwise live in four different files in four different formats, none
of them written down after a run.

| Field | Type | Meaning |
|---|---|---|
| `schemaVersion` | const `pf.coupling_manifest.v1` | which contract this document is |
| `problemId` | string | the document's problem id, as the compile request carried it |
| `unit` | object | which compile unit this is: service id, module id, role, node id, level, entry file name |
| `symbols` | array | every symbol the compiled model declares, in the symbol table's own order, each with its full name, emitted name, index, kind, whether it couples, and its owning service |
| `blocks` | array | masters only, empty for a leaf: the block partition, block *k* being the *k*-th associated subproblem service |
| `couplingCorrespondence` | array | every coupling declaration on a boundary this unit's node is on, with the side this unit is |

All six are required. [Files & artifacts](artifacts.md) covers where a manifest
appears in the workflow.

## The two prompt-pack schemas

The prompt pack ships two further contracts, and they are contracts on a
*model's* output rather than on a document the runtime reads. They are shipped
as schemas rather than as prose because a caller that wants to reject a
malformed response should not have to parse English to do it.

`response_envelope.schema.json` fixes the one JSON object a response is:
`response_type`, `request_id`, `assumptions[]`, `warnings[]` and a `payload`
whose shape follows from the type. `clarification.schema.json` fixes one
question: `question_id`, `question`, `why_it_matters`, optional `choices[]`,
`suggested_default` and `blocking`. Both are described in
[Authoring with an LLM](../../guide/llm-authoring.md).

## The results envelope has no schema file

`pf.results_envelope.v1` is the contract a run's answer comes back on, and it is
declared in C++ — in `pf_Results_Types.h` — rather than in a `.schema.json`.
There is no schema file for it, and a reader looking for one should stop
looking. [Results](../api/results.md) documents the envelope;
[Files & artifacts](artifacts.md) covers where it lands on disk.

## Why the version strings do not move

Capabilities have been added to the definition contract without moving
`pf.problem_definition.v1`, and the rule is stated rather than assumed: **every
addition is optional with a default, and no existing field changes meaning.** A
document written before an addition parses after it and means the same thing; a
document written after it, read by a consumer that predates it, loses the new
fields and is still a coherent problem — which is exactly the property a version
string exists to protect. A bump would be required only if a field became
mandatory or an existing one changed meaning.

The same rule governs the results envelope, which took provenance fields and
structured failures additively and kept its version string.

New *document kinds* do get their own versions, because they are new documents
rather than new fields: the command form is a third branch of the same schema
file with its own version constant, and the runtime topology summary has a file
of its own because it is produced by the application rather than authored by an
operator.
