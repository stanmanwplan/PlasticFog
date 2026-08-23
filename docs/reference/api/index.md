# API overview

<!-- dc:status=polished dc:owner=DC4a -->

PlasticFog exposes four programmatic surfaces: the problem-input library that
reads and validates authored documents, the conductor control API that the `pf`
front end speaks, the DDS control plane that reaches running services, and the
results envelope a solve returns. This page says what each one is, which header
defines it, and which page documents it. All four share one return
convention, documented under [Errors and status](#errors-and-status) below.

Every signature on these pages is copied from the header that declares it.
Where a header states a thread-safety, ownership or lifetime rule, the page
repeats it; where a header states none, the page claims none.

## The four surfaces

| Surface | Header | Page |
|---|---|---|
| Problem definitions, spot updates and control documents — parsing, validation, canonical form | `pf_ProblemInput.h`, `pf_ProblemInput_Manager.h` | [Problem input](problem-input.md) |
| The JSON value type and codec the input layer is expressed in | `pf_Json.h` | [Problem input](problem-input.md) |
| Content hashing — the identity of a stored revision | `pf_Hash.h` | [Problem input](problem-input.md) |
| The JSON Lines / AF_UNIX wire between `pf` and `pf_Conductor` | `pf_Conductor_ControlApi.h` | [Control API](control.md) |
| The DDS control-plane command objects carried to running services | `pf_Commands.h` | [Control API](control.md) |
| `pf.results_envelope.v1` — outcome, provenance and structured failures | `pf_Results_Types.h` | [Results](results.md) |
| How results leave the runtime and reach a caller | `pf_Results_Gateway.h` | [Results](results.md) |

The conductor control API and the DDS control plane are **different surfaces**
and are documented as such. The first is a request/reply protocol between a
command-line client and a resident daemon; the second is the command object a
service receives over DDS once a problem is running. They share vocabulary in
places and nothing else.

## Errors and status

Every surface on these pages shares one return convention, and it is declared in
`pf_Error.h` rather than per surface. A call that can fail returns `pf_Status`;
a call that can fail *and* produce a value returns `pf_Result<T>`. Both are
two-state and neither carries a third: a `pf_Status` is either ok or holds one
`pf_Error`, and a `pf_Result<T>` either holds a value or holds an error. Nothing
throws across an API boundary, which is what lets `pf_ResultsEnvelope::parse`
run inside a DDS listener callback and what lets the problem-input library be
called from a tool that links no runtime at all. The header states the rule for
choosing between the two mechanisms it offers: use `PF_LOG_*` when the current
function can continue, use `PF_RETURN_ERROR*` when the API already has a failure
return, and use `PF_FAIL_FAST*` only at a legacy boundary that can neither
recover nor yet propagate a status.

### The two carriers

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `pf_Status()` | `pf_Status() noexcept = default;` | "A default `pf_Status` represents success" |
| `pf_Status::success` | `static pf_Status success() noexcept` | the explicit spelling of the same thing |
| `pf_Status::failure` | `static pf_Status failure(pf_Error error)` | a failure carrying one error |
| `pf_Status::failure` | `static pf_Status failure(pf_Error error, pf_Error cause)` | the same, with the error's cause attached |
| `pf_Status::ok` | `bool ok() const noexcept` | true when no error is held |
| `pf_Status::operator bool` | `explicit operator bool() const noexcept` | `ok()`, for `if (status)` |
| `pf_Status::error` | `const std::optional<pf_Error>& error() const noexcept` | the error, engaged only when `!ok()` |
| `pf_Result<T>()` | `pf_Result() = delete;` | default construction is forbidden, so `!result` always implies `error()` is engaged |
| `pf_Result<T>::success` | `static pf_Result<T> success(T value)` | a value |
| `pf_Result<T>::failure` | `static pf_Result<T> failure(pf_Error error)` | an error |
| `pf_Result<T>::failure` | `static pf_Result<T> failure(pf_Error error, pf_Error cause)` | an error with its cause |
| `pf_Result<T>::ok` | `bool ok() const noexcept` | true when a value is held |
| `pf_Result<T>::value` | `const std::optional<T>& value() const noexcept` | the value, engaged only when `ok()` |
| `pf_Result<T>::error` | `const std::optional<pf_Error>& error() const noexcept` | the error, engaged only when `!ok()` |

The accessors are const deliberately: the header records that this is what
"prevent[s] callers from clearing the active alternative and recreating an
invalid third state." `pf_Unit` (`struct pf_Unit {};`) exists so a fallible
call with nothing to return can still be a `pf_Result`.

### What an error carries

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `severity` | `pf_ErrorSeverity severity = pf_ErrorSeverity::Error;` | `Debug`, `Info`, `Warning`, `Error` or `Fatal` |
| `category` | `pf_ErrorCategory category = pf_ErrorCategory::General;` | the stable category the caller branches on |
| `code` | `std::string code = pf_ErrorCodes::GeneralFailure;` | the stable dotted code |
| `message` | `std::string message;` | the human message |
| `context` | `pf_ErrorContext context;` | structured context, never embedded in the message |
| `cause` | `std::shared_ptr<const pf_Error> cause;` | the next error down the chain |
| `setCause` | `pf_Error& setCause(pf_Error causeError);` | attach a cause and return `*this` |

The eleven categories are `General`, `Configuration`, `Validation`, `State`,
`Transport`, `Data`, `Persistence`, `FileSystem`, `Compile`, `Solver` and
`Internal`, and they are lower-cased on the wire by
`pf_error_detail::toString`. The codes are named constants in
`namespace pf_ErrorCodes` and each is the category's own prefix followed by a
dot: `validation.invalid_argument`, `data.stale_revision`,
`transport.stale_reply`, `solver.invalid_result`,
`internal.invariant_violation`, and so on. A caller matches the code; the
message is not a contract.

Two groups of codes are worth naming because they are **not** failures. The
control-plane lifecycle codes `state.subproblem_paused`, `state.rmp_paused`
and their `_resumed` counterparts are state reports carried under category
`State`, so that "a collector can tell a deliberate pause from a subproblem
that has gone silent." `data.stale_revision` is the same idea for spot
updates: a module whose revision is lower than one a service already holds is
"rejected AS DATA and never adopted ... a well-formed module that arrived too
late, which is a fact about the input and not a failure of the service."

### Context, and where it goes

`pf_ErrorContext` carries `module_id`, `service_id`, `correlation_id`, `state`,
`native_detail`, `source_file`, `function`, `source_line` and a
`std::map<std::string, std::string> details`. It is built fluently through
`PF_ERROR_CONTEXT()`, which is `::pf_ErrorContextBuilder()`:

```cpp
PF_ERROR_CONTEXT()
    .serviceId(service_id)
    .correlationId(correlation_id)
    .state("waiting_costs")
    .detail("iteration", iteration);
```

The convention the header states is that module, service, correlation and state
values belong in the context rather than inside a message or a native-detail
string. `native_detail` is kept as raw adapter or library evidence, and its
existing `key=value` segments are also copied into the JSON `details` object on
a best-effort basis, so call sites written before `details` existed stay
queryable. `pf_ErrorContextScope` overlays context on the current thread at an
operation boundary and restores the previous values on destruction; it
deliberately does not imply propagation to a new thread or across a transport
boundary, which "must copy the correlation fields into their
message/envelope and establish a new scope at the receiving boundary."

An error is emitted as one JSON object per line on **stderr**, carrying
`timestamp` (UTC, milliseconds), `severity`, `category`, `code`, `message`,
`thread_id`, a `source` object of `file`, `line` and `function`, whichever
context properties are non-empty, and a nested `cause` object where one is
attached. Cause chains are followed to a depth of eight and then reported as
`"cause_truncated": true` rather than truncated silently. `PF_LOG_LEVEL`
selects the minimum severity emitted, defaulting to `info`. The header's
guidance on chains is to "log once at the service boundary when practical
instead of emitting an unrelated record at every layer."

The error model is independent of OpenDDS, ACE, TAO, COIN-OR and SQLite by
design: adapter and native error data are retained as context, while callers
reason about the stable categories and codes above.

## The problem-input library stands alone

`pf_ProblemInput.h`, `pf_ProblemInput_Manager.h`, `pf_Json.h` and `pf_Hash.h`
build into one static library, `pf_problem_input`. `CMakeLists.txt` states its
contract in the comment above the target: the library "intentionally has no
OpenDDS, COIN-OR, or SQLite dependency so it can also be used by LLM tooling,
local API handlers, and future applications that operate in memory." Its only
declared link dependencies are `Threads::Threads` and `CMAKE_DL_LIBS`.

```cmake
add_library(pf_problem_input STATIC
  pf_Hash.cpp
  pf_Json.cpp
  pf_ProblemInput.cpp
  pf_ProblemInput_Manager.cpp
)
```

The build carries a configure option that makes the separation testable rather
than merely stated:

```cmake
option(PF_PROBLEM_INPUT_ONLY "Configure only the transport-neutral problem-input library" OFF)
```

`CMakeLists.txt` records its purpose as allowing "schema tooling and its tests
to be configured on systems that do not install the OpenDDS/COIN-OR runtime",
and notes that the default remains the complete build. The same configure step
copies `pf_problem_input.schema.json` beside the build products, so a caller
that validates outside C++ has the machine-readable contract without reading the
source tree.

One dependency in the library is deliberate and worth knowing about: the
executability predicate for the GPU engine is answered by a runtime probe that
`dlopen`s a library the build never links. `CMakeLists.txt` records that this is
why the target links `CMAKE_DL_LIBS`, and why the probe is header-only — so that
"no COIN-OR, no HiGHS, no engine layer enters the codec library, which keeps
`pf_problem_input` the dependency-free thing it is."

## What these pages do not cover

The user-relevant surface is what a caller writes code against: the document
codec, the manager that owns a definition, the control wire, and the results
envelope. Transport plumbing — DDS listeners, readers, writers and QoS wrappers
— is internal and is not documented here, except where one of the headers above
exposes it to a caller by name.

For the shapes these APIs carry rather than the calls that carry them, see
[Schemas](../data/schemas.md) and [Files & artifacts](../data/artifacts.md); for
the command-line experience built on the control API, see
[Workbench reference](../../guide/workbench.md).
