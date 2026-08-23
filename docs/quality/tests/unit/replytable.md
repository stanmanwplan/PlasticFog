# pf_ReplyTable_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_ReplyTable_Tests.cpp` · CTest: `pf_ReplyTable` · Labels: `unit;fast;public`

The reply table decides whether an arriving subproblem reply belongs to an
outstanding request and, if so, which block it routes to. This test pins that
decision, and in particular the reserved echo field whose safety argument is
that it cannot create a new failure mode while it stays constant.

## What it verifies

- Baseline routing: an unarmed table has no outstanding request; a fully
  matching reply is accepted, carries no rejection text, fills its slot, routes
  to the armed block, and delivers the payload that was copied in.
- The genuine rejections are each reached by name — a mismatched correlation
  identifier, a mismatched iteration count, a second reply to a filled slot as a
  duplicate — and a rejected reply leaves the slot armed rather than consuming
  it.
- A reply whose reserved echo does not match the request's is accepted. The
  mismatch is reported through a separate output so a listener can log it, while
  the routing result itself is unchanged: the slot fills, the reply routes to
  its block, and the solution is delivered.
- The reserved field cannot mask or rescue anything. A correct echo does not
  rescue a reply that is bad for a real reason, an incorrect echo does not turn
  an acceptable reply into a rejection, and when both a genuine rejection and a
  mismatch occur, both are reported.
- A non-zero reserved value is exercised in both directions: echoed correctly it
  is accepted with no mismatch reported; dropped to zero it is still accepted,
  with the mismatch reported.

## Running

```bash
ctest --test-dir build -R '^pf_ReplyTable$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_UNIT_TESTS=ON`.
The unit depends on the standard library alone, so the test runs on every
configure that builds it.
