# Lane: W3

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `W3` · Defined in: `tests/tools/lanes.txt` · Group: CPU

W3 is the attach lane. The harness pre-starts the constellation, the document's
bindings ask for services to be discovered rather than spawned, and green means
the deployment attached to what was already running and spawned nothing.

## Scenario

The constellation is pre-started exactly as the generalized lane starts it. The
document's placements are queries, so the supervisor resolves each binding
against the register service and binds to the service it finds instead of
launching one.

The lane's two assertions are complementary and neither is sufficient alone.
First, that nothing was spawned: a deployment that attached and also started a
duplicate would still solve, and only counting processes catches it. Second,
that stopping the deployment leaves the harness's services running — the
supervisor drains what it started, and here it started nothing, so a stop that
took the constellation down would mean it had claimed processes it did not own.

Everything else follows the Workbench lane's discipline: the conductor is
launched in the foreground and tracked like a service, the catalog is a scratch
database under the run directory, and the control socket is a short per-run
path.

## Running

```bash
tests/e2e/run_workbench.sh --scenario wb-discover
```

Failures always retain the working directory; `--keep` retains it on success.
