# Lane: S1

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `S1` · Defined in: `tests/tools/lanes.txt` · Group: CPU

S1 is the sampled-certification lane. It certifies emptiness claims at random
under a fixed seed, and green means the draws were exactly the pinned ones, the
resulting ledger matched the settlement predicted on paper, and the terminal
invariant overrode the sampling where it had to.

## Scenario

The runner stages the speculative-farming fixture on the same flat
constellation the baseline lane uses, submitting the document whose
certification policy is sampled, at a rate of one half with a fixed seed on both
children. With no speculation block the campaign follows the unfarmed six-round
trace, and an environment hook puts both children's claims in the unproven state
they must be in to be ledgered.

The five draws are the point, asserted at full double precision. They are the
generator's output for the seed, service identifier and round, pinned in that
unit's own test and written into the fixture's notes before this machinery
existed. A draw that differs is a finding about the generator, the seed tuple or
the round numbering, never a number to adjust. Three fall below the rate and
certify inline; two are skipped.

The centrepiece is the terminal override, which is why this seed was chosen.
One child's draw at the final round says skip — and that is the round on which
both children claim emptiness and the run would converge. It does not converge
until that claim has been certified anyway, so the lane asserts a terminal
certification event for that child at that round. That is an assertion about
the override rather than the draw: the terminal invariant is structural, with no
mode, rate or seed that switches it off, and a lane asserting only the draws
would pass on a build where the interception had been deleted.

The settlement those draws predict is asserted in full: five claims, three
certified inline, two skipped, one certified at the terminal round, no audit
failures, no escalation, one residual debt. Certifying always would spend five
certifications; sampling spends three plus the interception's one, for the same
guarantee.

## Running

```bash
tests/e2e/run_engines.sh --lane pfe006-sampled --domain 260 --inforepo-port 12360
```

This lane is not part of `--lane all`. The assertions alone are
`tests/e2e/assert_pfe006_sampled.sh <workdir>`.
