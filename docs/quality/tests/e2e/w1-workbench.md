# Lane: W1

<!-- dc:status=polished dc:owner=DC4b -->

Lane: `W1` · Defined in: `tests/tools/lanes.txt` · Group: CPU

W1 is the Workbench lane. Every other lane drives the runtime's application
directly; this one drives the front end — a thin CLI speaking JSON Lines over a
Unix-domain socket to a resident conductor, which is what reaches the runtime.
Green means the front end gets the same answer.

## Scenario

The constellation underneath is the nested one, staged exactly as its own lane
stages it — nine processes, two master services, one mid — because the point is
that the front end reaches the same answer, not that a new topology does. The
oracle is not restated here either: the assertions read it out of the nested
lane's, so the two cannot drift.

One difference from the nested staging is deliberate and load-bearing: the
fixture's models and data are not copied into the application directory. They
come out of the catalog, and submitting exports the stored revision into the run
directory and points the application's source root at that export. A green lane
is therefore evidence that a revision stored by importing a specification is
sufficient on its own to re-solve. A lane that also staged the fixture into the
application directory could not tell the two apart.

The application directory is not empty of models, and the assertions say so
rather than pretending otherwise — it is a copy of the repository's own, which
carries demonstration models including one of the same conventional name. What
is asserted is the claim that actually distinguishes the sources: that none of
the fixture's own resources are there, and that the same-named model that is
there is a different file.

The conductor is launched like a service — held on a pipe, tracked by process
identifier, torn down by the same trap as everything else, and started in the
foreground so it stays the process the harness tracks. The catalog is a scratch
database under the run directory and the control socket is per-run, so no run
touches a real catalog or socket.

## Running

```bash
tests/e2e/run_workbench.sh
```

The bare invocation runs this scenario. Failures always retain the working
directory; `--keep` retains it on success.
