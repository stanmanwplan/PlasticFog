# Lane: W8

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `W8` · Defined in: `tests/tools/lanes.txt` · Group: CPU

W8 is the log lane. It spawns a deployment and then follows its logs, and green
means the router labelled two services' output correctly, the silent default was
genuinely silent, and nothing the lane does depends on a terminal multiplexer
being alive.

## Scenario

This is the one Workbench scenario that spawns rather than attaching, and it has
to: captured per-service streams exist only where the supervisor started the
processes. The lane therefore reuses the spawn scenario's document, brings the
constellation up through the deployment verb, and then follows.

Four things are asserted. Fan-in labelling over two services: each line carries
the service it came from and that service's own process identifier, so a merged
stream stays attributable. The silent default proved silent: the display mode
that is meant to produce no presentation produces none, which is a claim that
can only be checked by looking, since an accidental default would be invisible in
a passing run. `--level` filters structured records only, so banners, solver
chatter and timing lines pass every floor rather than being dropped on a guessed
severity. And a presentation pane is killed mid-lane, after which the lane
must continue: following logs must not depend on a viewer staying alive, or an
operator closing a window would take the run with it.

The rest follows the Workbench discipline — the conductor tracked like a
service, the catalog a scratch database under the run directory, and a short
per-run control socket.

## Running

```bash
tests/e2e/run_workbench.sh --scenario wb-logs
```

Failures always retain the working directory; `--keep` retains it on success.
