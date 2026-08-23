# Engineering practices

<!-- dc:status=polished dc:owner=DC4a -->

This page describes the mechanisms behind the claims the rest of this
documentation makes: how an answer is checked against something other than the
system that produced it, what has to be green before a change is kept, what gets
audited without being touched, and who is allowed to commit.

The thread running through all of them is a preference for evidence over
assertion. Where a claim could be either measured or stated, it is measured, and
where it cannot be measured yet, the gap is written down.

## An answer is checked against an independent oracle

**A decomposition that agrees with itself proves nothing.** Every end-to-end lane
compares the objective a run reports against a number, and if that number came
from the same reasoning that produced the model, the comparison is circular.

The answer is a monolith: the whole problem written out as one model — master
plus every child, the decomposition's internal variables removed, linking columns
renamed through the boundary's own declarations — then compiled with the vendored
Zimpl and solved with a CPU solver, cross-checked on a second one. The assembler
that produces it is deliberately inert: it is "a CHECK, not a repair", no part of
the runtime is aware it exists, and running it changes no behaviour.

The method began as a hand exercise on four disputed cases and then became a
tool. All four printed the hand-derived oracle, "and every disagreement turned
out to be the runtime's" — which is the point of an independent check: it can
only find something if it is capable of disagreeing with the thing it checks. A
user can run the same comparison on their own document and gate on it, and one of
the registered tests runs it across every document in the tree that carries a
recorded oracle.

Nesting made the check sharper rather than weaker. Assembling a nested price
document from the root's compile unit alone does not reach the known objective;
assembling it from every master's unit does. That was measured rather than
assumed, and it is now a rule of the assembler.

### Wrong, well-formed, and labelled optimal

The failure this project treats as the worst is not a crash. It is an answer that
is well-formed, plausible, and wrong — reported as `optimal`, with nothing in the
output to suggest otherwise.

Several mechanisms exist specifically to catch that class:

- Two authoring rules are labelled **silent defect** by the validator, because a
  model that breaks either compiles cleanly and then "solves a different problem
  and reports `optimal`": a coupling row that silently attaches to only one of
  the two children it names, and an objective that leaks a sibling's columns
  because its guard is missing.
- An integer column in a resource subproblem is refused by name, because every
  cut from that subproblem comes from LP duality — "an integer column makes the
  cuts invalid rather than weak — and an invalid cut is adopted as a constraint
  and the answer reported as optimal."
- One failure policy is refused outright on a resource boundary: the master holds
  no copy of the child's recourse model, so a manufactured substitute "would
  either exclude feasible allocations or bound nothing, and both would be
  reported as optimal." The resource default is abort instead, which is why
  pausing a resource-directed child ends its parent's solve.
- A degraded or substituted pricing path never changes the solve status. The
  status "is a mathematical claim about the model that was actually solved";
  what happened to a block is recorded separately, so that a caller can always
  tell a fully distributed answer from one that was partly solved centrally.

### An oracle disagreement is a finding, not a failure to fix

The rule the project states in one line: **an oracle a runtime disagrees with is
a finding to stop on with both numbers, and an assertion adjusted to fit a
runtime is a fabrication.**

The tool that runs an arbitrary document end to end is built around that rule. It
asserts everything that is true of any correct run — the exit code, the presence
of an envelope, an optimal status, distributed pricing, no rejected command — and
it **reports** the oracle comparison rather than asserting it. The reasoning is
recorded beside the code: "A disagreement is a FINDING for the review. An assert
that failed on it would invite editing the golden to go green, which is the one
thing this pass must not do."

## A claim is verified, not asserted

"Zero new warnings" is a claim that is easy to make and easy to get wrong. The
reliability audit made it a measurement instead, by running three full clean
builds: the edited tree, then the pristine baseline restored and rebuilt, then
the edits restored and rebuilt again. Warnings were filtered to this repository
alone and normalized to strip line and column numbers, so that code moving down a
file does not register as a change. The result was reported as a table with a
before and an after column: five warnings became three, two eliminated, none
introduced.

The same audit rebuilt every target from clean — 172 objects, five executables,
exit 0 — and separately configured the transport-free schema library on its own
and ran its tests, because a library that claims to build without the runtime
installed should be built that way at least once.

### Byte stability, proved rather than promised

The rule for schema growth is that byte stability is the default: "Every additive
field is emitted only when set, so a document produced before the field existed
is produced identically after."

That is provable, and it is proved. Every problem document in the fixtures and
the examples is canonicalized before a schema change and again after, and the two
outputs are byte-compared, along with every content hash. A pass whose additions
moved those bytes "would be a runtime change wearing a schema pass's clothes",
because a content hash is an identity that other things in the system are keyed
on.

Inside a block the rule inverts and defaults *are* materialized, so that two
spellings of the same policy hash alike. The two rules compose: a block is absent
unless stated, and complete once stated.

### The encoding gate

Most of the older sources in this tree carry non-UTF-8 bytes — a copyright
character on the second line of 137 tracked files, and a Windows-1252 byte in two
others. Some editing tools silently rewrite those bytes as the Unicode
replacement character, and "The damage is invisible in a normal diff review — the
line still reads 'Copyright ... 2022' — so it needs a mechanical check."

The gate is that check. It compares the non-ASCII byte count of every file under
review against the same file's committed revision. It deliberately does not care
*which* high bytes a file holds, only that the inventory did not change, which
catches three distinct accidents at once: a copyright byte corrupted into a
replacement character, an over-correction in the other direction, and newly
authored prose introducing typographic punctuation into a file that had none.

Captured goldens are judged differently, and the exemption is reasoned rather
than convenient. A golden is a byte-for-byte record of what the runtime wrote,
so if the model it came from carries a typographic character, the golden must
too: "reproducing it is the whole point of the oracle, and 'fixing' it would
falsify the fixture." A golden listed in a checksum manifest is therefore judged
against that manifest instead.

This is also why every search in this tree is run with a real `grep` rather than
a shell alias. An audit recorded the mechanism as its highest-severity finding:
one common shim silently returns "no match" on the non-UTF-8 sources, and "no
output and exit status 0 ... is indistinguishable from an honest 'no match'."
Four sweeps of a grounding pass were invalidated by it, and two conclusions drawn
from those sweeps were false.

## Audits report; they do not quietly repair

Some work is explicitly report-only: read the code, find what is wrong, change
nothing. Three such reports are tracked in `tests/`, and each opens by saying so
— "Report-only. **Nothing in this document was fixed.**"

The discipline that makes them useful is that every finding is re-derived rather
than inherited. One states it directly: everything in it "was confirmed by
content in this worktree ... line numbers were re-located, not copied from the
prompt." Findings are severity-ranked by consequence, and the top severity is
defined by the outcome this project cares most about — a finding is High when it
"can produce a silent wrong answer or data loss".

Findings are counted and kept, not closed by narrative. One report carries
twenty-one findings across four severities; another, twenty-four; the reliability
audit added twenty more, "none fixed, per the report-only mandate."

Where a report-only rule *was* broken, the deviation is recorded rather than
absorbed. One track carries a section titled "Authorized deviations", listing two
approved single-expression changes with the before-and-after code, the reason
each was necessary, and the verification that it worked — "Recorded here so the
schema layer's owner sees them without reading the session transcript."

Consequences of a track's own decisions are listed as findings against itself,
too. That is the same instinct as the encoding gate: a defect you introduced is
harder to see than one you inherited, so it needs a mechanism rather than good
intentions.

### Premises that do not match the tree are reported, not forced

Work in this project arrives with a stated plan, and a plan can be wrong about
the code. The reliability audit found four of its own premises did not match the
tree — two named targets were dead code, one item was already fixed, and one
count was wrong. Each was verified with the compiler and reported rather than
worked around. Making the tree match a mistaken premise is the fastest way to
turn a documentation error into a code defect.

## Evidence tables that say "nothing"

The most unusual artifact in this repository is a table with a column for the
evidence behind each claim, in which some rows read *nothing*.

One runbook opens with exactly that. Its heading is "what has and has not been
executed", and it states plainly: "**No constellation has been run against any of
the code in this track.**" Each row then names its evidence — a clean rebuild, a
named test binary, a dry run and an inspection of the serialized graph — and two
rows read "**nothing — this runbook is the first execution**".

That table was later appended to rather than edited when an automated lane closed
the two open rows: "Appended, not substituted: everything above is the record as
it stood when this runbook was written, and it stays." The correction is dated,
the mechanism that closed the gap is named, and the earlier state remains
readable. A record that quietly acquires evidence it did not have is a record
nobody can audit.

## Gates, review, and who commits

Every change runs the full suite and has to come back green. The suite is layered
so that this is affordable: most of it is fast unit tests, the transport-free
targets need no runtime installed, and the end-to-end lanes are what a change to
the runtime has to answer to. What each lane proves and what it compares against
is on the [test index](tests/index.md).

Three properties of the working method are worth stating because they are
unusual:

**Machine-checkable reporting.** Work produces a report with commands, counts,
exit codes and before-and-after tables, not a narrative. Numbers in it are
reproducible by running what the report names — which is what allows a later
reader to disagree with it.

**Autonomous work is reviewed before it is kept.** Automated work is done in a
working tree and reviewed there. The reliability audit's own header records the
shape: the repository head was "unchanged; nothing committed. All work left in
the working tree."

**Commits are human.** No automated process commits to this repository. A change
is proposed, gated, reviewed and then committed by a person — which is what makes
the report and the review load-bearing rather than ceremonial.
