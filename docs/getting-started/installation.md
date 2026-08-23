# Installation

<!-- dc:status=polished dc:owner=DC1 -->

This page describes how PlasticFog is built and run today: the platform it
targets, the dependencies its CMake configure requires, the reduced configure
that needs none of them, and the caveats a first build runs into. PlasticFog
is pre-release, so it is built from source; there is no package to install.

## Platform

PlasticFog is a Linux application. It is developed and exercised on Ubuntu
under WSL2 on Windows, and the one CMake preset in the tree,
`ubuntu-cli-debug`, names that configuration. Nothing in the build is
Windows-native: the services use POSIX process, socket and filesystem
interfaces directly, so a native Windows build is not a supported path.

The code is C++17 throughout. The top-level `CMakeLists.txt` declares
`cmake_minimum_required(VERSION 3.16)`; `CMakePresets.json` declares a preset
schema that needs CMake 3.19 or later, so use 3.19+ if you intend to configure
through the preset.

## Getting the source

The repository at
[https://github.com/stanmanwplan/PlasticFog](https://github.com/stanmanwplan/PlasticFog)
hosts this documentation today. The source release will land there, and the
clone URL will be published with it.

## Dependencies for the full build

The complete configure builds the service executables, the conductor and the
`pf` command-line client, and it requires all of the following.

**OpenDDS.** The transport under the running constellation.
`find_package(OpenDDS REQUIRED)` resolves it; the `ubuntu-cli-debug` preset
sets `OpenDDS_DIR` from `$env{OPENDDS_INSTALL_DIR}`, so exporting that variable
is the normal way to point the build at an install. OpenDDS brings ACE/TAO with
it. The DDS types the services exchange are generated from `Messenger.idl` at
build time.

**COIN-OR, including DIP.** The decomposition machinery and the CBC/CLP/SYMPHONY
solvers link out of one COIN-OR install root. The build takes that root from
the environment variable `COIN_OR_INSTALL_DIR` by default, and an explicit
`-DCOIN_OR_ROOT=/path/to/coin-or` on the configure line overrides it. If
neither is set, CMake emits a warning at configure time and the targets that
need DIP fail later, at link.

**SQLite3.** Resolved through `pkg-config`
(`pkg_check_modules(SQLITE3 REQUIRED sqlite3)`), so the development package
must be installed, not just the shared library.

**Zimpl, as a library.** The RMP and subproblem services compile their models
through the embedded Zimpl compiler rather than shelling out to a Zimpl binary,
so the library form is required, not optional. Point the build at it with
`ZIMPL_LIB_INSTALL_DIR` (the install root holding `lib/libzimpl-pic.a` and
`include/`) and `ZIMPL_LIB_SRC_DIR` (the pinned Zimpl source tree). A configure
that cannot find both stops with an error naming the two variables, rather than
producing services that fail to link.

**HiGHS.** The engine seam requires it. `HIGHS_INSTALL_DIR` must be exported and
must contain a `libhighs` archive under `lib/` or `lib64/`; an absent or empty
vendor directory is a configure-time error carrying the export line, not a
quiet feature drop. The reasoning is deliberate — a build that silently omits an
engine produces a binary whose capability set depends on the machine that built
it, which would make a document's acceptance or refusal depend on the builder's
shell rather than on the contract. The repository vendors HiGHS with
`tests/tools/highs_vendor.sh`, which pins a specific upstream version and
installs a static, position-independent archive, so nothing has to be staged
beside the services at run time.

!!! note
    Because HiGHS is linked statically and Zimpl is compiled in, the built
    service executables carry those engines with them. Only OpenDDS, COIN-OR
    and SQLite3 are shared-library dependencies at run time.

### NVIDIA cuOpt

cuOpt is optional and, by construction, is **not** a build dependency of any
kind. There is no `find_package(cuopt)`, no install-directory variable, no
include path and no library on any link line. The adapter reaches its entire
API surface through `dlopen`/`dlsym` at run time. A machine with no cuOpt and no
GPU configures, compiles, links and passes the default test matrix unchanged.

The consequence for a user is that cuOpt availability is a property of the
machine at the moment a document is submitted, not of the build. The runtime
probe answers "can this host run cuOpt right now"; a definition that asks for
the cuOpt engine on a host without it is refused with a stated reason rather
than silently downgraded.

## The dependency-free configure

Not every use of PlasticFog needs the runtime. The problem-definition layer —
the JSON value type, the content hashing, the `pf_ProblemInput` object model
and its manager — is deliberately built as a library with no OpenDDS, COIN-OR
or SQLite dependency, so that authoring tools, LLM tooling and local API
handlers can link it on machines that install none of the above.

```bash
cmake -S . -B build-tooling -DPF_PROBLEM_INPUT_ONLY=ON
cmake --build build-tooling -j
```

`PF_PROBLEM_INPUT_ONLY` returns from the top-level `CMakeLists.txt` before
`find_package(OpenDDS)` is ever reached, so the configure succeeds on a host
with none of the runtime dependencies present. The machine-readable schema,
`pf_problem_input.schema.json`, is copied beside the build products so that
tooling outside C++ can validate against the same contract the library
enforces.

## Configuring and building

With the environment variables exported, a full configure and build is:

```bash
cmake -S . -B build -G Ninja
cmake --build build -j
```

or, through the preset:

```bash
cmake --preset ubuntu-cli-debug
cmake --build build -j
```

The build produces the five service executables (`pf_App`, `pf_RegService`,
`pf_OvrService`, `pf_RmpService`, `pf_SubService`), the resident daemon
`pf_Conductor`, the `pf` command-line client, and `pf_CatalogTool`.

!!! warning
    The `ubuntu-cli-debug` preset hardcodes an absolute COIN-OR path in its
    cache variables. This is a known portability defect, recorded in the
    project's own audit findings and deliberately left out of scope of the
    passes that would otherwise have touched it. Until it is fixed, prefer the
    plain configure with `COIN_OR_INSTALL_DIR` exported, or override with
    `-DCOIN_OR_ROOT` on the command line.

### Test options

Every test group is behind a CMake option that defaults to `OFF`, so an
ordinary configure builds the shipping executables and nothing else. The
options are `PF_BUILD_PROBLEM_INPUT_TESTS` (the DDS-free problem-input and
results-envelope tests, the only group that also builds under
`PF_PROBLEM_INPUT_ONLY`), `PF_BUILD_REGDB_TESTS` (registration schema and
structured-query tests), `PF_BUILD_UNIT_TESTS` and `PF_BUILD_TEST_TOOLS`
(the end-to-end fault-injection tools).

Two properties of the test build are worth knowing before a first run. Every
check in the registration test suite is a plain `assert()`, so the suite is
only meaningful in a build where `NDEBUG` is absent — a release configuration
passes it vacuously. And turning a test option off in a build directory that
previously had it on leaves a stale CTest entry behind, because CMake only
rewrites `CTestTestfile.cmake` when `enable_testing()` runs; configure a fresh
build directory rather than reusing one when you want to see real default-off
behaviour. See [Test harness & fixtures](../quality/tests/harness.md) for how
the suites are organised.

## Running the services

The services are ordinary executables that each run in their own working
directory, because several of them resolve state files by relative path. The
repository carries one directory per service role, and `refresh.sh` copies the
freshly built binaries from `build/` into them — the app, the registration
service, the overall-problem service, the RMP service, and one directory per
subproblem service.

Under the current workflow you do not normally start these by hand. `pf deploy`
plans and starts a constellation through the conductor, and `pf` starts a
conductor itself if one is not already running — a missing socket is not an
error. `--no-autostart` suppresses that, and reports the suppression rather
than failing silently. The [Workbench reference](../guide/workbench.md)
documents the verbs; [Services & control plane](../architecture/services.md)
describes what each executable owns.

## Next

With a build in hand, [Your first problem](first-problem.md) walks through
authoring a problem definition, validating it, and submitting it.
