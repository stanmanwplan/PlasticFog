# Problem input

<!-- dc:status=polished dc:owner=DC4a -->

The problem-input library is the C++ entry point for everything an author
writes: a problem definition, a spot update against one, or a control command
addressed at a running problem. This page documents the calls a program makes
against those documents — parsing, validation, canonical form, transactional
ownership of the active definition — and the error surface the validator
refuses with.

Four headers make up the surface: `pf_ProblemInput.h` (the codec and semantic
validator), `pf_ProblemInput_Manager.h` (the transactional owner),
`pf_Json.h` (the value type everything is expressed in) and `pf_Hash.h` (the
content hash). They build into `pf_problem_input`, which links no DDS, no
COIN-OR and no SQLite; see the [API overview](index.md).

For the fields these documents carry, rather than the calls that read them, see
[Problem definitions](../../guide/problem-definitions.md) and
[Schemas](../data/schemas.md).

## Documents

One codec reads all three document kinds and dispatches on the version string
each carries.

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `pf_ProblemInput_DocumentKind` | `enum class pf_ProblemInput_DocumentKind { ProblemDefinition, ProblemUpdate, ProblemCommand }` | which of the three a document is |
| `pf_ProblemInput_Document::kind` | `pf_ProblemInput_DocumentKind kind = pf_ProblemInput_DocumentKind::ProblemDefinition;` | the discriminator |
| `pf_ProblemInput_Document::problem` | `pf_ProblemDefinition problem;` | populated when `kind` is `ProblemDefinition` |
| `pf_ProblemInput_Document::update` | `pf_ProblemUpdate update;` | populated when `kind` is `ProblemUpdate` |
| `pf_ProblemInput_Document::command` | `pf_ProblemCommand command;` | populated when `kind` is `ProblemCommand` |

The version strings are declared as constants in the same header —
`PF_PROBLEM_DEFINITION_SCHEMA_VERSION`, `PF_PROBLEM_UPDATE_SCHEMA_VERSION`,
`PF_PROBLEM_COMMAND_SCHEMA_VERSION`, and two legacy package versions the codec
still imports.

## Reading a document

`pf_ProblemInput` is a class of static functions. Its header states the scope
of the whole class: "All APIs are DDS-free and can be called from an LLM tool, a
local app, or an API handler."

Every entry point takes an output object, a report, and options; every one
returns `pf_Status` — the shared return convention, documented under
[Errors and status](index.md#errors-and-status). The `Value` forms read a JSON
value already in memory, the `Text` forms parse a string, and the `File` forms
read a bounded file.

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `parseDocumentText` | `static pf_Status parseDocumentText(std::string_view jsonText, pf_ProblemInput_Document& output, pf_ProblemInput_Report& report, const pf_ProblemInput_Options& options = pf_ProblemInput_Options());` | parse any of the three kinds from a string |
| `parseDocumentValue` | `static pf_Status parseDocumentValue(const pf_JsonValue& document, pf_ProblemInput_Document& output, pf_ProblemInput_Report& report, const pf_ProblemInput_Options& options = pf_ProblemInput_Options());` | the same from a parsed JSON value |
| `parseProblemText` | `static pf_Status parseProblemText(std::string_view jsonText, pf_ProblemDefinition& output, pf_ProblemInput_Report& report, const pf_ProblemInput_Options& options = pf_ProblemInput_Options());` | parse a problem definition specifically |
| `parseProblemValue` | `static pf_Status parseProblemValue(const pf_JsonValue& document, pf_ProblemDefinition& output, pf_ProblemInput_Report& report, const pf_ProblemInput_Options& options = pf_ProblemInput_Options());` | the same from a value |
| `parseUpdateText` | `static pf_Status parseUpdateText(std::string_view jsonText, pf_ProblemUpdate& output, pf_ProblemInput_Report& report, const pf_ProblemInput_Options& options = pf_ProblemInput_Options());` | parse a spot update |
| `parseUpdateValue` | `static pf_Status parseUpdateValue(const pf_JsonValue& document, pf_ProblemUpdate& output, pf_ProblemInput_Report& report, const pf_ProblemInput_Options& options = pf_ProblemInput_Options());` | the same from a value |
| `parseCommandText` | `static pf_Status parseCommandText(std::string_view jsonText, pf_ProblemCommand& output, pf_ProblemInput_Report& report, const pf_ProblemInput_Options& options = pf_ProblemInput_Options());` | parse a control command |
| `parseCommandValue` | `static pf_Status parseCommandValue(const pf_JsonValue& document, pf_ProblemCommand& output, pf_ProblemInput_Report& report, const pf_ProblemInput_Options& options = pf_ProblemInput_Options());` | the same from a value |
| `readDocumentFile` | `static pf_Status readDocumentFile(const std::string& fileName, pf_ProblemInput_Document& output, pf_ProblemInput_Report& report, pf_ProblemInput_Options options = pf_ProblemInput_Options());` | "Read either a full problem or an update from a file" |
| `readProblemFile` | `static pf_Status readProblemFile(const std::string& fileName, pf_ProblemDefinition& output, pf_ProblemInput_Report& report, pf_ProblemInput_Options options = pf_ProblemInput_Options());` | read a definition from a file |
| `readUpdateFile` | `static pf_Status readUpdateFile(const std::string& fileName, pf_ProblemUpdate& output, pf_ProblemInput_Report& report, pf_ProblemInput_Options options = pf_ProblemInput_Options());` | read an update from a file |
| `readCommandFile` | `static pf_Status readCommandFile(const std::string& fileName, pf_ProblemCommand& output, pf_ProblemInput_Report& report, pf_ProblemInput_Options options = pf_ProblemInput_Options());` | read a command from a file |

The `File` overloads take their options **by value** because the codec fills in
`sourceRoot` from the file's own location before resolving anything the document
references.

A control command parses on its own terms. The header states it directly:
"Control commands parse standalone: no problem definition is required in the
same document, and none is consulted here. Cross-checks against a topology are
`validateCommand`'s job."

## Writing and canonical form

Canonical JSON is what the content hash is taken over, so these are the calls
that decide a revision's identity.

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `toJson` | `static pf_JsonValue toJson(const pf_ProblemDefinition& problem);` | "Convert typed structures to their canonical JSON representation" |
| `toJson` | `static pf_JsonValue toJson(const pf_ProblemUpdate& update);` | the same for an update |
| `toJson` | `static pf_JsonValue toJson(const pf_ProblemCommand& command);` | the same for a command |
| `writeProblemText` | `static std::string writeProblemText(const pf_ProblemDefinition& problem, int indent = 2);` | canonical JSON as a string |
| `writeUpdateText` | `static std::string writeUpdateText(const pf_ProblemUpdate& update, int indent = 2);` | the same for an update |
| `writeCommandText` | `static std::string writeCommandText(const pf_ProblemCommand& command, int indent = 2);` | the same for a command |
| `writeProblemFile` | `static pf_Status writeProblemFile(const std::string& fileName, const pf_ProblemDefinition& problem, bool overwrite = true, bool atomicWrite = true, int indent = 2);` | write a definition to a file |
| `writeUpdateFile` | `static pf_Status writeUpdateFile(const std::string& fileName, const pf_ProblemUpdate& update, bool overwrite = true, bool atomicWrite = true, int indent = 2);` | write an update to a file |
| `writeCommandFile` | `static pf_Status writeCommandFile(const std::string& fileName, const pf_ProblemCommand& command, bool overwrite = true, bool atomicWrite = true, int indent = 2);` | write a command to a file |

Defaulted fields are materialized in the canonical document rather than left
implicit. The header states the consequence for the solver block: "a document
that omits `solver` and one that states the role default emit the same bytes and
therefore the same content hash."

Optional top-level blocks work the other way, and each carries its own `present`
flag. `pf_RunSpec`, `pf_ObservabilitySpec`, `pf_SolverGuarantee`,
`pf_SolverSpeculation`, `pf_SolverCertification` and `pf_CatalogSpec` are
"emitted into canonical JSON only when the document carried it, so every
definition written before they existed canonicalizes to the bytes it always did
and its `contentHash` does not move."

## Commands against a topology

Two calls answer the questions a command document cannot answer alone.

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `validateCommand` | `static pf_Status validateCommand(const pf_ProblemCommand& command, const pf_ProblemDefinition& problem, pf_ProblemInput_Report& report);` | the cross-document rules: the command names this problem, every target exists, `start` and `request_results` address a master-side node |
| `expandTargets` | `static std::vector<std::string> expandTargets(const pf_ProblemCommand& command, const pf_ProblemDefinition& problem);` | the ordered node list a command addresses |

`expandTargets` is documented as pure — "it reads the definition and returns a
list" — and its order is defined: each target's descendants are appended
depth-first in pre-order when `applyToChildren` is set, and "duplicates are
removed keeping first occurrence, so overlapping targets expand once."

## Identifiers, vocabulary and capability

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `stableId` | `static std::uint64_t stableId(const std::string& problemId, const std::string& elementKind, const std::string& elementId) noexcept;` | "Deterministic nonzero module ID derived from problem, element kind, and stable element ID" |
| `toString` | `static const char* toString(pf_ServiceRole value) noexcept;` | the wire spelling of an enum value; overloads exist for every enum on this page |
| `serviceRoleFromString` | `static bool serviceRoleFromString(std::string_view text, pf_ServiceRole& value) noexcept;` | parse a role name |
| `solverKindFromString` | `static bool solverKindFromString(std::string_view text, pf_SolverKind& value) noexcept;` | parse a solver kind |
| `solverEngineFromString` | `static bool solverEngineFromString(std::string_view text, pf_SolverEngine& value) noexcept;` | parse an engine name |
| `commandVerbFromString` | `static bool commandVerbFromString(std::string_view text, pf_ProblemCommandVerb& value) noexcept;` | parse a command verb |
| `defaultSolverEngineFor` | `static pf_SolverEngine defaultSolverEngineFor(pf_ServiceRole role) noexcept;` | "The engine a role uses when 'solver' is absent" |
| `solverEngineIsExecutable` | `static bool solverEngineIsExecutable(pf_SolverEngine engine) noexcept;` | "True for engines the current services can actually execute" |
| `solverKindIsExecutable` | `static bool solverKindIsExecutable(pf_SolverKind kind) noexcept;` | "True when the current runtime can execute this solver KIND" |
| `solverEngineAllowedForRole` | `static bool solverEngineAllowedForRole(pf_SolverEngine engine, pf_ServiceRole role) noexcept;` | "True when the engine may be selected for this role at all" |
| `serviceRoleIsMasterSide` | `static bool serviceRoleIsMasterSide(pf_ServiceRole role) noexcept;` | whether the role speaks for a subtree |
| `masterRoleFor` | `static pf_ServiceRole masterRoleFor(pf_DecompositionParadigm paradigm) noexcept;` | the master-side role a paradigm implies |
| `subproblemRoleFor` | `static pf_ServiceRole subproblemRoleFor(pf_DecompositionParadigm paradigm) noexcept;` | the subproblem-side role a paradigm implies |

`toString` has an overload for each of `pf_ProblemNodeRole`,
`pf_DecompositionParadigm`, `pf_DecompositionBinding`, `pf_ServiceRole`,
`pf_DataDistribution`, `pf_CouplingDiscoveryMode`, `pf_CouplingKind`,
`pf_PromotionRole`, `pf_ProblemUpdateMode`, `pf_InterruptDirective`,
`pf_SolverKind`, `pf_SolverEngine` and `pf_ProblemCommandVerb`.

`solverEngineIsExecutable` is not a compile-time constant for every engine. The
header records that `cuopt` "is answered by a live probe" — "its adapter is
compiled in unconditionally, and whether it can solve depends on a shared
library and a CUDA device this build never links" — while every other engine is
still decided at compile time. `solverKindIsExecutable` answers `gpu` through
the same probe, "because this build's only GPU-capable adapter IS cuopt and a
`gpu` kind is a request for it by capability rather than by name."

The role defaults are stated in the header: `priceMaster` is DIP, `resourceMaster`
is CBC, `priceSubproblem` is SYMPHONY, `resourceSubproblem` is CLP. Which
engines a role *accepts*, as opposed to which it defaults to, is on
[Problem definitions](../../guide/problem-definitions.md).

## Diagnostics

A report accumulates what the codec and the semantic validator found. It is a
value: it is passed in, filled, and read back.

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `warning` | `void warning(std::string pointer, std::string code, std::string message);` | record a warning at a JSON Pointer |
| `error` | `void error(std::string pointer, std::string code, std::string message);` | record an error at a JSON Pointer |
| `ok` | `bool ok() const noexcept;` | no errors were recorded |
| `hasWarnings` | `bool hasWarnings() const noexcept;` | at least one warning was recorded |
| `errorCount` | `std::size_t errorCount() const noexcept;` | how many errors |
| `warningCount` | `std::size_t warningCount() const noexcept;` | how many warnings |
| `diagnostics` | `const std::vector<pf_ProblemInput_Diagnostic>& diagnostics() const noexcept;` | every diagnostic, in the order recorded |
| `toText` | `std::string toText() const;` | the human-readable rendering |
| `clear` | `void clear() noexcept;` | discard everything recorded |

Each diagnostic carries four fields — `level`, `pointer`, `code` and `message` —
where `level` is `pf_ProblemInput_DiagnosticLevel::Warning` or `::Error`.

## Options

`pf_ProblemInput_Options` is the one place a caller changes what parsing means.

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `json` | `pf_JsonParseOptions json;` | the JSON layer's own bounds |
| `sourceRoot` | `std::string sourceRoot;` | the directory external references resolve against |
| `resolveExternalResources` | `bool resolveExternalResources = true;` | whether file-backed model and data sources are read |
| `allowLegacyProblemPackage` | `bool allowLegacyProblemPackage = true;` | whether a legacy package document may be imported |
| `rejectUnknownProperties` | `bool rejectUnknownProperties = true;` | whether a property outside the schema is an error |
| `checkZimplMarkers` | `bool checkZimplMarkers = true;` | whether the Zimpl marker rules run at parse time |
| `maxResourceBytes` | `std::size_t maxResourceBytes = 16U * 1024U * 1024U;` | the ceiling on one resolved resource |
| `maxTopologyDepth` | `std::size_t maxTopologyDepth = 64U;` | the deepest topology accepted |

## The object model

A parsed definition is a tree of plain structs. The table names each one and
what it holds; the field-level meaning of the document these mirror is on
[Problem definitions](../../guide/problem-definitions.md).

| Struct | What it holds |
|---|---|
| `pf_ProblemDefinition` | identity (`problemId`, `version`, `revision`, `contentHash`), `models`, `data`, `rootNodeId`, `nodes`, `boundaries`, `execution`, the optional `runSpec` / `observability` / `catalog` blocks, and `canonicalDocument` |
| `pf_ProblemNodeSpec` | one node: `id`, `role`, `level`, and its `services` keyed by service role |
| `pf_ProblemServiceBindingSpec` | one node's binding for one role: `modelRef`, `dataRefs`, `placement`, `solver` |
| `pf_ProblemBoundarySpec` | one parent/child edge: `paradigm`, `binding`, `couplingMode`, `couplingDeclarations` |
| `pf_CouplingDeclaration` | one crossing symbol: `couplingKey`, `kind`, `parentSymbol`, `childSymbol`, `ownerNodeId`, `valueType`, optional `promotion` |
| `pf_ProblemModelSpec` / `pf_ProblemDataSpec` | a named model or data resource and its source |
| `pf_ProblemTextSource` | `inline` or `file`, the resolved bytes, and the `sha256` that pins them |
| `pf_PlacementSpec` | where a role's solve runs: `Explicit`, `Query`, `Spawn` or `Auto`, exactly one populated |
| `pf_PlacementQuery` | the registry selector: `type`, `count`, `requireCapabilities`, `availableOnly`, `selection` |
| `pf_SolverSpec` | `kind`, `engine`, opaque `options`, and the optional `guarantee` and `speculation` blocks |
| `pf_SolverGuarantee` | what an answer must certify (`requirement`, `onUncertifiedAction`, optional fallback engine) and the `certification` policy |
| `pf_SolverCertification` | when an unproven claim is certified: `mode`, `sampleRate`, `seed`, and the optional rider-timeout fields |
| `pf_SolverSpeculation` | the column farm: `columns`, `epsilon`, `seed` |
| `pf_ProblemExecutionSpec` | `maxIterations`, `timeLimitSeconds`, `convergenceTolerance`, `innerSolvePolicy`, `innerIterationBound`, and `results` |
| `pf_ProblemResultsSpec` | `returnMode`, `output`, `waitSeconds`, `variableFilter`, `interimProgress`, `returnScopes` |
| `pf_RunSpec` | repeated execution: `mode`, `count`, `intervalSeconds`, `overlap`, `warmStart`, `stop` |
| `pf_ObservabilitySpec` | result streaming and log display policy |
| `pf_CatalogSpec` | "INERT identity metadata for an application catalogue: who this definition is, not what it does" |
| `pf_ProblemUpdate` | a patch against an exact base: `baseRevision`, `baseContentHash`, `mode`, `interrupt`, `payload` |
| `pf_ProblemCommand` | a verb, its `targets`, `applyToChildren`, and an optional `baseRevision` pin |

Six lookups on `pf_ProblemDefinition` save a caller writing its own traversal:

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `findNode` | `const pf_ProblemNodeSpec* findNode(const std::string& nodeId) const noexcept;` | one node by id, or `nullptr` |
| `findBoundary` | `const pf_ProblemBoundarySpec* findBoundary(const std::string& boundaryId) const noexcept;` | one boundary by id |
| `findModel` | `const pf_ProblemModelSpec* findModel(const std::string& modelId) const noexcept;` | one model resource by id |
| `findData` | `const pf_ProblemDataSpec* findData(const std::string& dataId) const noexcept;` | one data resource by id |
| `childBoundaries` | `std::vector<const pf_ProblemBoundarySpec*> childBoundaries(const std::string& nodeId) const;` | the edges down from a node |
| `parentBoundary` | `const pf_ProblemBoundarySpec* parentBoundary(const std::string& nodeId) const noexcept;` | the edge up from a node |

Several blocks in this model are valid to author and not executable by the
current build; a `spawn` or `auto` placement, a `gpu` kind and a `runSpec` mode
other than `once` are the header's own examples. Each is carried through the
schema and refused at submit rather than silently ignored, and the refusal names
the pass that retires it.

## Owning the active definition

`pf_ProblemInput_Manager` is the transactional owner of one problem definition.
Its header states the guarantee: it is a "Thread-safe transactional owner of the
active problem definition", and updates "are applied to a copy, fully re-parsed
and re-validated, and become visible atomically only after validation succeeds."

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| constructor | `explicit pf_ProblemInput_Manager(std::size_t maxRememberedUpdateIds = 4096U);` | the bounded replay-rejection window |
| `submitText` | `pf_Status submitText(std::string_view jsonText, pf_ProblemInput_Commit& commit, pf_ProblemInput_Report& report, const pf_ProblemInput_Options& options = pf_ProblemInput_Options());` | submit a document as text |
| `submitValue` | `pf_Status submitValue(const pf_JsonValue& document, pf_ProblemInput_Commit& commit, pf_ProblemInput_Report& report, const pf_ProblemInput_Options& options = pf_ProblemInput_Options());` | submit a parsed value |
| `submitFile` | `pf_Status submitFile(const std::string& fileName, pf_ProblemInput_Commit& commit, pf_ProblemInput_Report& report, pf_ProblemInput_Options options = pf_ProblemInput_Options());` | submit from a file |
| `submitProblem` | `pf_Status submitProblem(const pf_ProblemDefinition& problem, pf_ProblemInput_Commit& commit, pf_ProblemInput_Report& report, const pf_ProblemInput_Options& options = pf_ProblemInput_Options());` | submit an already-typed definition |
| `applyUpdate` | `pf_Status applyUpdate(const pf_ProblemUpdate& update, pf_ProblemInput_Commit& commit, pf_ProblemInput_Report& report, const pf_ProblemInput_Options& options = pf_ProblemInput_Options());` | apply a spot update and commit it |
| `validateUpdateAgainstRuntime` | `pf_Status validateUpdateAgainstRuntime(const pf_ProblemUpdate& update, const pf_RuntimeTopologySummary& summary, pf_ProblemInput_Report& report, const pf_ProblemInput_Options& options = pf_ProblemInput_Options()) const;` | decide whether an update may be applied while services are running, **without** applying it |
| `snapshot` | `std::shared_ptr<const pf_ProblemDefinition> snapshot() const;` | the active definition, immutable |
| `revision` | `std::uint64_t revision() const noexcept;` | the active revision number |
| `contentHash` | `std::string contentHash() const;` | the active revision's content hash |
| `waitForRevision` | `std::shared_ptr<const pf_ProblemDefinition> waitForRevision(std::uint64_t minimumRevision, std::chrono::milliseconds timeout) const;` | "Wait until a committed snapshot reaches at least minimumRevision" |
| `setObserver` | `void setObserver(Observer observer);` | install the commit callback |
| `clear` | `void clear();` | drop the active definition |

`Observer` is `std::function<void(const pf_ProblemInput_Commit&)>`. The header
states the callback contract: notifications "are serialized in commit order and
invoked outside the state mutex", and "a callback may safely call back into the
manager; such nested notifications are queued behind the current one."

A commit describes what changed. `pf_ProblemInput_Commit` carries the new
`snapshot`, the previous and new revision and content hash, `fullReplacement`,
`requiresSolveInterrupt`, the `interruptDirective` the update asked for, and a
`pf_ProblemInput_ChangeSet`. The change set classifies the diff — whether
topology, model logic, data, placement, execution or metadata changed — lists
the affected node, boundary, model and data ids, and carries the JSON Pointers
that moved.

!!! note
    The manager classifies and reports; it does not act. Its header is explicit:
    "The manager does not itself stop a solve; `requiresSolveInterrupt` tells the
    future generalized app whether it should ask its solve controller to do so."

### Updating a running problem

`validateUpdateAgainstRuntime` answers the question `applyUpdate` would answer,
against a copy that is then discarded. Nothing is committed and no observer
fires whatever the verdict, "so a caller may ask this question of a live manager
freely." The optimistic-concurrency check still fires first: an update built
against a stale revision is refused before any runtime rule is consulted.

Four rules are then checked against the supplied runtime summary. The header
names them:

| Code | Fires when |
|---|---|
| `update.running_paradigm_change` | a boundary's paradigm or binding changed and its child subtree holds a `Solving` or `Paused` node |
| `update.running_placement_change` | a placement changed on such a subtree |
| `update.running_solver_change` | a solver engine or kind changed on such a subtree |
| `update.running_node_removal` | a node with running descendants was removed |

The first three are waived by `interrupt: always` — "the operator has said to
interrupt the solve, so disturbing it is the instruction rather than the
accident." The fourth is not waivable: "interrupting a solve still leaves the
removed node's descendants with no parent to report to."

All four gate structure rather than content, and all four are asked of the
target's own subtree rather than of the run. Every change to models, data or
execution policy passes them, so it is legal against a target that is solving or
paused; a structural change is refused only when the target's own subtree holds
such a node, whatever the rest of the hierarchy is doing.

## JSON values

`pf_JsonValue` is the value type the whole surface is expressed in. Its header
describes it as "A small, dependency-free JSON value and codec" implementing
"strict RFC 8259 parsing, deterministic serialization, JSON Pointer (RFC 6901),
JSON Patch (RFC 6902), and JSON Merge Patch (RFC 7396)".

Its type is one of `Null`, `Boolean`, `SignedInteger`, `UnsignedInteger`,
`Number`, `String`, `Array` or `Object`, and the accessors follow that list:
`type()`, `typeName()`, the `isX()` predicates, the throwing `asX()` accessors,
the non-throwing `tryGetX()` accessors, `size()`, `empty()`, `find()`,
`operator[]` and `at()`.

Three members carry rules worth stating:

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `findPointer` | `const pf_JsonValue* findPointer(std::string_view pointer) const noexcept;` | "Resolve an RFC 6901 JSON Pointer. An empty pointer addresses this value. nullptr is returned for malformed pointers or missing targets" |
| `dump` | `std::string dump(int indent = 2) const;` | "Serialize deterministically. Object keys are emitted in lexical order. indent < 0 produces compact JSON; indent >= 0 produces pretty JSON" |
| `operator==` | `friend bool operator==(const pf_JsonValue& lhs, const pf_JsonValue& rhs) noexcept;` | structural equality |

`pf_Json` is the codec beside it, and every call returns `pf_Status`.

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `parse` | `static pf_Status parse(std::string_view input, pf_JsonValue& output, const pf_JsonParseOptions& options = pf_JsonParseOptions());` | "Parse strict JSON from memory" |
| `readFile` | `static pf_Status readFile(const std::string& fileName, pf_JsonValue& output, const pf_JsonParseOptions& options = pf_JsonParseOptions());` | "Parse a JSON file with a bounded size" |
| `writeFile` | `static pf_Status writeFile(const std::string& fileName, const pf_JsonValue& value, bool overwrite = true, bool atomicWrite = true, int indent = 2);` | write JSON to a file; when `atomicWrite` is true "a temporary sibling file is flushed first and then renamed into place" |
| `applyPatch` | `static pf_Status applyPatch(pf_JsonValue& target, const pf_JsonValue& patch, std::vector<std::string>* changedPointers = nullptr);` | "Apply an RFC 6902 JSON Patch transactionally to target" |
| `applyMergePatch` | `static pf_Status applyMergePatch(pf_JsonValue& target, const pf_JsonValue& patch, std::vector<std::string>* changedPointers = nullptr);` | "Apply RFC 7396 JSON Merge Patch to target" |
| `escapePointerToken` | `static std::string escapePointerToken(std::string_view token);` | "Escape one JSON Pointer token (RFC 6901)" |
| `decodePointer` | `static pf_Status decodePointer(std::string_view pointer, std::vector<std::string>& tokens);` | "Decode a JSON Pointer into unescaped tokens" |
| `contentHash` | `static std::string contentHash(const pf_JsonValue& value);` | "SHA-256 of deterministic compact JSON, returned as 64 lowercase hex digits" |

Parsing is bounded, and the bounds are visible to the caller.
`pf_JsonParseOptions` carries `maxInputBytes` (16 MiB), `maxDepth` (128),
`maxContainerEntries` (1,000,000) and `rejectDuplicateObjectKeys`, which
defaults to `true`.

## Content hashing

`pf_Hash` is two functions, described in its header as "Small, dependency-free
hashing helpers used by the generalized problem-input layer. Hashes are
lowercase hexadecimal strings."

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `sha256` | `std::string sha256(std::string_view input);` | "Return the SHA-256 digest of input as 64 lowercase hexadecimal digits" |
| `isSha256` | `bool isSha256(std::string_view value) noexcept;` | "True only for a canonical 64-character lowercase hexadecimal SHA-256" |

## The refusal surface

Every refusal is a `(code, pointer, message)` triple, and the code is the part a
program matches on. The authoring reference states the rule plainly: match on
the code, edit at the pointer, and "never key a repair on the message's wording,
which is human text and may be reworded between builds."

```
error [run_spec.count_required] /runSpec/count: Run mode 'counted' requires 'count'.
       ^ code                    ^ pointer      ^ message
```

Two gates produce codes. The **codec** is what `pf spec validate` runs; the
**reviewer** is the same with `--deep`, and it compiles the model. The codec runs
first, so a document it refuses never reaches the reviewer.

| Family | Gate | Pointer discipline | What it covers |
|---|---|---|---|
| `schema.*` | codec | the offending node | shape: required properties, types, enums, bounds, unknown properties, identifier patterns, hash format, unsupported and legacy versions |
| `topology.*` | codec | the node or boundary at fault | the tree: root, parents, cycles, reachability, levels, roles, downward paradigm uniformity, depth and edge bounds |
| `boundary.*` | codec | the boundary or one of its endpoints | one edge: paradigm/binding legality, the master- and subproblem-side services it requires, and two unsupported shapes |
| `coupling.*` | codec, two from the reviewer | the declaration | who owns what crosses: duplicate keys, ownership outside the boundary, unserializable symbols, and (reviewer) symbols that resolve on neither compiled side |
| `placement.*` | codec, one from the reviewer | the placement block | empty or nested `auto` lists; and the deep gate's requirement that placements be explicit |
| `run_spec.*` | codec | `/runSpec/...` | count and interval, each required by its mode and refused beside any other |
| `update.*` | codec, patch mode only | `/payload`, `/update/...`, or the node at fault | the payload's shape against `update.mode`; the `baseRevision` compare-and-swap guard and the runtime-summary match; the four changes refused against a running solve, and the note that records an `interrupt: always` waiver |
| `solver.*` | codec | the solver block | engine/role legality, guarantee fallbacks, ray capability, farm legality, certification sampling |
| `problem.*`, `results.*`, `catalog.*` | codec | the field named | integer recourse engines; `returnScopes` entries that name no node or no master; a catalog id that is not a stable id |
| `zimpl.*` | codec, then reviewer | the model source | first the marker and include rules the codec checks without compiling; then staging and compile failures, whose `cause=` token is the repair |
| `monolith.*` | reviewer, `--monolith` only | the node that decides the shape | the assembler has no rule for this shape and refuses rather than approximating it |
| `coverage.*` | reviewer | the topology node concerned | **informational, never a defect** |

Three classes of code are not defects and should not be repaired as if they
were.

A code whose suffix is `_not_executed` means the document is **valid** and states
something this build does not execute yet; the message names the pass that
retires the refusal. The authoring reference is emphatic about the wrong
response: "Never rewrite a ratchet refusal into an approximation of what was
asked for."

`coverage.unproven_shape` is an advisory. The definition is valid and
executable; one dimension of it has never been run end to end by a test lane.
The line begins `warning`, the exit status is unaffected, and it appears only
under `--deep`. Repairing it by editing the document toward a proven shape
"changes what you asked for in order to quiet a message that says nothing is
wrong."

Some `solver.*` codes are warnings rather than errors — a fallback engine stated
beside `action: refuse`, a seed beside a mode with nothing to randomize, a
`kind: gpu` assertion no document can settle.

Two reviewer codes deserve a reader's attention because they describe models
that compile and then answer the wrong question:
`zimpl.row_spans_two_children` and `zimpl.objective_leaks_sibling_columns` are
labelled **silent defect** in the authoring reference, because in each case the
model "solves a different problem and reports `optimal`".
