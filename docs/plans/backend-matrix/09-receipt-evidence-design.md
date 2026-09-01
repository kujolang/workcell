# Receipt and evidence design

## Versioning

Use `workcell-receipt/v2alpha1` for external backends and the controls ledger. Keep current v1 receipts byte/meaning compatible for Docker/Podman during extraction. Once v2 stabilizes, Docker and Podman should emit v2 when a v2 definition is used.

## Core receipt shape

```json
{
  "schema_version": "workcell-receipt/v2alpha1",
  "run": {},
  "definition": {},
  "source": {},
  "backend": {},
  "workspace": {},
  "execution": {},
  "controls": [],
  "logs": {},
  "changes": {},
  "verification": {},
  "artifacts": {},
  "resources": {},
  "cost": {},
  "cleanup": {},
  "errors": [],
  "warnings": [],
  "lifecycle": []
}
```

## Required normalized fields

### Run and definition

- WorkCell product and contract versions, run/attempt ID, timestamps.
- original definition version/path/hash and normalized intent hash.
- selected profile ID and non-secret profile fingerprint.
- operator policy ID/digest when present.

### Source/workspace

- repository identity, exact source commit, clean-state proof.
- materialization strategy, workspace-package schema/digest/counts.
- provider-observed input digest, workspace root, delta/export boundaries.
- no provider-supplied repository URL containing credentials.

### Backend identity

- adapter ID/version/build/digest and backend-contract version.
- provider ID, API version/endpoint class, account/project fingerprint, region.
- provider resource/session/command IDs.
- substrate/runtime facts with authority: engine version, OCI runtime, sandbox class, Firecracker/gVisor/Kata provider claim, rootless/VM host observations.

### Execution

- redacted argv, working directory, environment and secret names.
- attempt ID, provider command ID, start/end/elapsed with clock authority.
- workload exit code, signal/reason, timeout/cancel/terminal-unknown.
- WorkCell failure category remains distinct from workload exit.

### Controls

For each material request: requested value/required flag, acceptance, resolved value, enforcement status/authority/evidence reference, observation status/method/result, limitations. Include controls omitted because they are unsupported when their absence affects interpretation.

### Logs

```json
{
  "capture": "streaming-with-recovery",
  "stdout_stderr": "separate",
  "ordering": "per-stream",
  "timestamps": "provider",
  "completeness": "partial",
  "truncated": true,
  "discontinuities": [{"after_sequence": 18, "reason": "reconnect"}],
  "bytes": {"stdout": 1000, "stderr": 200},
  "paths": {"stdout": "stdout.log", "stderr": "stderr.log"}
}
```

Never claim global stdout/stderr order unless the provider supplies a single ordered channel or WorkCell observed both streams at one source. Host arrival order is named `host-arrival`, not workload order. Buffered provider logs are not called streaming. Missing tail data after disconnect is partial.

### Artifacts and changes

- declared path, per-path result, bytes/files/depth, SHA-256 entries.
- provider archive/object reference only after redaction; local destination.
- transfer start/end, partial/failure status, compressed/expanded counts.
- Git change report and redacted patch generated from the portable baseline.
- secret scanning/redaction/rejection result without secret values.

### Resources and cleanup

- complete run-owned inventory: sandbox/VM/container, commands, snapshots, volumes, images, uploaded objects, log handles, temporary secrets.
- ownership marker/nonce evidence.
- per-resource cleanup status, attempts, provider response category, remaining cost-accruing state if known.
- recovery journal path and final reconciliation status.

### Metrics and cost

Each measurement has value, unit, interval, aggregation, source, and completeness. Requested CPU/memory is not observed use.

Cost states:

- `provider-reported` — provider returned amount/currency/window.
- `provider-usage-only` — billable dimensions/times returned, no amount.
- `deterministic-rate-calculation` — only when an immutable provider rate ID and exact formula are captured; not planned initially.
- `unknown` — default.

Do not emit invented estimates. Record cost class (`local-operator`, `per-second-compute`, `provisioned-storage`, `composite-platform`) and cost-accruing orphan warnings.

## Provider metadata

Core receipts are not provider response dumps. Optional `provider/` attachments must be:

- explicitly selected by adapter code;
- redacted and bounded;
- schema/API version labeled;
- hashed by the WorkCell manifest;
- referenced from normalized fields;
- free of credentials, signed URLs, environment values, and unrelated account inventory.

## Partial and failure evidence

Receipt checkpoints are atomic after resolve, provision, prepare, start, terminal result, collect, export, and cleanup. If the final write fails, the prior checkpoint plus recovery journal remains. A terminal-unknown run is never classified as workload success. Artifact collection failure cannot be hidden by a successful exit. Cleanup failure overrides the CLI lifecycle category as it does today, while preserving the original failure.

## Offline verification

`workcell verify` remains local and provider-independent. It validates the manifest, normalized receipt schema, workspace/artifact manifests, attachment references, and that no mutable/signed transport URLs were persisted. It does not contact the provider and does not retroactively prove provider isolation.

## v1 field migration

- `runtime_backend` becomes `backend.adapter_id` and `backend.provider_id`.
- container image/name fields move under backend/execution resources but remain as compatibility aliases for v1 Docker/Podman.
- `effective_security_policy` is retained in v1; v2 uses `controls[]`.
- `network_policy` becomes the normalized network control entry plus a concise resolved summary.
- `cleanup_status` expands into itemized cleanup and retains a summary.

