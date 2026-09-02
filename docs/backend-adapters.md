# Provider-neutral backend adapters

## Status and boundary

The external-backend surface is alpha and additive. Existing version 1 definitions still use the stable Docker/Podman path without reinterpretation. Workcell owns definition validation, semantic requirements, clean-source packaging, declared artifacts, evidence, failure categories, and ownership-safe cleanup. An adapter owns provider API calls, compute provisioning, workspace transport, command execution, provider log collection, and deletion of the exact resources in its handle.

External adapters communicate through `workcell-backend/v1alpha1`: one bounded JSON request on stdin, zero or more JSONL events, and exactly one result. Request envelopes reject unknown fields, operation payloads are validated before launch, and successful results are checked against operation-specific response shapes before core consumes them. Workcell never downloads or auto-discovers an adapter. The operator supplies a local manifest explicitly; official manifests are digest-pinned.

The canonical lifecycle is:

```text
resolve → provision → prepare → execute → collect → export → destroy → record
```

Resolve is mandatory and occurs before provisioning. Cancel and inventory are first-class operations; inventory supports crash recovery. Pause, resume, snapshot, and metrics are optional capabilities and are not part of the portable success path.

## Install official adapters

The official adapters are external Node packages so provider SDK dependencies do not enter Workcell core:

```bash
cd adapters/official
npm ci --ignore-scripts
npm test
```

Versions are pinned by `package-lock.json`. E2B uses `e2b` 2.46.1, Vercel uses `@vercel/sandbox` 3.2.1, and Daytona uses `@daytona/sdk` 0.207.1. Live-provider API drift is not covered by offline fixture success.

## Definition and host profile

The v2 definition contains workload semantics only. Provider, region, account, credential reference, and provider template belong in an explicit host profile:

```json
{
  "schema": "workcell-host-profiles/v1alpha1",
  "profiles": {
    "remote": {
      "backend": "e2b",
      "credential_ref": "env:E2B_API_KEY",
      "adapter_options": {
        "e2b": {
          "template": "base",
          "guarantees": {
            "compute.cpu_limit": 1,
            "compute.memory_limit": "512m",
            "compute.pid_limit": 64,
            "filesystem.read_only_root": true,
            "filesystem.tmpfs": ["/tmp"],
            "filesystem.writable_paths": ["/workspace"],
            "image.oci": "alpine:3.20"
          }
        }
      },
      "policy": {}
    }
  }
}
```

Docker and Podman profiles are built in and require no adapter manifest. The portable coordinator translates the v2 workload into the stable v1 OCI policy/lifecycle, then normalizes the resulting evidence into receipt v2. Built-in profile options are limited to `engine_runtime` (for example `runsc` or a configured Kata runtime) and `workspace_run_as`; remote routing and credentials are rejected. Domain allowlists are not mapped to an OCI custom network and fail capability resolution because Docker/Podman alone cannot provide equivalent semantics.

Operator guarantees are visible as `operator-claimed` with `operator-profile` authority and remain `not-observed` until separate evidence exists. They are never relabeled `workcell-enforced` or `provider-claimed`. Remove any guarantee the deployment cannot substantiate; strict resolution will then reject the run before provisioning.

Inspect and run with explicit inputs:

```bash
./bin/workcell inspect \
  --file workcell.v2.json \
  --profiles host-profiles.json \
  --profile remote \
  --manifest adapters/official/e2b/manifest.json \
  --json

./bin/workcell run \
  --file workcell.v2.json \
  --repo . \
  --profiles host-profiles.json \
  --profile remote \
  --manifest adapters/official/e2b/manifest.json \
  --json
```

Credential references may use `env:`, `kujo-agent:`, or `os-store:` syntax. The bundled adapters currently resolve only `env:` references. Workcell passes only the named environment variable to the adapter process; the value is not placed in the definition, profile, request payload, receipt, log, or artifact. Kujo Agent/OS-store resolution requires a host bridge and must fail rather than fall back to ambient credentials.

Orchestrators may pass `--context <path>` with a `workcell-caller-context/v1` JSON object. Only bounded identifiers (`caller`, required `correlation_id`, and optional workflow, step, attempt, and causation IDs) are accepted. Context is copied into receipt evidence; it cannot carry provider options, credentials, retry policy, or workload semantics.

Host routing fields are normalized identically by `inspect` and `run`. `region` and `provider_project` are bounded control-free strings. Custom endpoints require HTTPS; loopback HTTP is accepted only with `policy.allow_insecure_loopback_endpoint: true` for explicit local development. Embedded URL credentials, fragments, whitespace, backslashes, unknown policy keys, malformed credential names, and non-object adapter options fail during profile loading.

Operator profiles may impose preflight ceilings with `max_cpus`, `max_memory_mb`, `max_pids`, `max_timeout_ms`, `max_output_bytes`, `max_workspace_upload_bytes`, and `max_artifact_download_bytes`. Inspect and run apply the same checks before adapter resolution or provisioning. These are deterministic resource/transfer ceilings, not monetary estimates or concurrency promises.

An adapter also rejects normalized routing fields it does not implement. The current E2B and Vercel adapters reject non-empty endpoint, region, and provider-project overrides; Daytona accepts endpoint and region but rejects provider-project. This prevents an inspect result from implying that ignored placement or account routing took effect.

## Strict capability negotiation

Every requested control is required by default. Unknown, unsupported, not enforceable, unproved conditional, or semantically changed controls reject before provision. An adapter cannot accept a request with `unknown`, `unsupported`, or `not-enforceable` enforcement, and an accepted resolved value must exactly match the requested semantic value in this alpha contract. There is no global best-effort mode and no backend-name shortcut. Only exact non-security evidence capabilities may use an operator-approved degradation list in future compatible versions.

The receipt control ledger records:

- the requested semantic value;
- acceptance (`accepted`, `rejected`, `degraded`, or `not-requested`);
- the resolved value;
- enforcement status and authority;
- observation status and method;
- explicit limitations.

## Workspace, artifacts, logs, and recovery

Remote input is a one-commit shallow clone of a clean Git source. Workcell removes the remote, disables hooks and credential helpers, rejects submodules and Git LFS pointer-only inputs, hashes every file, and bounds files, expanded bytes, and depth. It never uploads a dirty ambient directory by default.

Adapters export a tar containing only declared paths. Workcell treats the download as untrusted: it rejects traversal and non-regular entry types, extracts into run-owned staging, re-exports through local declaration/extension/size/secret policy, computes a fresh manifest and SHA-256 digest, and removes staging. Entire-workspace download is not supported.

JSONL events preserve per-stream order only. Receipt v2 says `buffered-protocol`; it does not claim global stdout/stderr ordering or provider timestamps. Provider adapters must not advertise real-time streaming until the core transport exposes it.

Portable receipts record separate WorkCell-monotonic durations for resolve, workspace packaging, provisioning, preparation, execution, verification, collection, artifact export/verification, cleanup, and total-before-record. These timings measure the client-observed phase and do not pretend to separate provider queue/cold-start time without provider evidence.

Adapters may classify the provider billing shape, but `amount` stays null and cost status stays `unknown` unless the provider reports usage or money for the exact run with a source and billing window. The official E2B, Vercel, and Daytona adapters currently report only `per-second-compute`, `composite-platform`, and `provisioned-compute` classes respectively; they do not estimate charges.

Before provision, Workcell writes `workcell-recovery/v1` with the run ID, nonce, backend identity, profile fingerprint, and idempotency key. It attaches the owned handle before upload. A lost provision response remains `recovery-required`; recovery inventories by the exact ownership tuple and can synthesize a one-use cleanup handle only from matching provider inventory. If a client dies or cleanup fails, use:

```bash
./bin/workcell recover \
  --journal .workcell/runs/<run-id>/recovery/<run-id>.json \
  --manifest adapters/official/e2b/manifest.json \
  --profile resolved-adapter-options.json \
  --dry-run --json
```

Recovery inventories first, requires a complete inventory response, and refuses any resource whose run ID or ownership nonce differs. It passes only explicitly referenced provider credentials to the adapter and redacts them at the protocol boundary. It never deletes persistent volumes, snapshots, images, or provider resources absent from the run handle or a handle-less intent's exact owned inventory.

## Adapter conformance and live gates

`tests/official_adapters_test.kujo` runs the base suite against all official adapters in deterministic fixture mode. It proves repeated provisioning is idempotent, timeout normalization is terminal, unsafe artifact paths fail, and owned inventory is empty after destroy in addition to the complete mandatory lifecycle. `npm test --prefix adapters/official` tests protocol framing, ownership, lifecycle results, credential failure, integrity tampering, a deterministic malformed-request corpus, and concurrent ownership-isolated fixture lifecycles with zero leaks. Linux CI exercises Docker and Podman; macOS CI runs the offline VM/interpreter and official-adapter contracts. Capability-specific and live tests must be gated by explicit credentials and should preserve a verified receipt plus zero-resource inventory for the exact adapter/provider version.

Live official adapters independently hash the uploaded workspace archive before extraction, collect a complete Git status delta, bound normalized log evidence, and require both the run ID and nonce on recovery inventory. A provider listing that omits either ownership marker is ignored rather than treated as Workcell-owned. Vercel's native resource request directly represents vCPU but not arbitrary memory; memory is rejected unless the selected operator profile supplies an exact reviewed guarantee.

Conformance proves the adapter follows the tested machine contract. It does not certify the provider, host, network, tenant isolation, data retention, or operator profile.

## Built-in and support decisions

- Docker and Podman: built into core for compatibility and zero-dependency local use.
- E2B, Vercel Sandbox, Daytona: official external adapters.
- Modal and Runloop: candidates for later official adapters after the first live remote gates.
- Cloudflare Sandbox and Kubernetes Agent Sandbox: operator adapters after their runtime/deployment contracts stabilize.
- Fly Machines, Nomad, containerd: community/operator integrations only.
- Kata and gVisor: substrate/runtime profiles under OCI or Kubernetes, not top-level providers.
- raw Firecracker, hosted development workspaces, and WASI: deliberately unsupported by this workload contract.
