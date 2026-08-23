# Lane: X1

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `X1` · Defined in: `tests/tools/lanes.txt` · Group: CPU

X1 is the audit-failure lane, and the only one that exercises escalation. A
child is made to lie about having nothing to offer, and green means the lie was
caught, the run escalated in response, and the true optimum was reached anyway.

## Scenario

The document combines sampled certification with a column farm on both children,
because escalation is a property of a run that is both farming and sampling. An
environment hook then makes one child present false claims: on every round where
it finds an improving point, the point is suppressed and the claim goes out
empty and unproven.

The hook is one-directional — it can only make the system do more work — and
deliberately does not apply to a certification solve forced by a rider. That
asymmetry is what makes the failure detectable: the candidate lies, the
certifier tells the truth, and the master sees a column where the claim said
there was none.

This lane asserts theorems and records everything else, and says why. Its
siblings assert a full event table because their schedules are derived. Here,
suppressing a child's columns changes which columns enter the restricted master,
hence every subsequent dual and folded cost, hence both the farm schedule and
the draw sequence — and the escalation then changes the policy midway through.
A predicted trace would be a table someone invented and then asserted.

Four theorems are asserted, each true of every correct run. The objective is the
same optimum the honest lanes reach, which is the lane's most important
assertion: a run in which a child lied whenever it had something to say reaches
the true optimum only if the terminal invariant refuses to converge on an
unproven uncertified claim and the certifier supplies the withheld column. At
least one audit failure must occur, or the hook did not fire. The run must
escalate and thereafter certify every unproven claim with no further draws. And
every claim in the round it converged on must be proven or certified.

## Running

```bash
tests/e2e/run_engines.sh --lane pfe006-escalate --domain 260 --inforepo-port 12360
```

This lane is not part of `--lane all`. The assertions alone are
`tests/e2e/assert_pfe006_escalate.sh <workdir>`.
