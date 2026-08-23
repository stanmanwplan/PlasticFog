# Lane: I1

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `I1` · Defined in: `tests/tools/lanes.txt` · Group: CPU

I1 is the all-inline submission lane. Every model in its document travels
inside the document itself, and the lane installs no model file at all. Green
means the runtime executed what was submitted, not a file the harness happened
to stage.

## Scenario

Every other price-directed lane submits a document whose models are file
sources, and stages the root model into the application directory before
launching. None of them can therefore distinguish executing the document from
executing the staged file. This lane removes the one staging step they share:
the fixture contains no model source anywhere, and the lane fails if one
reaches the application directory.

What makes an inline document executable is a graph-builder default that gives
an inline master's source a conventional file name and an inline child's a name
derived from its model identifier — the same name the master's include line
carries. Constellation staging, launch gating and teardown otherwise follow the
generalized lane's discipline exactly.

The oracle is 8.0, hand-derived by enumerating all four option combinations of
the instance, one of which is infeasible; the minimum is unique. There is no
flattened oracle model for this fixture by design, because such a file would
itself be a model file.

The objective alone proves nothing, and the lane says so: the coordinator
prices an unanswered block locally with its own fallback, and that fallback
reproduces the same number. So participation is asserted as an equality per
boundary rather than as a pinned round count, which would pin a property of the
coordinator's convergence rather than of the decomposition, and the inline
facts — the absent model file, the document's own contents — are asserted
separately. The results envelope the application wrote and its exit code are
checked alongside.

## Running

```bash
tests/e2e/run_inline.sh
```

The lane defaults to its own domain and repository port. `--keep` retains the
working directory on success; failures always retain it. The assertions alone
are `tests/e2e/assert_inline.sh <workdir>`.
