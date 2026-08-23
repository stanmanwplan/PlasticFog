# Lane: D1

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `D1` · Defined in: `tests/tools/lanes.txt` · Group: CPU

D1 is the deferred-certification lane. It runs the speculative-farming fixture
under a certification policy that certifies nothing inline, and green means the
proof-debt ledger recorded every uncertified emptiness claim and the terminal
interception settled the ones that would otherwise have closed the run
uncertified.

## Scenario

The runner stages the fixture's document and launches the full constellation on
an isolated domain as the other engine lanes do; only the document and the
environment differ. The document sets the certification policy to terminal-only
with a fixed seed on both children and states no speculation block, so the
column farm never runs and the lane measures the ledger against a
single-candidate trace.

Both children bind an engine that reports proof statuses of its own, which would
make every emptiness claim proven by the engine that made it and leave a
deferred policy nothing to defer. The lane therefore sets an environment hook
naming both children by service id, putting their claims in the unproven state
they must be in to be ledgered at all.

Every number the assert script checks is an oracle derived on paper in advance,
under the same admission inequality the pricing code applies: five claims arise
and none at the first two rounds, none is certified inline, all five are
deferred, two are certified at the terminal round when both children claim
emptiness at once, no audit fails, nothing escalates, and the residual interior
debt of three is named in the settlement stamp rather than merely counted. The
script also prints every certification event and the stamp itself. A runtime
that disagrees with one of these numbers is a finding to stop on, not a number
to adjust.

Green establishes the terminal invariant doing its job: no run converges on an
unproven, uncertified claim, and this policy spends two certifications where
certifying always would spend five for the same guarantee.

## Running

```bash
tests/e2e/run_engines.sh --lane pfe006-debt --domain 260 --inforepo-port 12360
```

This lane is not part of `--lane all`. Assertions can be re-run alone against a
preserved working directory with
`tests/e2e/assert_pfe006_debt.sh <workdir>`; failed runs always retain theirs.
