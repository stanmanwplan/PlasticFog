# pf_ServicesRepo_Schema_Tests

<!-- dc:status=polished dc:owner=DC4b -->

Source: `tests/unit/pf_ServicesRepo_Schema_Tests.cpp` · CTest: `pf_regdb_schema` · Labels: `unit;fast;public`

The registry's richer service table and its structured query path. This test
covers schema creation, migration from the older table, the mutation verbs,
query selection semantics, and the compatibility of the query shapes the
application already composes. Each section runs in its own working directory,
because the store's path is relative and its constructor deletes what it finds.

## What it verifies

- The schema is created with its columns and its type index, and the legacy
  table is gone afterwards.
- A database predating the wider schema migrates: its rows survive, are stamped
  as migrated, and the old table is replaced.
- A full registration payload round-trips field by field — name, type, host,
  endpoint, capabilities, options, status and timestamps — with the registration
  timestamp matching the expected format.
- A duplicate registration is ignored rather than overwriting the stored row.
- A heartbeat promotes a registered service to active, an update applies its
  whole payload, and removal addressed by identifier takes effect.
- The three query shapes the application composes today are frozen and continue
  to resolve unchanged.
- Structured queries filter by type and by required capability, and identifiers
  are matched exactly. Values crafted to look like injected statements are
  handled as data, leaving the table intact.
- Liveness is decided against a freshness window: fresh rows are returned, a row
  placed exactly at the window edge is included, and a deactivated service is
  excluded from availability regardless of its heartbeat.
- Selection semantics are pinned: a short result is a success matching what is
  available rather than a failure.
- An identifier too large to represent in the store's integer type is refused,
  with the largest representable value accepted.
- The published query schema is readable, embeds an example, and that example is
  a balanced JSON object; the deprecated schema version is handled as such.

## Running

```bash
ctest --test-dir build -R '^pf_regdb_schema$' --output-on-failure
```

The target exists only in a tree configured with `-DPF_BUILD_REGDB_TESTS=ON`.
It needs the full toolchain configure even though nothing in it speaks the
transport, because the store's header reaches it transitively.
