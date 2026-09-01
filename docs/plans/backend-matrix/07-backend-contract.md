# Backend adapter contract

## Transport decision

Use a versioned executable protocol over stdin/stdout JSON Lines. Do not require in-process Kujo modules, a daemon, MCP, HTTP callbacks, or a provider SDK in WorkCell core.

Invocation:

```text
workcell-backend-<id> protocol
```

WorkCell writes one request envelope to stdin. The adapter writes zero or more bounded event envelopes followed by exactly one result envelope to stdout. Stderr is diagnostic-only, bounded, redacted, and never parsed as the contract. WorkCell starts a fresh adapter process for each operation; the provider handle carries durable state. This makes adapters language-neutral, locally inspectable, fixtureable, and killable.

## Envelope

```json
{
  "contract": "workcell-backend/v1alpha1",
  "request_id": "wc-request-...",
  "run_id": "wc-...",
  "operation": "resolve",
  "deadline_ms": 30000,
  "profile": {"id": "ci-remote", "config": {}},
  "payload": {}
}
```

Every result echoes `contract`, `request_id`, `run_id`, and `operation`, then supplies:

```json
{
  "type": "result",
  "ok": false,
  "status": "unsupported",
  "retryable": false,
  "error": {
    "code": "CAPABILITY_UNSUPPORTED",
    "message": "network.none is unavailable for this profile",
    "provider_code": "redacted-optional-code"
  },
  "data": {}
}
```

Provider response dumps are not `data`. A bounded, redacted raw attachment may be written to a WorkCell-provided output path and referenced by digest.

## Operations

### `describe`

No credentials or network required. Returns adapter ID/version/build, supported contract versions, credential reference names, static capability hints, implementation runtime requirements, and platforms. Hints are non-authoritative.

### `resolve`

Read-only. May authenticate and inspect account/host/profile/plan/region. Takes semantic execution intent and returns:

- provider/API/profile identity;
- per-capability resolution and limitations;
- resolved resource/image/network/workspace plan;
- estimated cost class only when provider semantics support it;
- volatile fields that must be rechecked;
- no secret values.

It must not create compute, snapshots, volumes, networks, object buckets, or images.

### `provision`

Creates or exclusively acquires the run resource. It is idempotent by `run_id + idempotency_key`. Returns an opaque handle, provider resource IDs, ownership markers, created time, expected expiration, and actual capability resolution. WorkCell persists the handle before calling another mutating operation.

### `prepare`

Transfers/materializes the workspace package and execution prerequisites. Returns the observed package digest and workspace root. It must not fetch a mutable Git branch unless the resolved plan explicitly uses the optional provider-clone capability. Multiple identical calls are idempotent.

### `execute`

Starts one command attempt. Payload contains argv, working directory, environment names/values separated into non-secret and one-shot secret channels, timeout, output limit, and attempt ID. Events may be:

```json
{"type":"event","event":"log","sequence":17,"stream":"stderr","bytes_base64":"...","provider_timestamp":null,"ordering":"per-stream"}
```

The terminal result includes provider process/command ID, exit code or null, signal/reason, timed-out/cancelled flags, stream byte counts/truncation/discontinuities, and start/end times with authority. A provider exception for non-zero exit is normalized into a successful protocol result with workload failure data.

### `cancel`

Optional graceful cancellation of the active command. It returns whether the process was signaled, killed, already terminal, or unknown. WorkCell invokes `destroy` when cancel is unsupported, times out, or cannot prove termination.

### `collect`

Collects normalized log recovery, workspace change metadata, resource observations, attempt inventory, and provider timing. It cannot select artifacts or decide verdicts. Log recovery states whether it duplicates streamed bytes, supplies provider timestamps, separates streams, is truncated, or has retention gaps.

### `export`

Takes normalized declared paths, limits, destination transport parameters, and the WorkCell exporter version. Returns one bounded archive plus manifest/digest or an explicit per-artifact failure. It must not return undeclared paths. Provider-direct object uploads are run-owned and enter the cleanup inventory.

### `destroy`

Idempotently terminates and removes run-owned compute plus adapter-created temporary objects. The request includes the durable handle and expected ownership markers. It returns an itemized result: `removed`, `absent`, `preserved`, `failed`, or `ownership-mismatch`. Ownership mismatch never retries as deletion.

### `inventory`

Lists resources carrying valid WorkCell ownership markers in the selected account/profile. Results include kind, ID, run ID, state, creation time, expiration, cost-accruing state if known, and ownership evidence. It does not mutate.

### Optional operations

`pause`, `resume`, and `snapshot` are extension operations and require capabilities with precise semantics. A disk snapshot does not advertise process pause. `metrics` may be separate when provider collection is asynchronous; normal `collect` may otherwise return it.

## Handle rules

The handle is opaque to core for provider-specific fields but uses a common wrapper:

```json
{
  "backend": "e2b",
  "adapter_version": "x.y.z",
  "provider": "e2b",
  "profile_fingerprint": "sha256:...",
  "resource_ids": [{"kind":"sandbox","id":"..."}],
  "ownership": {"run_id":"wc-...","nonce":"..."},
  "provider_state": {}
}
```

Core validates wrapper identity, size, and redaction; only the same adapter ID/compatible version/profile may consume provider state. Handles never contain credential values, signed file URLs beyond their immediate operation, or unbounded responses.

## Error taxonomy

Adapters return stable codes mapped by core:

- `ADAPTER_UNAVAILABLE`, `AUTH_REQUIRED`, `AUTH_DENIED`
- `PROFILE_INVALID`, `CAPABILITY_UNSUPPORTED`, `CAPABILITY_DRIFT`
- `QUOTA_EXCEEDED`, `RATE_LIMITED`, `REGION_UNAVAILABLE`
- `PROVISION_FAILED`, `PREPARE_FAILED`, `START_FAILED`
- `TRANSPORT_DISCONNECTED`, `PROVIDER_TIMEOUT`, `WORKLOAD_TERMINAL_UNKNOWN`
- `COLLECT_FAILED`, `EXPORT_FAILED`
- `OWNERSHIP_MISMATCH`, `DESTROY_FAILED`, `PROVIDER_UNAVAILABLE`
- `PROTOCOL_VIOLATION`, `ADAPTER_INTERNAL`

`retryable` is evidence, not permission to retry the workload. WorkCell core never reruns a workload. Dispatch or another orchestrator may start a new WorkCell run/attempt under its own policy.

## Backpressure and bounds

- Protocol lines, event count, bytes, and wall time are bounded by WorkCell.
- Log bytes are decoded incrementally, redacted before persistence, and truncated at the core bound even if provider limits fail.
- Adapter protocol stdout may contain only JSON Lines; accidental SDK logging is a protocol violation.
- WorkCell closes stdin after the request. Adapter process cancellation cannot be treated as provider resource termination; recovery uses the durable handle.

## Conformance contract

An adapter passes base conformance only if all mandatory operations, idempotency, ownership, redaction, partial failure, and offline fixtures pass. Capability-specific suites are selected from the execution-time resolution, not the manifest hint. The machine-readable proposal is `BACKEND_CONTRACT_PROPOSAL.json`.

