# Enterprise deployment boundary

Workcell 1.0 provides a stable, release-gated local Docker/Podman execution contract with digest/signature-aware image policy. It is not a universal enterprise-readiness or compliance claim. The following controls remain deployment concerns because they depend on the host, network, organization, and operator trust model.

## Isolation

- Leave `workspace.run_as` at its default `host` value for least-privilege owner-only bind-mount access on rootful engines. For rootless Docker or Podman, set `workspace.run_as` to `rootless`; Workcell then uses container `0:0`, which the rootless engine maps to its unprivileged daemon user, and fails closed if the engine mode does not match. Use a fixed non-root `uid:gid` only when the host can assign that ownership; Workcell refuses explicit root identities and fails closed when fixed ownership cannot be applied.
- Prefer a rootless Docker or Colima daemon for untrusted workloads where the image and workload compatibility permits it.
- For higher-risk multi-tenant workloads, place the daemon behind a VM, Kata/gVisor runtime, or microVM service. Workcell's container policy remains useful inside that stronger boundary, but it does not create the boundary itself.
- Keep the daemon socket private to the operator and do not mount it into workloads.

## Network and syscall policy

- Keep `network.mode` at `none` unless the definition explicitly requires network access.
- If `default` is required, declare `network.egress` with `policy: deny-by-default` or `operator-managed`, `dns`/`proxy` ownership, and a reviewed `enforcement_profile`; enforce it with a host firewall or transparent proxy. Workcell records the declaration and rejects inherited proxy and credential-selector variables, but cannot force arbitrary child processes to honor a proxy.
- For a reproducible controlled boundary, pre-create an internal or proxy-enforced Docker network and use `network.mode: custom` with its `network.name`; Workcell will attach only to that named network and will not create or mutate it.
- Treat `network.egress.policy: unmanaged` as a compatibility mode only. It is accepted for older definitions, produces a receipt warning, and is not sufficient release evidence.
- Docker's default seccomp and AppArmor profiles must remain enabled. Do not run the daemon with `seccomp=unconfined` or equivalent relaxed profiles for production workloads.
- `workcell doctor --backend docker|podman` verifies the selected engine; rootful Docker must report seccomp/AppArmor, while rootless Docker must report seccomp and may warn that AppArmor is not advertised. Podman must report an enabled seccomp profile and its rootless state, and may warn when AppArmor is unavailable. A non-rootless engine is surfaced as a warning so operators can choose a rootless or VM/microVM boundary.
- Set `filesystem.seccomp_profile` and `filesystem.apparmor_profile` only to profiles installed and reviewed on the target daemon; Workcell passes those names through and rejects `unconfined`.
- Use `trust_profile: native-guarded` to make runs fail closed on a non-rootless daemon; this does not provision the daemon or a microVM for you.

## Image trust

- Pin `runtime.image_digest` for every release definition.
- Set `runtime.require_digest: true`, `runtime.require_signature: true`, and an explicit `runtime.registry_allowlist` in release definitions so missing provenance or an unapproved registry fails validation instead of relying on operator convention.
- Set `runtime.signature_key` when the organization signs images with cosign. Workcell fails image preparation if the key is missing, cosign is unavailable, or verification fails.
- Manage public-key rotation, Rekor/transparency policy, registry authorization, and vulnerability scanning outside the Workcell definition.

## Secrets and evidence

- Prefer short-lived secret values and avoid exporting secret-bearing artifacts.
- Workcell redacts exact captured values and common base64 encodings incrementally while the process streams, before logs and receipts are persisted. Hashed or otherwise transformed secret output still requires workload-level controls.
- Retain receipts, logs, patches, and failure workspaces according to the organization's evidence-retention policy.

## Remote adapters and policy profiles

- Keep workload definitions provider-neutral. Select the backend through an operator-owned host profile and pin the adapter digest for approved environments.
- Set profile ceilings for CPU, memory, PIDs, timeout, output, workspace upload, and artifact download. A workload exceeding any ceiling fails before capability resolution or provisioning.
- Treat every receipt control separately as requested, accepted, enforced, and observed. Provider-claimed and operator-claimed enforcement is evidence of configuration, not an independently observed isolation result.
- Permit only reviewed adapter IDs, versions, digests, profile fingerprints, regions, projects, endpoints, and provider plans in deployment policy. Workcell validates the selected explicit profile but does not operate a fleet-wide allowlist service.
- Use `env:` credentials only for tightly scoped CI environments. The adapter manifest must advertise the exact reference. Kujo Agent and OS-store references require a separately reviewed host bridge; Workcell does not export secrets from `kujo agent auth` or silently fall back to ambient provider SDK discovery.
- Pass orchestrator correlation through `--context`; do not place retry policy, queue state, provider credentials, or model credentials in caller context.
- Keep provider control-plane credentials distinct from secrets intentionally injected into the workload. Prefer short-lived, project-scoped provider credentials and provider-native audit logging.

## Data governance and recovery

- Approve provider region, data residency, subprocess/log retention, backup, snapshot, and deletion behavior outside Workcell. A requested region is not observed residency unless the provider supplies suitable evidence.
- Inventory remote resources by both run ID and ownership nonce. Recovery must refuse incomplete inventory and ownership mismatches.
- Alert on `recovery-required`, failed cleanup, terminal-unknown, artifact partial failure, and receipt persistence failure. Dispatch or Relay may start a new correlated attempt; Workcell never retries a workload invisibly.
- Define evidence retention separately from provider resource retention. Workcell manifests prove local evidence integrity, not provider-side erasure.
- Run credential-gated provider smoke tests on a schedule and before adapter promotion. A passing smoke is scoped to its exact account, plan, region, adapter, SDK, and time.

## Operational release gate

Production promotion requires a clean-machine core suite, adapter integrity verification, offline conformance, capability-specific live probes, zero-orphan inventory, dependency and license review, rollback instructions, API-deprecation ownership, measured lifecycle latency, and an explicit spend ceiling. Unsupported or unknown security controls block the run; evidence-only metrics or cost may remain unknown if the profile permits no security degradation.

## Operator acceptance

Before an organization calls a deployment production-accepted, it must separately approve daemon and kernel hardening, tenant isolation, egress enforcement, image provenance and vulnerability policy, signing-key custody, retention and deletion, incident response, and applicable compliance controls. Workcell receipts can support that review but do not replace it or provide certification.
