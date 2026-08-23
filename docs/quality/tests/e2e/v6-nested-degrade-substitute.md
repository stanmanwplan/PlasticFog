# Lane: V6

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `V6` · Defined in: `tests/tools/lanes.txt` · Group: CPU

V6 is the substitute half of the nested fault matrix: a child of the mid is
killed before the solve, and the mid's default policy approximates it. Green
means the campaign completed and the substitution was recorded in the root's own
results at the path naming where it happened.

## Scenario

Every fault lane before this matrix injected at a leaf of the root. This one
injects at a leaf of the mid, which is the case a nested topology adds: the
failure has to be resolved twice, once by the mid for its own child and once by
the root for the mid, and the two decisions are independent.

The constellation is the nested lane's, launched with a shortened subproblem
reply deadline. The named child is killed before the solve starts, so it answers
nothing at all, and the mid must resolve a missing child of its own.

Under substitution — the mid's default — the mid approximates the missing child's
column locally and the campaign completes. The lane asserts more than
completion: the substitution must land in the root's results document at the path
that names it as having happened under the mid, with the oracle intact. A
substitution that happened but was not reported would leave a reader believing a
fully distributed answer had been produced.

The policy is delivered through the per-service environment override, which is
the real precedence chain's environment level. The fixture states no failure
policy on any boundary, so no attribute outranks it; a lane that set the policy
some other way would be testing a mechanism the runtime does not use.

Injection is fixed to killing before the solve and any other mode is rejected
rather than silently coerced, because the batch pricing path outruns a
first-reply kill on this fixture.

## Running

```bash
tests/e2e/run_nested.sh --degrade C1 --degrade-mode pre-solve --degrade-policy substitute
```

The degrade target is restricted to the one child of the mid this matrix injects
at. Failures always retain the working directory.
