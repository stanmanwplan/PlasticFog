# Control API

<!-- dc:status=polished dc:owner=DC4a -->

Two different surfaces control PlasticFog, and this page keeps them apart. The
**conductor control API** is the request/reply protocol the `pf` front end speaks
to a resident `pf_Conductor` over a Unix-domain socket. The **DDS control plane**
is the command object a running service receives once a problem is live.

They are declared in different headers, carried over different transports, and
answer to different callers. Nothing on one side is a synonym for anything on the
other.

## The conductor control API

`pf_Conductor_ControlApi.h` declares the whole wire in namespace `pf_ControlApi`.
Its header states the scope: everything in the file "is transport-neutral in the
DDS sense — it links `pf_Json` and nothing else — so the framing, the verb table,
the error vocabulary, the lock discipline and the capabilities document can all
be unit-tested without a socket, without a catalog, and without a running
constellation."

### Framing

One JSON object per line, newline-terminated, compact, in each direction. The
five line shapes are declared in the header:

```
request   {"v":1,"id":<any JSON>,"verb":"...","args":{...}}
ok        {"id":...,"ok":true,"data":{...}}
error     {"id":...,"ok":false,"error":{"code":"...","message":"..."}}
event     {"id":...,"event":{...}}          streaming verbs only
done      {"id":...,"ok":true,"done":true}  terminates a streaming verb
```

`constexpr int kProtocolVersion = 1;` is "The only protocol version this build
speaks."

Three properties are stated as rules rather than as behaviour. A line is never
pretty-printed on the wire, "because a reader that splits on `'\n'` has to be
able to trust that a newline ends a message." The `id` is echoed back byte for
byte as the client sent it, whatever JSON type it had — "Rewriting a client's
correlation token into the server's preferred type is how a client stops being
able to match a reply to its request." And a version mismatch is decided before
the verb is even looked at: "a client speaking a protocol this build does not
know is not a client whose verb should be guessed at."

### Messages

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `Request::version` | `int version = 0;` | the `v` field; must be `kProtocolVersion` |
| `Request::id` | `pf_JsonValue id;` | the client's correlation token, of any JSON type |
| `Request::verb` | `std::string verb;` | the verb being called |
| `Request::args` | `pf_JsonValue args;` | the verb's arguments |
| `Reply::Kind` | `enum class Kind { Ok, Error, Event };` | which shape this reply is |
| `Reply::done` | `bool done = false;` | terminates a streaming verb |
| `Reply::data` | `pf_JsonValue data;` | the payload, for `Kind::Ok` |
| `Reply::event` | `pf_JsonValue event;` | the payload, for `Kind::Event` |
| `Reply::errorCode` | `std::string errorCode;` | the vocabulary code, for `Kind::Error` |
| `Reply::errorMessage` | `std::string errorMessage;` | the human message |
| `Reply::errorDetail` | `pf_JsonValue errorDetail;` | "Kind::Error, extra fields inside `"error"`" |

### Encoding and decoding

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `encodeRequest` | `std::string encodeRequest(const Request& request);` | one request line |
| `decodeRequest` | `bool decodeRequest(const std::string& line, Request& request, std::string& errorCode, std::string& errorMessage);` | decode one line, returning a vocabulary code on malformed input |
| `encodeOk` | `std::string encodeOk(const pf_JsonValue& id, const pf_JsonValue& data);` | a success reply |
| `encodeDone` | `std::string encodeDone(const pf_JsonValue& id);` | the terminator of a streaming verb |
| `encodeEvent` | `std::string encodeEvent(const pf_JsonValue& id, const pf_JsonValue& event);` | one event line |
| `encodeError` | `std::string encodeError(const pf_JsonValue& id, const std::string& code, const std::string& message);` | an error reply |
| `encodeError` | `std::string encodeError(const pf_JsonValue& id, const std::string& code, const std::string& message, const pf_JsonValue& detail);` | "As above, with extra members merged into the `"error"` object (candidates, exit codes)" |
| `decodeReply` | `bool decodeReply(const std::string& line, Reply& reply, std::string& error);` | decode one reply line |

`decodeRequest` fails softly by design: the caller "answers with that code rather
than closing the connection, because a client that sent one bad line is still a
client."

This codec is the one place on these pages that does **not** return `pf_Status`:
a wire codec answers with the vocabulary code the protocol defines, so the
failure a caller must relay is a wire code rather than an in-process error. The
convention the other surfaces share is documented under
[Errors and status](index.md#errors-and-status).

### The error vocabulary

Closed, and spelled once in the header as a set of extern constants.

| Constant | Wire code | Meaning |
|---|---|---|
| `kErrorUnknownVerb` | `unknown_verb` | the verb is not in the table |
| `kErrorVersionMismatch` | `version_mismatch` | `"v"` is absent or is not 1 |
| `kErrorBadRequest` | `bad_request` | malformed line, or bad args |
| `kErrorNotFound` | `not_found` | no revision / run matched |
| `kErrorAmbiguous` | `ambiguous` | several candidates matched |
| `kErrorInvalidDocument` | `invalid_document` | the document was refused |
| `kErrorRunFailed` | `run_failed` | the submission itself failed |
| `kErrorUnavailable` | `unavailable` | the conductor is not configured for this |
| `kErrorInternal` | `internal` | anything the daemon did not expect |

`unavailable` is deliberately distinct from `run_failed`. As the design memo puts
it: "This conductor was started without a constellation to talk to" and "the
submission failed" call for completely different operator responses, and
collapsing them into one code would make the first look like the second.

An error's `detail` may add fields — `ambiguous` attaches its candidates,
`run_failed` attaches the run record — but may never rewrite `code` or `message`.

### Where the socket lives

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `socketPath` | `std::string socketPath();` | "`$PF_CONDUCTOR_SOCK` when set and non-empty, else `$HOME/.plasticfog/conductor.sock`" |
| `lockPathFor` | `std::string lockPathFor(const std::string& socketPath);` | "The single-instance lock that guards one socket path" |
| `ensureRuntimeDirectory` | `bool ensureRuntimeDirectory(const std::string& socketPath, std::string& error);` | create the socket's directory with mode 0700 |

The directory mode is chmodded rather than passed to `mkdir`, "because mkdir
honours the umask and a world-readable control socket directory would be a
decision made by omission." The socket itself is chmodded to 0600 after `bind`
for the same reason.

Honouring `$PF_CONDUCTOR_SOCK` everywhere is what lets a test lane run a
conductor whose socket, lock, catalog and run directory all live inside its own
run directory. What a run directory holds is described under
[Files & artifacts](../data/artifacts.md).

### Verbs

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `knownVerbs` | `const std::vector<std::string>& knownVerbs();` | "Every verb v1 answers, in a stable order" |
| `isKnownVerb` | `bool isKnownVerb(const std::string& verb);` | membership in that table |
| `isDeferredVerb` | `bool isDeferredVerb(const std::string& verb);` | verbs named as arriving in a later pass |
| `deferredVerbPrefixes` | `const std::vector<std::string>& deferredVerbPrefixes();` | "Deferred verb prefixes, for the capabilities document" |
| `capabilitiesDocument` | `pf_JsonValue capabilitiesDocument();` | "What this build can execute" |

The deferral machinery exists so that a future capability can be *listed* rather
than discovered by guessing: a deferred verb answers `unknown_verb` exactly as a
typo does, because "a verb that a later pass will implement is not a verb this
build half-implements."

**This build defers nothing it has named.** The workbench close records
twenty-two verbs, one protocol version, and an empty deferred-verb list — "this
build defers no verb it has named, which is a stronger statement than any
non-empty list can make."

| Verb group | Verbs |
|---|---|
| liveness and capability | `ping`, `capabilities` |
| daemon lifetime | `conductor.stop` |
| the catalog | `spec.import`, `spec.show`, `spec.search`, `spec.validate`, `spec.diff`, `spec.export` |
| running a problem | `run.submit`, `run.command`, `run.status` |
| repeated execution | `campaign.start`, `campaign.status` |
| deployment | `deploy.plan`, `deploy.start`, `deploy.status`, `deploy.stop` |
| the results plane | `results.query`, `results.follow` |
| logs | `logs.tail` |
| the prompt pack | `promptpack.build` |

Four verbs stream events before their reply — `run.submit`, `deploy.start`,
`campaign.start` and `results.follow`. `run.submit` emits a `submitting` event
naming the run and the document before the child process is started, and
terminates with a reply carrying both `data` and `done: true`.

The capabilities document is described as "sourced, not stated" — it is built
from the current refusal state, "so the document is a map of the ratchet and not
just a feature list" — and it is deterministic: "the same bytes on every
invocation of the same build."

For what each verb does from a user's seat, see
[Workbench reference](../../guide/workbench.md).

### Autostart

A missing socket is not an error. The rule is a pure function, "so the CLI's
autostart rule is a unit test rather than a lane."

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `Autostart` | `enum class Autostart { Connect, Spawn, Suppressed };` | connect to an existing socket, start a conductor, or fail because `--no-autostart` was given |
| `autostartDecision` | `Autostart autostartDecision(bool socketPresent, bool noAutostart);` | the decision, from those two inputs alone |

A conductor started this way detaches and owns its own lifetime; the CLI process
exiting never takes it down, "because a resident daemon whose life is tied to
whichever CLI happened to start it is not resident."

### Single instance

`Lock` is an flock-based single-instance lock with stale detection. The header
explains why the distinction is reported rather than smoothed over: flock is
released when the holding process dies however it dies, so "a conductor that was
SIGKILLed leaves a lock file whose bytes still name it and whose lock is free",
and "an operator who sees a conductor start after a crash should be told a crash
happened."

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `acquire` | `bool acquire(const std::string& lockPath, std::string& error);` | take the lock, or report who holds it |
| `held` | `bool held() const noexcept;` | this process holds it |
| `heldByAnother` | `bool heldByAnother() const noexcept;` | another live process holds it |
| `otherPid` | `long otherPid() const noexcept;` | that process's pid |
| `wasStale` | `bool wasStale() const noexcept;` | the lock file named a dead holder |
| `stalePid` | `long stalePid() const noexcept;` | the pid it named |
| `release` | `void release();` | release the lock |

`Lock` is non-copyable, and its destructor releases.

### Endpoints

`Listener` is the server side: "bind, chmod 0600, listen."

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `listen` | `bool listen(const std::string& socketPath, std::string& error);` | bind and listen; the caller is expected to hold the `Lock` already |
| `acceptOne` | `int acceptOne(int timeoutMs);` | "Wait up to timeoutMs for a connection. -1 means 'nothing arrived'" |
| `fd` | `int fd() const noexcept;` | the listening descriptor |
| `path` | `const std::string& path() const noexcept;` | the bound path |
| `close` | `void close();` | "Close and unlink. Idempotent" |

A socket file left behind by a dead conductor is unlinked first — "but ONLY after
a `connect()` to it has been refused, so a live conductor's socket is never
removed by a second one racing it."

`Client` is the caller's side: "connect, one request at a time, replies read as
lines."

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `connect` | `bool connect(const std::string& socketPath, std::string& error);` | connect to a conductor |
| `close` | `void close();` | close the connection |
| `connected` | `bool connected() const noexcept;` | whether it is open |
| `call` | `bool call(const std::string& verb, const pf_JsonValue& args, Reply& reply, std::vector<pf_JsonValue>* events, std::string& error);` | send one request and read until a terminal reply |
| `socketPresent` | `static bool socketPresent(const std::string& socketPath);` | "Does something exist at this path, whether or not it answers?" |
| `socketAnswers` | `static bool socketAnswers(const std::string& socketPath);` | "Does a conductor answer at this path right now?" |

`call` distinguishes the two failures a caller must not confuse: it "returns
false only on a TRANSPORT failure; a well-formed error reply is returned through
`reply` with kind `Error`." Event lines are appended to `events` when the pointer
is non-null and dropped otherwise.

Both endpoint classes are non-copyable, and both close in their destructors.

### Line I/O

Exposed "because both endpoints need exactly this and a second copy would be a
second place for the framing to drift."

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| `writeAll` | `bool writeAll(int fd, const std::string& data);` | "Write every byte, retrying short writes. False on any error" |
| `readLine` | `int readLine(int fd, std::string& buffer, std::string& line, int timeoutMs);` | "Read one newline-terminated line, buffering whatever else arrived. Returns 1 on a line, 0 on timeout, -1 on EOF or error" |

### Exit status

`pf` is a thin client, and its own header lists what it returns:

| Status | Meaning |
|---|---|
| 0 | the verb succeeded |
| 1 | the conductor answered with an error, or could not be reached |
| 2 | usage |
| 4 | ambiguous selection in a non-interactive invocation |

Exit 4 is the one worth knowing about. A catalog search returns a ranked list,
always, and choosing among candidates belongs to the caller: a unique identity
match is used directly, and anything else is either prompted for interactively or
failed with the list printed. "A script that silently got whichever revision
ranked highest is a script that will one day run the wrong model."

## The DDS control plane

Once a problem is running, control reaches a service as a `pf_Command` inside a
`pf_Commands` collection, published over DDS. This is the surface `pf_Commands.h`
declares, and it is not the conductor protocol above.

### Document verbs and wire commands

A `pf.problem_command.v1` document names what an operator means; the wire
constant names what the service machine does. The design memo gives the mapping:

| Document verb | Wire command | Reaches | Meaning |
|---|---|---|---|
| `start` | `cmd_SOLVE` | master | begin a campaign |
| `pause` | `cmd_PAUSE` | any | stop responding or emitting at the round boundary; solve state preserved |
| `resume` | `cmd_RESUME` | any | clear the pause |
| `stop` | `cmd_HALT` | any | halt the active solve |
| `halt` | `cmd_STOP` | any | stop the process |
| `request_results` | `cmd_RESULTS` | master | emit the current envelope |

`stop`→`cmd_HALT` and `halt`→`cmd_STOP` are crossed deliberately: "The document
verbs are named for what an operator means; the wire constants are named for what
the 2021 machine does."

The document-side vocabulary is the enum on the input side:

```cpp
enum class pf_ProblemCommandVerb
{
    Start,
    Pause,
    Resume,
    Stop,
    Halt,
    RequestResults
};
```

Pause is a flag rather than a state. The memo records the reasoning: what pause
has to change "is not what state a service is *in* but whether it *answers*" — at
a subproblem, whether an arriving reduced-cost request is solved; at a master,
whether another pricing round is started. A paused subproblem answers with a
status record rather than falling silent, because "Silence already means
something on this channel: it is what a dead peer produces."

### The command collection

`pf_Commands` is an owning container of `pf_Command` objects that can be attached
to a published object or published itself.

| Member | Signature (verbatim) | Purpose |
|---|---|---|
| constructor | `pf_Commands();` | an empty collection |
| copy constructor | `pf_Commands(const pf_Commands& other);` | "Performs a DEEP COPY: every pf_Command is cloned, so the new pf_Commands shares no element with the source" |
| copy assignment | `pf_Commands& operator=(const pf_Commands& other);` | deep copy, as for the copy constructor |
| move constructor | `pf_Commands(pf_Commands&& other) noexcept = default;` | transfers ownership without cloning |
| move assignment | `pf_Commands& operator=(pf_Commands&& other) noexcept = default;` | the same |
| `setRecipient` | `void setRecipient(unsigned long long recipient);` | the service id that will receive this collection when it is published |
| `getRecipient` | `unsigned long long getRecipient();` | that id |
| `addCommand` | `void addCommand(pf_Command* pf_Command_ptr);` | add one command; **the collection takes ownership** |
| `setCommands` | `void setCommands(pf_Commands* pf_Commands_ptr);` | replace the contents with another collection's |
| `setCommands` | `void setCommands(vector<pf_Command*> pf_Commands_ptr);` | replace the contents with a vector's |
| `getCommands` | `vector<pf_Command*> getCommands();` | a **non-owning view** of the commands |
| `deleteCommand` | `int deleteCommand(pf_Command* pf_Command_ptr);` | delete the first command with the same command value; returns 1 if found |
| `clearCommands` | `void clearCommands();` | remove every command |
| `reset` | `void reset();` | remove every command and reset all members to defaults |
| `publish` | `int publish(pfMessenger::PF_COMMANDSDataWriter_var* dataWriter_ptr);` | publish the collection |

Ownership is the part to get right, and the header states it at length.
`addCommand` takes ownership and will delete the command, so the caller "must
therefore pass an object it is entitled to give away — in practice a fresh `new
pf_Command`, or `x.clone()`." Never the address of a stack object, and never a
pointer something else already owns.

`getCommands` returns raw pointers that "address commands owned by THIS
pf_Commands and stay valid only for as long as it does." The header names the
trap directly: never write `module->getCommands().getCommands()` into a variable,
"because the pf_Commands returned by a holder's getCommands() is a temporary and
takes its commands with it." Bind the collection to a named value first.

Because copies deep-clone rather than share, the by-value `setCommands`
signatures elsewhere in the runtime are "both leak-free and double-free-proof:
the callee owns its own copies and the caller may destroy its originals whenever
it likes."

!!! note
    A collection attached to a containing object — a module, say — is published
    with that object, and its own recipient is then ignored.
