# Workbench reference

<!-- dc:status=polished dc:owner=DC2 -->

The Workbench is the `pf` command-line experience: a thin client speaking JSON
Lines over a Unix-domain socket to a resident `pf_Conductor`, which reaches the
runtime by executing the staged application. This page is the verb surface, with
a worked example for each major verb, and what a refusal looks like. The
documents the verbs operate on are described under
[Problem definitions](problem-definitions.md), field by field under
[Schemas](../reference/data/schemas.md).

The examples use the press-shop problem from the worked corpus
(`promptpack/examples/natural_language/flat_dw/`): a shop prices two assembly
lines, east and west, against one bottleneck press. Its problem id is
`pp_press_shop` and its hand-derived optimum is 11.0.

## The client and the conductor

`pf` decides two things on its own; everything else it asks the conductor.

**Autostart.** A missing socket is not an error. `pf` starts a conductor and
connects to it, and the conductor's lifetime is then its own — it detaches, and
this process exiting never takes it down, because a resident daemon whose life
is tied to whichever command happened to start it is not resident.
`--no-autostart` suppresses this, and the suppression is a stated failure rather
than a silent one.

**Ambiguity.** A catalog search returns a ranked list, always. A unique identity
match is used directly; anything else is prompted for when the session is
interactive, and failed with the candidate list printed when it is not. A script
that silently got whichever revision ranked highest is a script that will one
day run the wrong model.

The exit status is a small closed set: `0` the verb succeeded, `1` the conductor
answered with an error or could not be reached, `2` usage, `4` an ambiguous
selection in a non-interactive invocation.

The socket path is `$PF_CONDUCTOR_SOCK` when set, else
`$HOME/.plasticfog/conductor.sock`; `--socket` overrides it. `--json` is
available on every command and prints the reply's data verbatim, with object
keys in lexical order, so it is reproducible byte for byte from the same state.

## The verbs

Twenty-two protocol verbs, one protocol version, and an empty deferred-verb
list — this build defers no verb it has named, which is a stronger statement
than any non-empty list can make.

| Command | What it does |
|---|---|
| `pf ping` | liveness, pid, protocol version, catalog and application directory |
| `pf conductor stop` | stops the resident daemon, after the reply is written |
| `pf capabilities [--json]` | the capability document: engines, placement modes, run-spec modes, solver kinds |
| `pf promptpack build --mode <m>` | assembles the prompt pack for one input mode |
| `pf spec import\|show\|search\|validate\|diff\|export` | the catalog: immutable, content-hashed, parent-linked revisions |
| `pf run <app[@rev]>` | one submission, resolved and executed |
| `pf command pause\|resume\|stop` | a control command against a running problem |
| `pf status [--run ID]` | run status out of the catalog |
| `pf deploy plan\|start\|status\|stop` | the deployment planner and process supervisor |
| `pf campaign start\|status` | repeated execution under the document's `runSpec` |
| `pf results <app>\|--run ID` | the persistent results plane, queried or followed |
| `pf logs` | the log router |

### `pf ping`

    $ pf ping
    pong  pid <pid>  protocol v1
      socket   <socket path>
      catalog  <catalog path>
      app dir  <application directory>
      domain   <domain> / inforepo port <port>
      runs     <count>

The first line is the liveness answer; the rest is the conductor's own
configuration, which is what you check when a verb complains that this conductor
is not configured for something.

### `pf capabilities`

    $ pf capabilities

The capability document is **sourced, not stated**: it is produced from the
build's own codec and solver-engine registry rather than kept by hand. It lists
each engine with whether it is executable, the placement modes, the run-spec
modes and the solver kinds, each split into what is executable and what is
refused. It is the authority on what this build runs; where a table in this
documentation and the snapshot disagree, read the snapshot.

`--json` emits the same document machine-readably. That form is the one the
prompt pack carries, byte for byte.

### `pf spec import`

    $ pf spec import press_shop.problem.json --author you --note "first cut"
    imported pp_press_shop@1
      contentHash       <64 hex characters>
      validationStatus  valid   (as ingested; run `pf spec validate` for the authority)
      applicationId     <where the application id came from>
      storedSources     <count>
      unresolved        0

The catalog is append-only. Importing bytes identical to the parent revision's
records a new revision of the same content and says so, rather than overwriting
anything. The stored validation status is what the codec said when the bytes
were ingested, in whatever environment ran the import — which is why it is
labelled and why `pf spec validate` is the authority instead.

### `pf spec show`, `search`, `diff`, `export`

    $ pf spec show pp_press_shop@1 --view summary
    pp_press_shop@1
      title             <title>
      problemId         pp_press_shop
      contentHash       <64 hex characters>
      schemaVersion     pf.problem_definition.v1
      ...
      nodes/boundaries  3/2
      sources           <count>

The default view is `canonical`, and it sends the canonical document bytes to
standard output alone, with everything about them on standard error, so the
command is pipeable. `pf spec search <text>` prints ranked candidates with their
match kind and score. `pf spec diff <a@r1> <a@r2>` prints whether two revisions
are identical and the hunks between them. `pf spec export <a@r> --out <dir>`
writes the revision's files out and lists what it wrote.

### `pf spec validate`

    $ pf spec validate --file press_shop.problem.json --source-root .
    VALID  press_shop.problem.json
      authority  pf_App --dry-run (exit 0)

The verb's authority is the real binary on a path that creates no participant
and contacts no registry — not the catalog's stored status. Adding `--deep`
stages every compile unit the runtime would build and compiles it in process:

    $ pf spec validate --file press_shop.problem.json --source-root . --deep
    VALID  press_shop.problem.json
      authority  pf_App --dry-run --deep (exit 0)

`--no-advisories` suppresses `coverage.` informational items and only those.
When you drive the application directly instead of going through a conductor,
the same gate is `build/pf_App --problem <doc> --source-root <dir> --dry-run
--deep`, and there `--deep` requires `--dry-run`: the reviewer compiles the
staging plan, and the plan is what the dry-run path stops at.

### What a refusal looks like

A refused document prints `REFUSED`, a non-zero authority exit code, and one
line per refusal — each carrying a stable code and the exact JSON Pointer it
fired at:

    $ pf spec validate --file press_shop_discovered.problem.json --source-root . --deep
    REFUSED  press_shop_discovered.problem.json
      authority  pf_App --dry-run --deep (exit 4)
      error [placement.deep_requires_explicit] /topology/nodes/press_shop/services/priceMaster/placement: deep validation requires resolved service ids; this binding uses query placement -- make it explicit, or validate without --deep
      error [placement.deep_requires_explicit] /topology/nodes/line_east/services/priceSubproblem/placement: ...
      error [placement.deep_requires_explicit] /topology/nodes/line_west/services/priceSubproblem/placement: ...

That is the query-placed variant of the same press shop, and it is the shape of
a refusal worth recognising: one item per query-placed binding, and **no
`zimpl.` line anywhere in the report**, because the reviewer refused without
compiling anything. A report that refuses one thing and stays silent about
everything downstream of it is telling you the truth about how far it got.

Match on the code, edit at the pointer, and re-run both gates. Every code, its
pointer form and a one-line repair are in
[Problem input](../reference/api/problem-input.md);
[Workflow overview](workflow.md) covers the two gates and the order they run in.

### `pf run`

    $ pf run pp_press_shop@1 --wait 900
    run <run id>
      status       completed
      objective    11.0
      exit         0
      results      <run directory>/results.json
      correlation  <correlation id>

`--wait` bounds how long the client waits for the run; `--wait-services` bounds
how long it waits for the constellation to be ready. The objective line reads
`(not observed)` rather than a number when the run produced none, which is a
different fact from producing zero.

Submission executes the staged application as a child process rather than
calling a library in the daemon: a submission ends by shutting down its DDS
participant, which is process-global, so a resident daemon could serve exactly
one in-process submission ever.

### `pf command`

    $ pf command pause --target line_east --run <run id>
    pause -> line_east
      published     true
      acknowledged  1  (<acknowledgement semantics>)
      exit          0

The verbs are `pause`, `resume` and `stop`. `--target` names a node; without it
the command addresses the whole problem. The reply distinguishes **published**
from **acknowledged**, and names the acknowledgement semantics it is reporting
under, because a command that went out and a command that was taken up are
different facts.

### `pf status`

    $ pf status
    2 run(s)
      <run id>  completed  exit 0
      <run id>  failed     exit <code>

`--run <id>` narrows to one run.

### `pf deploy`

    $ pf deploy plan pp_press_shop@1 --profile local
    plan pp_press_shop@1  profile local
      problem      pp_press_shop  root press_shop
      domain       250 / inforepo port 12350
      infoRepo     spawn
      actions      6
        spawn  register [reg]
          readiness  process_banner, deadline 30s (banner 30s)
        spawn  priceSubproblem [sub1]  line_east/priceSubproblem
          readiness  registry_registration, deadline 60s (banner 30s)
        ...

`plan` prints exactly what `start` would execute and performs **no side
effects**: it starts no process, creates no directory, opens no model file and
touches no registry. An operator has to be able to read a deployment before
consenting to it, and a planning verb that consulted the registry could not be
run twice with the same answer.

Three action kinds come straight from the placement modes the document already
spells: an explicit placement becomes `attach`, a query becomes `discover`, a
spawn becomes `spawn`, and an ordered `auto` list becomes whichever alternative
wins. A binding with alternatives prints its fallback chain, each arm with the
reason it would be taken.

Every action carries **its own** readiness deadline, and a spawned process
carries two: one for its startup banner never appearing, one for the fact that
decides readiness never becoming true. The two failures need different next
steps, so a deadline that fires names its service:

    sub2 (pf_SubService) started but never registered with the Register service within 60s

Readiness is three kinds this build genuinely observes — a process banner, a
registry registration, and a registry query. There is deliberately no
service-status kind, because that channel was measured silent across a healthy
startup, and naming a kind the build cannot observe would be a plan claiming a
capability.

    $ pf deploy start pp_press_shop@1
    deployment <deploy id>
      owned      6
      discovered 0
      running  reg   register         pid <pid>
      running  sub1  priceSubproblem  pid <pid>
      ...

`pf deploy status` prints the same census later; `pf deploy stop` drains what
this deployment started, through TERM and then KILL, and reports what it left
running because it never started it. Processes this deployment does not own are
labelled as such and are not signalled.

### `pf campaign`

    $ pf campaign start pp_press_shop@1 --budget 3600

A **campaign** is the activation of one revision, executed to that revision's
`runSpec`; a **run** is one submit cycle inside it, with its own run id, its own
directory and its own row in the results plane. A plain `pf run` is a campaign
of exactly one run — not as a special case, but because an absent `runSpec` is
configured as mode `once` and the two paths are one path.

The scheduler is a pure decision engine. Modes are `once`, `counted`,
`continuous` and `interval`; overlap policy is `skip` or `queue`; stopping is by
count, by a run ceiling, by consecutive failures, or by the budget you passed.
The cadence grid is anchored at the campaign's origin rather than at each run's
end, so a cadence cannot drift by each run's duration. `pf campaign status
[--campaign ID]` reports where a campaign is.

### `pf results`

    $ pf results pp_press_shop
    $ pf results --run <run id> --follow
    $ pf results --run <run id> --export events.jsonl

A plain query and a follow are two verbs on the wire rather than one verb with a
flag, because they answer differently: a query returns rows, a follow streams
them as events from a resumable cursor. The client hides that; the protocol does
not blur it.

`--export` writes one JSON object per line — one line per result event and
nothing else, no header, no trailer, no summary object — so a consumer can
compare two exports without knowing which lines to skip.

Ingestion is document-granular: one row per envelope the run's own results
document carried, stored as the document carried it. No stream is simulated that
the documents do not support.

### `pf logs`

    $ pf logs --service sub1,sub2 --level warning --follow
    $ pf logs pp_press_shop@1 --terminal tmux

The log router fans in the streams the supervisor captured, labelled by service,
pid and UTC time. `--level` filters structured records only, `--terminal tmux`
presents them per service, and the default is genuinely silent. A positional
`app[@rev]` names the **policy** rather than the logs: the streams belong to the
deployment, and what the document contributes is the `observability` block that
says how they should be presented.

### `pf promptpack build`

    $ pf promptpack build --mode natural_language --out /tmp/pack.txt
    prompt pack  mode natural_language  packVersion 1.0.0
      root       <pack root>
      snapshot   capabilities/generated_capability_snapshot.json   REGENERATED
      ...
      TOTAL      <words> words, <bytes> bytes
      sha256     <64 hex characters>
      written to /tmp/pack.txt

Without `--out`, the pack goes to standard output and the report to standard
error, so a caller that pipes the pack somewhere gets the pack and nothing else.
The capability snapshot is regenerated from the build's own codec and
solver-engine registry before assembly, so a pack can never carry a capability
statement older than the build that answers for it.
[Authoring with an LLM](llm-authoring.md) covers what the pack contains and how
it is used.

## Errors

A verb that fails answers with a code from a closed vocabulary rather than
prose: `unknown_verb`, `version_mismatch`, `bad_request`, `not_found`,
`ambiguous`, `invalid_document`, `run_failed`, `unavailable`, `internal`.

`unavailable` earns its place beside `run_failed`: "this conductor was started
without a constellation to talk to" and "the submission failed" call for
completely different responses, and collapsing them into one code would make the
first look like the second.

An error may attach detail — `ambiguous` attaches its candidates, `run_failed`
attaches the run record — but detail may never rewrite the code or the message,
so a reply cannot lie about what kind of failure it is.
