# Backend adapter authoring guide

An adapter implements compute and isolation behind `workcell-backend/v1alpha1`. Workcell remains responsible for definition validation, semantic policy, workspace packaging, evidence normalization, declared artifact acceptance, receipt verification, failure classification, and cleanup intent. An adapter is not a scheduler, retry engine, policy interpreter, or provider-response proxy.

## Small contract

Ship a `workcell-backend-manifest/v1` file and one executable. The executable reads exactly one bounded JSON request from stdin and emits zero or more JSONL log events followed by exactly one result. It must implement:

1. `describe` without credentials or network;
2. `resolve` without provisioning and with one exact capability result per requirement;
3. idempotent, ownership-marked `provision`;
4. `prepare` that independently verifies the uploaded package digest;
5. argv-faithful `execute` with a terminal result and bounded/redacted log evidence;
6. complete `collect` evidence, including an honest workspace-delta completeness flag;
7. declared-only, bounded `export`;
8. idempotent ownership-checked `destroy`;
9. complete ownership-filtered `inventory` for recovery.

Cancellation is mandatory at the Workcell lifecycle level. An adapter may satisfy termination by destroying the run-owned sandbox; it must not claim graceful process cancellation unless it can prove it. Pause, resume, snapshot, log streaming, metrics, custom images, and provider cost are optional capabilities.

## Safety invariants

- Never accept provider policy inside the workload definition. Provider mechanics belong in a versioned host profile.
- Never silently drop a requirement. Return rejected or unknown capability evidence before provisioning.
- Use both `run_id` and the unpredictable ownership nonce on every resource. Inventory and destroy must match both.
- Handles contain stable opaque identifiers, never credentials, signed URLs, or unbounded provider JSON.
- Provider credentials are named by a manifest-advertised reference. Values must not enter argv, protocol payloads, fixtures, receipts, logs, or artifacts.
- Do not echo provider response objects. Select, bound, normalize, and redact every field.
- Confirm the remote archive digest before extraction. Treat provider upload success as transport evidence, not integrity evidence.
- Preserve Git path bytes where the provider transport permits them. If a provider cannot report a complete delta, advertise that limitation rather than returning `complete: true`.
- Download only the archive produced from Workcell's declarations. Enforce a transport bound before core extraction and verification.
- A failed or ambiguous provision leaves a recoverable ownership intent. Never delete resources based on a name, run ID, account listing, or caller assertion alone.

## Capability evidence

Each resolution entry distinguishes support, acceptance, resolved value, enforcement, observation, and limitations. `provider-claimed` means the adapter mapped a documented API request; it is not observation. `operator-claimed` requires an exact value in the selected host profile. `workcell-enforced` is reserved for a control Workcell itself can verify. Unknown evidence never becomes enforced evidence in a receipt.

Do not advertise a capability merely because a provider has a related feature. For example, a fixed two-GiB-per-vCPU class does not directly implement an arbitrary memory request, VM suspension is not process pause, and whole-workspace download is not selective artifact export.

## Distribution and supply chain

Keep heavyweight SDKs outside Workcell core. Pin dependency versions and lockfiles. The manifest should pin the executable digest; official adapters additionally need a reviewed runtime/dependency integrity chain, read-only installation, provenance for release artifacts, and scheduled drift tests. A community adapter can remain independently distributed; passing conformance establishes protocol compatibility, not endorsement or security certification.

## Required verification

Run the offline conformance suite and adapter-specific malformed-input, secret-canary, ownership-collision, timeout, output-bound, artifact traversal, digest-mismatch, partial-cleanup, and concurrent lifecycle tests. Live tests are opt-in and credential gated. They must use a tiny immutable fixture, strict resource/time/spend ceilings, unconditional destroy, final complete inventory with zero resources, and retained redacted evidence for the exact account, plan, region, adapter, SDK, and API version.

An adapter is eligible for official status only after offline conformance, clean-machine installation, live lifecycle evidence, capability-specific enforcement probes, orphan recovery, dependency review, and a named maintainer and deprecation policy all pass.
# Machine-readable conformance evidence

Offline conformance reports use `workcell-backend-conformance/v1`; the published
JSON Schema is [`schemas/workcell-backend-conformance-v1.schema.json`](../schemas/workcell-backend-conformance-v1.schema.json).
Passing this format proves bounded protocol behavior for the exercised fixture.
It does not certify provider isolation, network enforcement, tenancy, compliance,
retention, credential handling outside the adapter boundary, or operator security.
