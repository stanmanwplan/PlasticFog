# Authoring with an LLM

<!-- dc:status=polished dc:owner=DC2 -->

Writing a problem definition by hand is possible and most people should not.
This page covers the model-assisted routes: what the prompt pack is and how you
build it, what the agent skill tells a coding agent to do, and the protocol by
which generated definitions are evaluated.

One property frames all of it. **Nothing in this repository calls a language
model** — not a test, not a tool, not a lane. A conformance lane searches the
pack and its tests for the shapes a model call takes and fails if it finds one.
The pack is text that a person or an agent gives to a model somewhere else; the
scorer scores what comes back and calls nothing.

## The prompt pack

A **prompt pack** is a model-neutral bundle of text that a caller loads before
asking a model to turn a problem into a PlasticFog document. There is one bundle
per input mode, and you pick the mode from what you are holding:

| Mode | You are holding | It emits |
|---|---|---|
| `natural_language` | prose — a description of the business problem, no formulation | `pf.problem_definition.v1` |
| `mathematical_form` | a written formulation: sets, parameters, variables, objective, constraints | `pf.problem_definition.v1` |
| `foreign_aml` | a model in another algebraic modelling language | `pf.problem_definition.v1` |
| `legacy_zimpl` | a flat Zimpl model you already run under one solver | `pf.problem_definition.v1` |
| `patch` | a change to a definition that is already submitted | `pf.problem_update.v1` |

Build it and paste it in front of your request:

    pf promptpack build --mode natural_language --out /tmp/pack.txt

A pure-script assembler produces the same bundle with no C++ build at all, and
the conformance lane asserts that the two paths are byte-identical, so the
script is not a lesser copy.

Every mode loads the same core protocol, the same two response schemas, the same
generated capability snapshot and the same repair protocol; the mode file and
its worked examples are what differ. The manifest states each mode's component
list in full and in assembly order, repeating the shared components rather than
factoring them out — what a mode contains is what the manifest says, line by
line, with no implicit prefix a reader has to hold in their head.

### What the core carries

Two of the core's rules are what the pack is for.

**Mechanical validation is the authority, and the model proposes.** The pack
never asks a model to certify its own output. Every document it produces is
checked by the validator, whose verdict is final and whose error codes are the
repair vocabulary. A pack that told a model to "make sure the document is valid"
would be asking for a claim, and a claim is exactly what a validator exists to
replace.

**Never invent a capability absent from the snapshot.** The capability snapshot
is regenerated from the live registry every time the pack is built, so it can
never be older than the build that answers for it, and it is the complete list
of what this build executes. A model asked for something it does not carry
answers `unsupported`, naming the capability and quoting the field it checked —
rather than producing a document that validates and is refused at submit, a
round trip through the whole system to learn something the snapshot said up
front.

The core also carries a **clarification policy** rather than a ban on asking:
named categories where a question is legitimate, a cap on how many questions one
round may carry, and three assumption modes so the caller decides whether
questions are allowed at all. A blanket ban on asking produces confident
documents built on guesses, which is the most expensive failure available to a
modelling assistant.

### The response is one JSON object

The model answers with a **response envelope** — never prose around it, never a
markdown fence — conforming to a schema shipped with the pack:

| Field | What it carries |
|---|---|
| `response_type` | `problem_spec_candidate`, `patch_candidate`, `clarification_request`, or `unsupported` |
| `request_id` | echoed verbatim from the caller, never invented |
| `assumptions[]` | every choice made that the user did not state |
| `warnings[]` | everything the user should know that did not stop the response |
| `payload` | the document, the update, or the questions — the shape follows the type |

A clarification question is itself schema-shaped: a stable question id, the
question, why it matters, optional closed choices, a suggested default, and
whether it is blocking.

**A proposed decomposition always appears in `assumptions[]`** — whether the
model derived it, was hinted at it, or read it out of the source. It is the one
choice the user cannot check by reading the document, because the document is
written in terms of the decomposition rather than about it.

### The worked examples

`promptpack/examples/` holds ten worked triples, each a request, the response
envelope, and the document the envelope carries. They cover the shapes this
build executes — flat price, nested price with a mid, flat resource, and the
mixed shape — plus two that teach a field rather than a shape: the engine role
table, and the interaction between placement and the deep gate.

Every golden is all-inline, so each is one JSON file with nothing beside it. The
one exception is a rule rather than a lapse: the nested-price golden carries its
mid's own child ids as a file, because that name is fixed and the document-wide
collection already claims it.

Every golden is validated on every test run, and the conformance target
additionally asserts that the document inside each envelope is the same document
as the file beside it — because a copy is a thing that drifts, and a pack that
shipped an envelope teaching a document no lane ran would be the same class of
defect one level down.

## Pointing an agent at the skill

If you work inside a coding agent, the repository carries a skill file written
for one. **It is opt-in by path**: it becomes active because you say "follow
this file", and it stops being active the moment you stop saying so. There is no
root instruction file in the repository and none is created, so nothing directs
an agent that was not pointed at it.

The skill tells the agent to do the loop and to stop:

1. **Build the pack** for the mode that matches what you handed it, and read the
   whole pack before drafting.
2. **Draft the envelope** and save it to a file before validating anything, so
   every later step reads from that file and you can see it.
3. **Run the two gates in order** — the codec, then the deep gate — against the
   extracted document.
4. **Read the report**: match on the code, edit at the pointer, and use the
   `cause=` token on a compile failure to choose the repair. Treat `coverage.`
   items as informational and do not repair them.
5. **Repair at most three times**, saving every attempt and every report beside
   it, and re-running *both* gates after each repair.
6. **Run the agreement protocol only if you asked for a run**, because it starts
   a private constellation of services.
7. **Stop, and show you** the envelope, the verdicts it actually ran quoted, the
   attempts in order, and anything it could not clear, named by code and pointer.

Three prohibitions are stated as plainly as the steps. The agent may not edit
the pack — the pack is the input to the work, not part of the deliverable. It
may not claim a verdict it did not run: "valid", "deep-valid" and "agrees" are
things a command printed, and every one of them is quotable. And it does not
call a model on the repository's behalf: the agent *is* the model, and adding a
network call, a client library or a key is what the conformance lane turns red
on.

The stopping rule is deliberate. If a fourth attempt would still be needed, the
agent stops and hands you the last attempt, the last report, and a plain
sentence saying which code it could not clear — because a guessed repair that
produces a second refusal costs a round and teaches nothing.

## How generated definitions are evaluated

The pack's own effectiveness is measured by a written protocol, run by a person,
outside the repository. It asks one question, and the question is answerable:

> Does a model, given the pack's exact bytes and one request, produce a
> definition that passes the codec, passes the deep gate, and agrees with its
> own monolith when run?

Three verdicts, each from a command — the codec gate, the deep gate, and the
agreement protocol — plus one number no command can produce: the **hand
oracle**. Where a request's oracle is derivable by hand, the request carries it,
and a run that agrees with its own monolith but not with the oracle is a
candidate that modelled the wrong problem. That is the most expensive failure
available, and it is why the requests carry oracles at all.

### The rules that make a score mean something

**Record the pack digest and the repository commit.** A pack is a moving
artifact — the capability snapshot is regenerated on every build — so a score
without a digest is a score about nothing in particular.

**One request, one fresh context, discarded afterwards.** No system prompt of
the runner's own, no preamble, no coaching, and no carry-over between requests.
A model that has already seen three of these requests is not the model the pack
was written for. This is the single rule most likely to be broken by accident,
and a cell whose context was not fresh is discarded rather than reported with a
caveat.

**The input is the pack's exact bytes plus the request body, and nothing else.**
Each held-out request file carries a header, a statement of what a correct
answer must contain, the oracle, and what the scorer will check — and none of
that is sent. Those are the answer key. The request is not paraphrased, its
typos are not fixed, and no "please return JSON" is appended: the pack already
says what the response protocol is, and whether the model follows it is part of
what is being measured.

**The raw response is saved verbatim.** If the model wrapped its JSON in a
markdown fence or wrote prose around it, that is saved too. The pack says a
response is one JSON object with nothing around it, so a fenced answer is a
finding, and stripping it would delete the measurement. **No human ever edits a
candidate** — not to fix a comma, not to remove a fence. An edited candidate is
a candidate the model did not produce, and a score over edited candidates
measures the editor.

**At most three repairs, so at most four attempts per request.** The report is
fed back verbatim, in the same conversation, with no commentary of the runner's
own — not "you got X wrong", not "try changing Y". The repair protocol in the
pack is what tells the model how to read a report, and whether it can is part of
what is being measured. A request with no deep-valid attempt at the fourth is
recorded as a failure there and left there: no fifth round, no hint, no restart.
The bounded-retry contract belongs to the caller, and in the protocol the runner
is the caller.

**A generator is a configuration, not a vendor.** Each generator directory
records the model and its version string, the interface it was driven through,
every setting that was not the default, the date, and the pack digest. The same
model at two temperatures is two generators and gets two directories.

**An `agree=no` is not automatically the candidate's fault.** The lane prints
the diagnosis itself: if the monolith reproduces the oracle and the run does
not, that is a runtime limit of this build rather than a modelling error, and
the protocol requires recording which side of the diagnosis each disagreement
fell on. A report that counted a known runtime limit as a model result would be
reporting the wrong thing.

### What the numbers will and will not describe

The scorer produces one table and one histogram. They describe how often a model
given this pack produces a structurally valid envelope, how often that envelope
carries a document the codec accepts, how often the reviewer accepts it, how
many rounds of fed-back report it takes, **which codes** the failures land on —
the actionable half, since a code that dominates the histogram is a place the
pack's text is not doing its job — and, where a constellation was available, how
often the decomposition agreed with its own monolith.

They do not describe whether the model wrote the problem the request *meant*:
deep-valid is compile-and-stage, and agreement says the decomposition solved the
problem the candidate wrote. Only the hand oracle catches a candidate that
modelled the wrong thing, and only where an oracle is derivable.

They are not a ranking of models. They are a fact about one pack version, one
build and one held-out request set, which is why the digest is recorded. Most
cells of that set hold a single request, and a cell of one is an observation
rather than a rate.

And they say nothing about whether the pack earns its length. The protocol holds
the pack fixed and measures whether it works; a minimization study would vary
it, and that is a different study.

!!! note
    The cross-model evaluation is in progress. Its results will be published;
    nothing about them is stated here or elsewhere on this site.
