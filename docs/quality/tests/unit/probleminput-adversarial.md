# pf_ProblemInput_Adversarial_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `pf_ProblemInput_Adversarial_Tests.cpp` · CTest: `pf_problem_input_adversarial` · Labels: `—`

The refusal half of the problem-definition library. Every case is a document a
careless or hostile author could write, paired with the refusal it must draw;
matching acceptance cases sit alongside, so no rule passes by refusing
everything.

## What it verifies

- Hardening of the parsing layer: the hash function against known vectors, depth
  and entry-count limits, a patch that fails partway leaving its target
  unchanged, and a topology deeper than the limit.
- Concurrency: two updates racing through a commit hook give one winner and one
  refusal naming the concurrent update, the revision advancing exactly once. The
  replay branch is exercised for real, and its bounded memory is asserted rather
  than assumed.
- Digest discipline, stated for both patch formats: an unrelated patch must not
  absorb changed file bytes, removing a pin is an explicit request to
  re-resolve, an authored digest stays authoritative even when it agrees, and
  changing only the locator leaves the old digest stale.
- Capability rejections, one per rule: an engine outside the vocabulary, one
  named at a role its table forbids in both directions, options that are not
  opaque objects, unknown keys, and a GPU selection that warns.
- Control-command rejections: an unknown verb, empty or ambiguous targets,
  duplicated or unstable node identifiers, missing or unknown members, a wrong
  version, a negative revision, a command naming a different problem or an
  undeclared target, a mismatched pin, and a command submitted as a definition
  change. Results-scope rejections, hybrid-master shapes, malformed runtime
  summaries, unknown enumeration members and a running-state validation before
  anything is committed follow the same pattern.
- On resource-directed boundaries, engine selections and failure-policy options
  that are legal on a price-directed boundary are refused, including the
  compound retry form checked on its tail as well as its head, each paired with
  the acceptance that keeps the refusal honest.
- One rejection per semantic rule of every optional block — pairing rules in
  both directions, values outside a vocabulary, blocks present but empty, domain
  limits — each against an otherwise well-formed document, with a positive
  control so no case passes vacuously.

## Running

```bash
ctest --test-dir build -R '^pf_problem_input_adversarial$' --output-on-failure
```

The target requires the transport-free configure, `-DPF_BUILD_PROBLEM_INPUT_TESTS=ON`.
