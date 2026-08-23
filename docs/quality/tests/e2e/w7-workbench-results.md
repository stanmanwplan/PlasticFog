# Lane: W7

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `W7` · Defined in: `tests/tools/lanes.txt` · Group: CPU

W7 is the replay-equality lane. A run that returns per-master results is
exported as a stream of records, canonicalised, and compared against the results
document the run itself wrote. Green means what a caller can replay is exactly
what the run produced.

## Scenario

The lane runs the nested fixture whose results scopes name the mid as well as
the overall problem, so more than one envelope exists to account for. It then
exports the run's envelopes and compares the export against the run's own
results document.

The comparison is an equality, not a spot check, and three properties carry it.
Every envelope appears exactly once — a replay that duplicated or dropped one
would still look plausible read line by line. The root's envelope is flagged as
final, so a caller can tell the terminal answer from progress. And every
non-root scope is labelled as intermediate or local rather than left unmarked,
so a per-master result can never be mistaken for the overall answer.

The lane needs the nested fixture because only a mid holds an envelope of its
own; a flat topology has nothing to compare beyond the overall answer. It runs
against the constellation the harness starts, for the same reason the other
campaign lanes do.

## Running

```bash
tests/e2e/run_workbench.sh --scenario wb-results
```

Failures always retain the working directory; `--keep` retains it on success.
