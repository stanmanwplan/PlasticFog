# Lane: V7

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `V7` · Defined in: `tests/tools/lanes.txt` · Group: CPU

V7 is the abort half of the nested fault matrix. The same child of the mid is
killed before the solve, but this time the mid is configured to abort on it and
the root to abort on the mid. Green means the refusal propagated up both levels
and reached the caller as an exit code with a path-scoped status.

## Scenario

The constellation, the injection and the shortened reply deadline are the
substitute half's. Only the policies differ, and they are set at both levels
deliberately: the mid refuses to approximate its missing child, and the root
refuses to approximate the mid.

Abort means the campaign was terminated because a block's policy said a
master-side approximation of it is not acceptable. No objective is asserted, by
design — the coordinator still unwinds locally afterwards and still prints a
number, and asserting that number would be asserting the confidently wrong
answer the policy exists to refuse.

What is asserted instead is that the refusal travelled: the application exits
with the service-failure code, and the status it reports is scoped to the path
where the failure occurred rather than to the problem as a whole. A failure that
stopped the run but arrived unattributed would leave an operator with nowhere to
look.

The policies are delivered through the per-service environment override, the
real precedence chain's environment level, because the fixture states no failure
policy on any boundary. Injection is fixed to killing before the solve; the
first-reply mode is rejected rather than coerced, because the batch pricing path
outruns it on this fixture.

## Running

```bash
tests/e2e/run_nested.sh --degrade C1 --degrade-mode pre-solve --degrade-policy abort
```

The degrade target is restricted to the one child of the mid this matrix injects
at. Failures always retain the working directory.
