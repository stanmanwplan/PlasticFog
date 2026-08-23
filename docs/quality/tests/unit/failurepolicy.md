# pf_FailurePolicy_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_FailurePolicy_Tests.cpp` · CTest: `pf_FailurePolicy` · Labels: `unit;fast;public`

The missing-subproblem failure policy decides what a master does when a child
does not answer. This test pins the precedence chain that selects a policy and
the exhaustive matrix of cause against policy. It depends on nothing outside
the standard library, which is what makes it cheap enough to run always.

## What it verifies

- Policy text parses in every accepted form — case-insensitively, space
  trimmed, with a retry count, backoff and follow-on policy — and deprecated
  spellings are accepted while flagged as such. Invalid text is rejected, and a
  round trip preserves every field.
- The precedence chain runs attribute, per-subproblem environment, global
  environment, built-in default. Each level is asserted while the levels below
  it are also set — the only arrangement that catches a chain reading in the
  wrong order — and the selected source is recorded. A different subproblem
  still takes the global override, and an unparseable per-subproblem override
  falls through rather than failing.
- The cause-by-policy matrix is a table whose row count is checked against
  causes times policies, so adding a policy without its rows fails here rather
  than shipping untested. It covers a silent peer, a failed write and a
  reported failure under each policy, plus a paused and a stopped child, where
  retrying cannot help and falls through to the follow-on policy.
- A failed write is retryable because the peer never saw the request, while a
  reply timeout and a reported failure are not. Provenance spellings are
  pinned, each cause maps to its own error code, and a pause is not reported as
  a transport timeout. Combining policies is ordered: abort beats substitute in
  either order, retry beats substitute, substitute is the identity.
- On a resource-directed child, substitute is invalid and refused with a reason
  naming both the policy and what to use instead; abort is the default there
  and retry is valid. The price-directed path is unchanged by that rule.

## Running

```bash
ctest --test-dir build -R '^pf_FailurePolicy$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
