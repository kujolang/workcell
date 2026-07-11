# Enterprise deployment boundary

Workcell's local MVP is now release-gated, digest/signature-aware, and bounded by Docker policy. The following controls remain deployment concerns because they depend on the Docker host, network, and operator trust model.

## Isolation

- Prefer a rootless Docker or Colima daemon for untrusted workloads where the image and workload compatibility permits it.
- For higher-risk multi-tenant workloads, place the daemon behind a VM, Kata/gVisor runtime, or microVM service. Workcell's container policy remains useful inside that stronger boundary, but it does not create the boundary itself.
- Keep the daemon socket private to the operator and do not mount it into workloads.

## Network and syscall policy

- Keep `network.mode` at `none` unless the definition explicitly requires network access.
- If `default` is required, enforce egress with a host firewall or transparent proxy; Workcell rejects inherited proxy and credential-selector variables but cannot force arbitrary child processes to honor a proxy.
- Docker's default seccomp and AppArmor profiles must remain enabled. Do not run the daemon with `seccomp=unconfined` or equivalent relaxed profiles for production workloads.
- `workcell doctor` verifies that Docker reports both seccomp and AppArmor; a non-rootless daemon is surfaced as a warning so operators can choose a rootless or VM/microVM boundary.

## Image trust

- Pin `runtime.image_digest` for every release definition.
- Set `runtime.signature_key` when the organization signs images with cosign. Workcell fails image preparation if the key is missing, cosign is unavailable, or verification fails.
- Manage public-key rotation, Rekor/transparency policy, registry authorization, and vulnerability scanning outside the Workcell definition.

## Secrets and evidence

- Prefer short-lived secret values and avoid exporting secret-bearing artifacts.
- Workcell redacts exact captured values and common base64 encodings after command completion. Hashed or otherwise transformed secret output requires workload-level controls or a streaming redaction layer in the process runtime.
- Retain receipts, logs, patches, and failure workspaces according to the organization's evidence-retention policy.
