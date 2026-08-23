# Test index

<!-- dc:status=polished dc:owner=DC4a -->

Every test in the suite has a page. This one lists them: forty unit tests in the
first table, thirty-two end-to-end lanes in the second, with the CTest name and
labels where they exist and a one-line statement of what each covers.

The counts and the arithmetic that connects them are reconciled at the foot of
the page, because two of the columns below do not add up to the same number and
the reason is worth knowing.

## Unit tests

| Page | Source | CTest name | Labels | What it covers |
|---|---|---|---|---|
| [pf_BendersCuts_Tests](unit/benderscuts.md) | `tests/unit/pf_BendersCuts_Tests.cpp` | `pf_BendersCuts` | `unit;fast;public` | The Benders cut objects and the arithmetic that builds them. |
| [pf_BendersMaster_Tests](unit/bendersmaster.md) | `tests/unit/pf_BendersMaster_Tests.cpp` | `pf_BendersMaster` | `unit;fast;public` | The Benders loop itself: master and children in one process, through the same entry points the services use. |
| [pf_BlockPlan_Tests](unit/blockplan.md) | `tests/unit/pf_BlockPlan_Tests.cpp` | `pf_BlockPlan` | `unit;fast;public` | The block plan that partitions a compiled master model into per-child blocks. |
| [pf_Catalog_Tests](unit/catalog.md) | `tests/unit/pf_Catalog_Tests.cpp` | `pf_Catalog` | `unit;fast;public` | The append-only revision store: immutability, hash determinism, exact round trip, ranked search. |
| [pf_ColumnVerifier_Tests](unit/columnverifier.md) | `tests/unit/pf_ColumnVerifier_Tests.cpp` | `pf_ColumnVerifier` | `unit;fast;public` | The pure arithmetic that decides whether a proposed column may be admitted. |
| [pf_Commands_Tests](unit/commands.md) | `tests/unit/pf_Commands_Tests.cpp` | `pf_Commands` | `unit;fast;public` | The DDS command collection: ownership, deep copy, and publication. |
| [pf_Conductor_Tests](unit/conductor.md) | `tests/unit/pf_Conductor_Tests.cpp` | `pf_Conductor` | `unit;fast;public` | The resident daemon: its verbs, its run registry, and the ingestion of a run’s results document. |
| [pf_Conductor_LogRouter_Tests](unit/conductor-logrouter.md) | `tests/unit/pf_Conductor_LogRouter_Tests.cpp` | `pf_Conductor_LogRouter` | `unit;fast;public` | The log router: labelling, level filtering, and its silent default. |
| [pf_Conductor_RunScheduler_Tests](unit/conductor-runscheduler.md) | `tests/unit/pf_Conductor_RunScheduler_Tests.cpp` | `pf_Conductor_RunScheduler` | `unit;fast;public` | The run scheduler as a pure decision engine: modes, overlap, stop conditions, warm start. |
| [pf_Conductor_Supervisor_Tests](unit/conductor-supervisor.md) | `tests/unit/pf_Conductor_Supervisor_Tests.cpp` | `pf_Conductor_Supervisor`, `pf_Conductor_Supervisor_Probe` | `unit;integration;public` | The deployment supervisor: start order, process identity, drain, census. Registered twice, once per half. |
| [pf_DeepCheck_Tests](unit/deepcheck.md) | `tests/unit/pf_DeepCheck_Tests.cpp` | `pf_DeepCheck` | `unit;fast;public` | The compile-diagnostic classifier, plus the guard that holds the coverage table and its tracked copy together. |
| [pf_EngineCuOpt_Loader_Tests](unit/enginecuopt-loader.md) | `tests/unit/pf_EngineCuOpt_Loader_Tests.cpp` | `pf_EngineCuOpt_Loader` | `unit;fast;public` | The GPU adapter’s loading decision, pinned against stub libraries rather than a device. |
| [pf_EngineHighs_MathGate_Tests](unit/enginehighs-mathgate.md) | `tests/unit/pf_EngineHighs_MathGate_Tests.cpp` | `pf_EngineHighs_MathGate` | `unit;fast;public` | The orientation of the duals and rays a newly seamed engine returns. |
| [pf_EngineHighs_Parity_Tests](unit/enginehighs-parity.md) | `tests/unit/pf_EngineHighs_Parity_Tests.cpp` | `pf_EngineHighs_Parity` | `unit;fast;public` | That engine against the others on the same models. |
| [pf_FailurePolicy_Tests](unit/failurepolicy.md) | `tests/unit/pf_FailurePolicy_Tests.cpp` | `pf_FailurePolicy` | `unit;fast;public` | Missing-subproblem policy resolution, including its precedence chain. |
| [pf_Graph_Tests](unit/graph.md) | `tests/unit/pf_Graph_Tests.cpp` | `pf_Graph` | `unit;fast;public` | The problem graph and its map: modules, identifiers and serialization. |
| [pf_MidPricing_Tests](unit/midpricing.md) | `tests/unit/pf_MidPricing_Tests.cpp` | `pf_MidPricing` | `unit;fast;public` | The column a mid returns to its parent, checked against a fixture rather than left to a runtime signal that does not exist. |
| [pf_MonolithAssembler_Tests](unit/monolithassembler.md) | `tests/unit/pf_MonolithAssembler_Tests.cpp` | `pf_MonolithAssembler` | `unit;fast;public` | Assembly of the independent monolith oracle, rule by rule. |
| [pf_Mps2English_Tests](unit/mps2english.md) | `tests/unit/pf_Mps2English_Tests.cpp` | `pf_Mps2English` | `unit;fast;public` | Readable rendering of a solved model, as a characterisation test over harvested goldens. |
| [pf_ProblemInput_Tests](unit/probleminput.md) | `pf_ProblemInput_Tests.cpp` | `pf_problem_input` | *(none)* | The problem-definition codec: parsing, semantic validation, canonical form and round trip. |
| [pf_ProblemInput_Adversarial_Tests](unit/probleminput-adversarial.md) | `pf_ProblemInput_Adversarial_Tests.cpp` | `pf_problem_input_adversarial` | *(none)* | Malformed and hostile documents against the same codec, each refusal pinned by code and pointer. |
| [pf_RefusalInventory_Tests](unit/refusalinventory.md) | `tests/unit/pf_RefusalInventory_Tests.cpp` | `pf_RefusalInventory` | `unit;fast;public` | The refusal inventory: every capability this build refuses, by name. |
| [pf_RefusalInventory_Engines_Tests](unit/refusalinventory-engines.md) | `tests/unit/pf_RefusalInventory_Engines_Tests.cpp` | `pf_RefusalInventory_Engines` | `unit;fast;public` | The engine-related half of that inventory. |
| [pf_RefusalInventory_Workbench_Tests](unit/refusalinventory-workbench.md) | `tests/unit/pf_RefusalInventory_Workbench_Tests.cpp` | `pf_RefusalInventory_Workbench` | `unit;fast;public` | The workbench-related half of that inventory. |
| [pf_ReplyTable_Tests](unit/replytable.md) | `tests/unit/pf_ReplyTable_Tests.cpp` | `pf_ReplyTable` | `unit;fast;public` | Whether an arriving subproblem reply belongs to an outstanding request, and which block it routes to. |
| [pf_ResourceDrive_Tests](unit/resourcedrive.md) | `tests/unit/pf_ResourceDrive_Tests.cpp` | `pf_ResourceDrive` | `unit;fast;public` | How a module’s attributes become resource-directed boundaries, and how their names resolve. |
| [pf_ResourceEnvelope_Types_Tests](unit/resourceenvelope-types.md) | `tests/unit/pf_ResourceEnvelope_Types_Tests.cpp` | `pf_resource_envelope_types` | *(none)* | The resource envelope types and their serialization. |
| [pf_ResponseTable_Tests](unit/responsetable.md) | `tests/unit/pf_ResponseTable_Tests.cpp` | `pf_ResponseTable` | `unit;fast;public` | The resource-directed counterpart to the reply table, concentrating on the rejection paths. |
| [pf_Results_Types_Tests](unit/results-types.md) | `pf_Results_Types_Tests.cpp` | `pf_results_types` | *(none)* | The results envelope: round trip, malformed input, and the provenance arrays. |
| [pf_ServiceIdManager_Tests](unit/serviceidmanager.md) | `tests/unit/pf_ServiceIdManager_Tests.cpp` | `pf_ServiceIdManager` | `unit;fast;public` | Reading and assigning service identifiers. |
| [pf_ServicesRepo_Tests](unit/servicesrepo.md) | `tests/unit/pf_ServicesRepo_Tests.cpp` | `pf_ServicesRepo` | `unit;fast;public` | The services repository: registration, retrieval and structured query. |
| [pf_ServicesRepo_Schema_Tests](unit/servicesrepo-schema.md) | `tests/unit/pf_ServicesRepo_Schema_Tests.cpp` | `pf_regdb_schema` | `unit;fast;public` | The registry database schema and its frozen rows. |
| [pf_SolverEngine_Tests](unit/solverengine.md) | `tests/unit/pf_SolverEngine_Tests.cpp` | `pf_SolverEngine` | `unit;fast;public` | The engine seam: selection, capability facts, and what each engine may be asked for. |
| [pf_SolverStateMachine_Tests](unit/solverstatemachine.md) | `tests/unit/pf_SolverStateMachine_Tests.cpp` | `pf_SolverStateMachine` | `unit;fast;public` | Both solver state machines, against the tracked transition table. |
| [pf_SpeculationPrng_Tests](unit/speculationprng.md) | `tests/unit/pf_SpeculationPrng_Tests.cpp` | `pf_SpeculationPrng` | `unit;fast;public` | The two deterministic draw streams speculative farming uses. |
| [pf_StagingPlan_Tests](unit/stagingplan.md) | `tests/unit/pf_StagingPlan_Tests.cpp` | `pf_StagingPlan` | `unit;fast;public` | The staging plan: which compile unit each service receives. |
| [pf_VerbAttachment_Tests](unit/verbattachment.md) | `tests/unit/pf_VerbAttachment_Tests.cpp` | `pf_VerbAttachment` | `unit;fast;public` | Which commands attach to which module, by role. |
| [pf_ZimplCompiler_Tests](unit/zimplcompiler.md) | `tests/unit/pf_ZimplCompiler_Tests.cpp` | `pf_ZimplCompiler` | `unit;fast;public` | The Zimpl compiler seam. |
| [pf_ZimplRegistry_Tests](unit/zimplregistry.md) | `tests/unit/pf_ZimplRegistry_Tests.cpp` | `pf_ZimplRegistry` | `unit;fast;public` | The source registry and the artifact cache: ingestion, pinning, eviction, single-flight compilation. |
| [pf_ZimplStaging_Tests](unit/zimplstaging.md) | `tests/unit/pf_ZimplStaging_Tests.cpp` | `pf_ZimplStaging` | `unit;fast;public` | Staging of model sources into the units that are compiled. |

## End-to-end lanes

| Page | Lane | Invocation | CTest name | What it covers |
|---|---|---|---|---|
| [l1-scenario-pf001](e2e/l1-scenario-pf001.md) | `L1` | `tests/e2e/run_scenario.sh --scenario pf001` | `pf_e2e_pf001` | The legacy demo path on the separable baseline scenario. |
| [l2-scenario-pf002](e2e/l2-scenario-pf002.md) | `L2` | `tests/e2e/run_scenario.sh --scenario pf002` | `pf_e2e_pf002` | The legacy demo path on the contended scenario — the value only real distributed coordination reaches. |
| [l3-generalized](e2e/l3-generalized.md) | `L3` | `tests/e2e/run_generalized.sh` | — | The generalized path: a problem definition projected, submitted, and answered over the wire. |
| [l4-reuse](e2e/l4-reuse.md) | `L4` | `tests/e2e/run_reuse.sh` | — | Durable reuse: one constellation, two campaigns, a published graph reused. |
| [l5-scenario-pf002-degrade-sub2](e2e/l5-scenario-pf002-degrade-sub2.md) | `L5` | `tests/e2e/run_scenario.sh --scenario pf002 --degrade sub2 --degrade-mode pre-solve` | — | A subproblem killed after its first real reply — degradation recorded rather than absorbed. |
| [l6-scenario-pf002-omit-sub2](e2e/l6-scenario-pf002-omit-sub2.md) | `L6` | `tests/e2e/run_scenario.sh --scenario pf002 --omit sub2 --mode unavailable` | — | A subproblem never launched — the services-unavailable fast fail, asserted as a process exit. |
| [l7-nested](e2e/l7-nested.md) | `L7` | `tests/e2e/run_nested.sh` | — | The nested topology: one node that is a subproblem to its parent and a master to its own children. |
| [l8-resource](e2e/l8-resource.md) | `L8` | `tests/e2e/run_resource.sh` | — | Resource-directed decomposition, flat. |
| [v1-nested-command-variant](e2e/v1-nested-command-variant.md) | `V1` | `tests/e2e/run_nested.sh --command-variant 1` | — | The nested topology driven through control-plane commands. |
| [v2-nested-update-lane](e2e/v2-nested-update-lane.md) | `V2` | `tests/e2e/run_nested.sh --update-lane` | — | A spot update applied against a running system. |
| [v3-resource-degrade-robot-b](e2e/v3-resource-degrade-robot-b.md) | `V3` | `tests/e2e/run_resource.sh --degrade robot_b` | — | The resource lane with a child degraded — the failure that must be loud. |
| [v4-nested-mixed-lane](e2e/v4-nested-mixed-lane.md) | `V4` | `tests/e2e/run_nested.sh --mixed-lane` | — | Mixed composition: a price-directed root over a resource-directed mid. |
| [v5-nested-mixed-degrade](e2e/v5-nested-mixed-degrade.md) | `V5` | `tests/e2e/run_nested.sh --mixed-lane --mixed-degrade robot_r1` | — | The mixed shape with a resource child degraded, so the composed failure chain resolves. |
| [v6-nested-degrade-substitute](e2e/v6-nested-degrade-substitute.md) | `V6` | `tests/e2e/run_nested.sh --degrade C1 --degrade-mode pre-solve --degrade-policy substitute` | — | A failure beneath the mid, resolved by the substitute policy. |
| [v7-nested-degrade-abort](e2e/v7-nested-degrade-abort.md) | `V7` | `tests/e2e/run_nested.sh --degrade C1 --degrade-mode pre-solve --degrade-policy abort` | — | The same failure under the abort policy — aborted at both levels. |
| [v8-nested-scopes-lane](e2e/v8-nested-scopes-lane.md) | `V8` | `tests/e2e/run_nested.sh --scopes-lane` | — | Per-master results return: a named node reports its own scope. |
| [w1-workbench](e2e/w1-workbench.md) | `W1` | `tests/e2e/run_workbench.sh` | — | The front end end to end: submit through the conductor and get an answer back. |
| [w2-workbench-spawn](e2e/w2-workbench-spawn.md) | `W2` | `tests/e2e/run_workbench.sh --scenario wb-spawn` | — | A submission whose placements ask for processes to be started. |
| [w3-workbench-discover](e2e/w3-workbench-discover.md) | `W3` | `tests/e2e/run_workbench.sh --scenario wb-discover` | — | A submission that discovers its services, against a pre-started constellation. |
| [w4-workbench-auto](e2e/w4-workbench-auto.md) | `W4` | `tests/e2e/run_workbench.sh --scenario wb-auto` | — | A submission whose placement offers an ordered list of alternatives. |
| [w5-workbench-repeat](e2e/w5-workbench-repeat.md) | `W5` | `tests/e2e/run_workbench.sh --scenario wb-repeat` | — | A repeated campaign: counted then interval, with the warm start carried. |
| [w6-workbench-continuous](e2e/w6-workbench-continuous.md) | `W6` | `tests/e2e/run_workbench.sh --scenario wb-continuous` | — | A continuous campaign bounded by a run ceiling, with one injected failing run. |
| [w7-workbench-results](e2e/w7-workbench-results.md) | `W7` | `tests/e2e/run_workbench.sh --scenario wb-results` | — | The replay-equality check over a run that returned per-master scopes. |
| [w8-workbench-logs](e2e/w8-workbench-logs.md) | `W8` | `tests/e2e/run_workbench.sh --scenario wb-logs` | — | The log router over a scenario that spawns, because the router carries the supervisor’s captured streams. |
| [e1-engines-all](e2e/e1-engines-all.md) | `E1` | `tests/e2e/run_engines.sh --lane all` | — | The default CPU engine matrix — seven engine lanes in one invocation. |
| [z1-zimpl-cli-pf001](e2e/z1-zimpl-cli-pf001.md) | `Z1` | `ZIMPLCLI tests/e2e/run_scenario.sh --scenario pf001` | — | The baseline scenario repeated on the alternative Zimpl backend. |
| [k1-engines-pfe006-k1](e2e/k1-engines-pfe006-k1.md) | `K1` | `tests/e2e/run_engines.sh --lane pfe006-k1` | — | The speculative-farming baseline: no farm anywhere, and the control that proves defaults are off. |
| [f1-engines-pfe006-farm](e2e/f1-engines-pfe006-farm.md) | `F1` | `tests/e2e/run_engines.sh --lane pfe006-farm` | — | The same fixture with a column farm on both children. |
| [d1-engines-pfe006-debt](e2e/d1-engines-pfe006-debt.md) | `D1` | `tests/e2e/run_engines.sh --lane pfe006-debt` | — | Proof debt under a terminal-only certification policy. |
| [s1-engines-pfe006-sampled](e2e/s1-engines-pfe006-sampled.md) | `S1` | `tests/e2e/run_engines.sh --lane pfe006-sampled` | — | Certification sampled per claim, with the terminal override. |
| [x1-engines-pfe006-escalate](e2e/x1-engines-pfe006-escalate.md) | `X1` | `tests/e2e/run_engines.sh --lane pfe006-escalate` | — | Audit failure and escalation, asserted as theorems rather than as a schedule. |
| [i1-inline](e2e/i1-inline.md) | `I1` | `tests/e2e/run_inline.sh` | — | A fully inline document: no external model or data file at all. |

Labels apply to CTest names, so only the two registered lanes carry any: both
`pf_e2e_pf001` and `pf_e2e_pf002` are labelled `integration;distributed;public`.
The other thirty lanes are run by the matrix driver rather than by CTest and
have no labels to carry.

## Making the counts add up

Three numbers describe this suite, and they are not the same number.

| Thing | Count |
|---|---:|
| CTest test names | 50 |
| Unit-test source files | 40 |
| End-to-end lanes | 32 |

**Fifty CTest names**, registered in `CMakeLists.txt`. Forty-one are driven by a
C++ test binary; nine are driven by a shell script.

**Forty-one binary-driven names over forty source files.** Every unit-test source
has exactly one CTest name, with one exception:
`tests/unit/pf_Conductor_Supervisor_Tests.cpp` is registered twice, once per
half, because the binary takes a flag that selects which half runs. That is
41 = 40 + 1, and it is why the supervisor row above carries two names.

**The nine script-driven names are not nine lanes.** They are the two legacy
scenario lanes, the prompt-pack conformance lane, the two staging-parity checks,
the monolith-oracle sweep, the deep-adversarial inventory, the deep validation
sweep, and the document lane.

**Only two of the thirty-two lanes are registered with CTest.** The other thirty
are driven by the matrix driver, which reads `tests/tools/lanes.txt` and runs
each invocation in turn. A lane needs a live constellation and an isolated DDS
domain, so registering all of them as ordinary tests would make an ordinary
`ctest` run try to start thirty constellations at once. How the matrix is driven,
and what `--lane all` means, is on
[Test harness & fixtures](harness.md).

Forty unit pages plus thirty-two lane pages are the seventy-two detail pages this
section carries.

One further figure appears on [Philosophy & methodology](../index.md): 553
`assert(` occurrences across the forty unit sources. It is a lower bound on cases
rather than a count of them — one test function commonly asserts several
independent facts — and it excludes the end-to-end assertions entirely.
