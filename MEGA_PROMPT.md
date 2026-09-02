# WorkCell Backend Matrix Productionization Mega Prompt

You are the senior implementation agent responsible for taking the current
WorkCell provider-neutral backend matrix from its existing alpha implementation
to a releaseable, production-grade, enterprise-operable product.

This is an implementation assignment, not a new architecture research project.
The architecture has already been researched and decided. Read the source of
truth, verify the current repository state, then implement the remaining work in
dependency order. Do not replace the design with a generic cloud abstraction,
provider-specific workload definitions, or a hosted control plane.

Work persistently until every locally implementable item is complete and
verified. Live-provider certification, publishing, signing, marketplace actions,
or other external effects require explicit authorization and appropriate
credentials. When one of those is unavailable, implement and verify the complete
gate, fixture, documentation, and safe resume path; record the external blocker
honestly; then continue with independent work.

## Mission

Deliver this product boundary:

> Same bounded WorkCell workload contract. Different execution provider.

And preserve this ownership rule:

> WorkCell owns the execution contract, policy, evidence, verification,
> portability, recovery, and cleanup lifecycle. Providers own compute,
> transport, and physical isolation.

The final system must support production-quality local Docker and Podman,
individually certified official remote adapters, safe third-party adapters, easy
operator onboarding, honest receipts, clean-machine installation, and explicit
enterprise operational gates. It must never imply that a provider is safer than
the available evidence proves.

## Current repository baseline

Do not assume the project is starting from zero. Inspect the repository and
confirm the current commit before changing anything. At the time this prompt was
written, the following existed on `main`:

- stable WorkCell 1.x Docker/Podman behavior;
- additive `workcell-definition/v2alpha1`;
- additive `workcell-backend/v1alpha1` executable JSONL protocol;
- additive `workcell-receipt/v2alpha1`;
- strict semantic capability negotiation;
- built-in portable Docker and Podman paths;
- clean one-commit portable workspace packaging;
- bounded declared-only artifact archives;
- controls-ledger evidence and offline receipt verification;
- durable ownership handles, recovery journals, inventory, and `recover`;
- bounded adapter I/O, protocol validation, redaction, and integrity pinning;
- deterministic offline conformance and adversarial fixtures;
- official alpha adapters for E2B, Vercel Sandbox, and Daytona;
- compact `workcell-inspect-summary/v1` and `workcell-run-summary/v1` outputs;
- Linux and macOS CI plus Docker/Podman integration gates;
- scheduled offline SDK dependency drift reporting;
- a complete backend architecture package under
  `docs/plans/backend-matrix/`.

The following are not established merely because adapter code exists:

- live-provider certification;
- provider security certification;
- exact plan/region/account capability evidence;
- published installable adapter packages;
- OAuth, Kujo Agent auth, or OS credential-store bridges;
- provider marketplaces or partnership listings;
- universal production or enterprise readiness;
- Modal, Runloop, Cloudflare Sandbox, or Kubernetes Agent Sandbox adapters.

The current official adapter npm package may still be private and repository-
local. Offline fixture success must never be presented as live-provider proof.

## Required reading

Read these files completely before implementation:

1. `AGENTS.md`
2. `README.md`
3. `CHANGELOG.md`
4. `VERSION`
5. `RUNTIME_VERSION`
6. `docs/security-model.md`
7. `docs/enterprise-deployment.md`
8. `docs/workcell-definition.md`
9. `docs/runtime-lifecycle.md`
10. `docs/backend-adapters.md`
11. `docs/adapter-authoring.md`
12. `docs/api-compatibility.md`
13. `docs/known-limitations.md`
14. `docs/development.md`
15. `docs/release-process.md`
16. `docs/launch-checklist.md`
17. every file under `docs/plans/backend-matrix/`
18. `adapters/official/README.md`
19. adapter manifests, launchers, runtime modules, tests, and lockfiles
20. `.github/workflows/*.yml`
21. all relevant `src/backend/`, `src/execution/`, `src/evidence/`,
    `src/recovery/`, `src/receipts/`, `src/workspace/`, and artifact modules
22. all relevant tests and fixtures

Treat `docs/plans/backend-matrix/BACKEND_CONTRACT_PROPOSAL.json`,
`CAPABILITY_MATRIX.json`, `BACKEND_MATRIX.json`, `IMPLEMENTATION_PLAN.md`,
`ACCEPTANCE_CRITERIA.md`, and `RISK_REGISTER.md` as architecture inputs. Resolve
documentation drift against verified code and current official provider behavior;
do not silently invent a competing contract.

## Non-negotiable architecture

The canonical mandatory lifecycle is:

```text
resolve -> provision -> prepare -> execute -> collect -> export -> destroy -> record
```

Verification is core-owned. Inventory and cancellation are first-class lifecycle
support. Pause, resume, snapshot, provider Git clone, metrics, and exact cost are
optional capabilities, not mandatory portable semantics.

WorkCell core owns:

- definition and profile validation;
- semantic capability requirements and strictness;
- source/workspace identity and clean-source packaging;
- CPU, memory, PID, disk, timeout, output, mount, writable-path, and network intent;
- environment and workload-secret intent;
- declared artifact policy;
- receipt and manifest schemas;
- evidence authority and failure classification;
- local artifact verification and hashing;
- ownership-scoped recovery and cleanup rules;
- offline verification;
- compatibility and release gates.

Adapters own only provider-varying mechanics:

- provider API/SDK calls;
- provisioning and provider handles;
- workspace upload/materialization;
- process start and provider terminal status;
- provider log retrieval;
- selective archive transport;
- provider resource inventory;
- deletion of the exact resources they own.

Do not:

- add `e2b`, `vercel`, `daytona`, or other provider blocks to workload schemas;
- branch core policy on provider names;
- silently drop or reinterpret requested controls;
- introduce a generic best-effort security mode;
- infer enforcement from provider marketing or a backend name;
- place credentials in definitions, profiles committed to source, protocol
  payloads, argv, receipts, logs, manifests, artifacts, or fixtures;
- retry workloads inside an adapter;
- let a scheduler create hidden workload attempts;
- download entire remote workspaces by default;
- delete resources without exact run ID, nonce, account/profile, and ownership
  agreement;
- treat gVisor, Kata, Firecracker, Lima, or Colima as equivalent top-level
  providers;
- add pause/resume to the canonical success path;
- build automatic cost/speed/security routing;
- build a hosted Kujo control plane, scheduler, VM manager, CI service, billing
  system, Docker replacement, Kubernetes replacement, or Temporal replacement;
- add mandatory daemons or a mandatory Kujo-hosted service.

## Evidence vocabulary

Every material control must remain distinguishable as applicable:

- requested;
- required;
- accepted;
- resolved;
- rejected;
- degraded only where explicitly permitted for non-security evidence;
- WorkCell-enforced;
- provider-claimed;
- operator-claimed;
- observed;
- not observed;
- unsupported;
- not enforceable;
- unknown;
- contradicted.

Unknown, unsupported, not-enforceable, contradicted, or semantically changed
required controls must reject before provisioning. A narrow observation does not
upgrade a broad provider claim. Receipt wording tests must prevent accidental
overstatement.

## Working rules

- Preserve all user changes and unrelated dirty work.
- Use small, reviewable, dependency-ordered commits.
- Keep each repository clean when a phase is handed off.
- Do not force-push, rewrite history, discard changes, publish, tag, deploy, sign,
  or use live credentials without explicit authorization.
- Prefer Kujo and stable HTTP protocols. Keep provider SDKs outside WorkCell core.
- Pin unavoidable adapter runtimes and dependencies exactly.
- Keep normal development and conformance offline.
- Use deterministic fixtures; gate all billable/live activity explicitly.
- Keep machine contracts small, strict, versioned, and reviewable.
- Keep core dependencies minimal.
- Prefer `inspect --summary` and `run --summary` for agent loops. Read full receipts
  only when detailed evidence is required.
- Do not paste large receipts, provider payloads, logs, matrices, or dependency
  trees into agent context.
- Update docs, examples, schemas, changelog, and tests in the same phase as the
  behavior they describe.
- Never weaken Docker/Podman behavior to accommodate a remote provider.
- Never claim completion for an external gate that was skipped.

## Required implementation tracking

Create or update `docs/plans/backend-matrix/IMPLEMENTATION_STATUS.md` as the
single human-readable execution ledger. It must:

- distinguish implemented, verified offline, verified live, blocked, deferred,
  deliberately unsupported, and released;
- name exact evidence commands and artifacts;
- name the account plan, region, adapter version, SDK/API version, and date for
  live claims;
- link each blocker to a safe resume command;
- avoid duplicating the machine-readable backend and capability matrices;
- never mark a provider production-ready based only on fixture conformance.

Update the status ledger at the end of every phase.

# Dependency-ordered implementation program

## Phase 0: Audit and freeze the current baseline

Goal: establish exactly what is already implemented and prevent regressions.

Tasks:

- inspect the worktree, recent commits, CI, current schemas, adapters, tests, and
  documentation;
- run the full offline suite before changing behavior;
- record current Docker/Podman policy, lifecycle, exit, receipt, artifact,
  cleanup, and recovery fixtures;
- record current provider-neutral schemas and conformance results;
- classify every prior checklist item as implemented, partial, missing, blocked,
  deferred, or unsupported;
- create the implementation status ledger;
- record initial performance samples for validate, inspect, dry-run, Docker, and
  Podman where approved engines are available;
- identify discrepancies between code and the backend-matrix documents;
- fix only clear documentation/test drift in this phase.

Exit criteria:

- baseline gates pass;
- status ledger is reviewed against source;
- no current capability is overstated;
- Docker/Podman public behavior is frozen by regression evidence.

## Phase 1: Build the protected live-provider certification harness

Goal: create one reusable, safe, provider-independent system for exact live
evidence before adding more adapters.

Implement:

- explicit gates such as `WORKCELL_LIVE_E2B=1`;
- protected-environment CI entrypoints that never expose secrets to fork PRs;
- unique run IDs and ownership nonces;
- strict maximum runtime, concurrency, upload, download, log, and spend bounds;
- immutable tiny test workloads;
- version capture for WorkCell, adapter, provider SDK/API, account plan, region,
  image/template, and profile fingerprint;
- lifecycle cases for success, non-zero exit, timeout, cancel, disconnect,
  provider error, quota/rate limit, lost provision response, and lost destroy
  response;
- exact clean workspace upload and digest verification;
- bounded log-quality evidence;
- declared-only artifact export and local verification;
- offline receipt verification;
- final destroy plus complete zero-owned-resource inventory;
- secondary-resource inventory for objects, snapshots, volumes, images, tasks,
  and provider-specific resources;
- redacted evidence bundles outside Git;
- explicit skipped/blocked results when credentials or authority are absent.

Security probes must include, where safely supported:

- DNS;
- direct IPv4 and IPv6;
- metadata endpoints;
- private/link-local addresses;
- redirects;
- provider control-plane exceptions;
- secret canaries in SDK errors, debug logs, protocol events, receipts, patches,
  manifests, and artifacts.

Add deterministic offline fixtures for every live-test branch. Live workflows
must be narrow and manually or schedule-gated. No normal test may require cloud
credentials.

Exit criteria:

- the harness can certify a fixture provider end to end;
- no test can run billable work accidentally;
- every run ends with verified cleanup or a durable recovery-required result;
- evidence is bounded, redacted, exact-versioned, and offline-verifiable.

## Phase 2: Certify and harden E2B

Goal: make E2B the first complete remote production candidate and prove the
architecture with one real provider.

Implement and verify:

- live authentication through an explicit credential reference;
- account/project identity confirmation;
- idempotent provisioning;
- clean package upload and remote digest verification;
- argv-safe process execution;
- success and non-zero terminal results;
- bounded stdout/stderr and disconnect recovery;
- timeout, graceful cancel where available, forced termination, and destroy;
- `network.none` resolution and negative probes;
- CPU, memory, PID, disk, timeout, output, image/template, and writable-path
  claims individually;
- selective artifact export with local revalidation;
- inventory, lost-response recovery, TTL behavior, and zero owned orphans;
- snapshot/object inventory even if snapshots are not advertised;
- exact provider identity and provider-claimed isolation wording;
- cold/warm provision, upload, first-log, execution, export, cleanup, and total
  phase benchmarks;
- provider-reported cost/usage when exact, otherwise unknown amount;
- rate-limit, quota, auth-expiry, provider outage, and pagination behavior.

Do not advertise E2B domain allowlisting until exact supported semantics and
negative tests pass. Do not convert a provider Firecracker statement into
WorkCell-enforced evidence.

Deliver:

- live and offline test suites;
- E2B capability/certification report;
- limitations document;
- five-minute clean-machine onboarding guide;
- safe credential setup, rotation, revocation, recovery, and uninstall guidance.

Exit criteria:

- the same v2 workload succeeds through Docker and E2B by profile change only;
- repeated live runs leave zero owned resources;
- receipt and manifest verify offline;
- all advertised E2B controls have exact evidence;
- all unknown security controls reject;
- E2B is marked production candidate, not production, until packaging and release
  gates also pass.

## Phase 3: Certify and harden Vercel Sandbox

Goal: prove the architecture against a second independent remote provider.

Implement and verify:

- supported OIDC/access-token acquisition, expiry, and refresh;
- account/team/project identity confirmation where supported;
- non-persistent sandbox creation;
- preview/public exposure disabled unless explicitly requested and authorized;
- vCPU resolution;
- memory rejection unless the selected profile has an exact reviewed guarantee;
- network-none and allowlist behavior with negative probes;
- command cancellation versus whole-sandbox termination;
- log recovery after disconnect;
- bounded file upload/download and declared artifacts;
- snapshot and secondary-resource inventory;
- REST/SDK pagination, error, version, and deprecation behavior;
- zero-owned-resource cleanup and recovery;
- cold/warm performance and exact/unknown cost evidence.

Deliver the same certification, limitations, onboarding, credential, recovery,
and uninstall artifacts required for E2B.

Exit criteria:

- conformance and exact-version live matrices pass;
- repeated runs prove zero owned resources;
- provider claims remain labeled as claims;
- marketplace work remains a separate explicit product/distribution phase.

## Phase 4: Certify and harden Daytona

Goal: prove conditional capabilities, sandbox classes, tiers, and self-hosted
profiles without weakening the contract.

Implement and verify separately:

- hosted Daytona;
- self-hosted Daytona;
- custom endpoint HTTPS, CA, and TLS policy;
- region selection;
- account/tier/class resolution;
- explicit ephemeral mode;
- container-versus-VM evidence;
- tier-specific network-none and allowlist behavior;
- rejection of tiers that cannot satisfy required controls;
- upload, execution, logs, artifacts, cancel, destroy, and recovery;
- volumes, snapshots, archives, signed transfer URLs, and secondary inventory;
- signed URL and token redaction;
- zero-owned-resource cleanup;
- per-class and per-region performance/cost evidence.

Deliver hosted and self-hosted certification reports, limitations, onboarding,
credential, recovery, and uninstall guides.

Exit criteria:

- conditional capability drift fails closed;
- container/VM distinctions are receipt-visible;
- hosted and self-hosted claims never share evidence incorrectly;
- repeated live runs prove zero owned resources.

## Phase 5: Close contract gaps and stabilize v2

Goal: incorporate only changes demanded by real multi-provider evidence, then
freeze the public provider-neutral contracts.

Tasks:

- reconcile live findings across Docker, Podman, E2B, Vercel, and Daytona;
- remove accidental provider-specific assumptions;
- finalize lifecycle, capability, error, log-quality, cost, recovery, receipt,
  profile, and manifest semantics;
- specify adapter protocol version negotiation;
- specify minimum/maximum compatible WorkCell and contract versions;
- specify additive field and strict input rules;
- publish final machine-readable JSON schemas;
- add golden fixtures for every released schema;
- add alpha-to-beta/stable migrations;
- test old WorkCell/new adapter and new WorkCell/old adapter combinations within
  the support policy;
- retain permanent v1 Docker/Podman compatibility gates;
- decide whether real-time streaming is required for stable v2.

If streaming is required, implement bounded streaming with backpressure,
disconnect markers, truncation, per-stream ordering, optional provider
timestamps, and receipt-visible completeness. Do not claim global stdout/stderr
ordering unless it is actually available.

Exit criteria:

- schemas and compatibility policy are complete;
- two independent remote providers validate the contract;
- no live-discovered ambiguity remains hidden;
- beta identifiers and migration notes are ready.

## Phase 6: Core robustness, fuzzing, and scale

Goal: harden host-side behavior against crashes, malformed adapters, resource
exhaustion, and high concurrency.

Implement and test:

- crash injection after every checkpoint;
- disk-full, permission, interrupted-write, receipt-write, and cleanup-write
  failures;
- malformed, oversized, secret-bearing, and cyclic provider metadata;
- concurrent recovery and destroy races;
- idempotency across client restarts;
- inspect-to-provision capability drift and contradiction handling;
- protocol, schema, manifest, profile, archive, receipt, path, and Unicode fuzzing;
- archive bombs, extreme compression ratios, hardlinks, devices, FIFOs, symlinks,
  traversal, absolute paths, duplicates, overlaps, case collisions, and Unicode
  normalization;
- sustained concurrency, memory, file descriptor, process, and temporary-file
  leak tests;
- malicious/noisy/hung/substituted adapters;
- bounded redacted diagnostics bundles;
- clean failure under provider inventory pagination or incompleteness.

Benchmark:

- validation, inspect, and dry-run overhead;
- small, medium, and maximum source packages;
- artifact export/download;
- peak memory;
- log throughput/backpressure;
- concurrency and rate-limit behavior;
- checkpoint and recovery latency.

Set reviewed regression budgets before enforcing them. Do not invent thresholds
after a failure merely to make a gate pass.

Exit criteria:

- critical fuzz/adversarial cases fail closed;
- no unexplained leaks remain;
- regression budgets are documented and gated;
- full deterministic suites remain token- and time-efficient enough for normal
  agent development.

## Phase 7: Package and secure official adapters

Goal: replace repository-local/private installation with immutable, reviewable,
clean-machine distribution while keeping installation explicit.

Decide and document whether adapters ship as independent packages/repositories or
as separately versioned artifacts. Prefer independent release cadence when SDK
drift or dependency weight justifies it.

Implement:

- non-private release-ready packages;
- exact runtime and dependency support policy;
- immutable release archives/packages;
- checksums;
- signatures when explicitly authorized;
- build provenance;
- SBOMs;
- dependency vulnerability and license gates;
- lockfile-to-installed-tree verification;
- read-only production installation guidance;
- Linux x64/ARM64 and macOS x64/ARM64 clean-install tests where supported;
- adapter rollback, revocation, and emergency denylist procedures;
- digest and contract compatibility checks before execution;
- reproducible offline installation where practical;
- release artifacts that do not require hidden downloads or a hosted registry.

Do not publish, sign, or create public releases without explicit approval. Build
and verify release candidates locally and in CI first.

Exit criteria:

- clean machines can install and verify each adapter without a repository-local
  `node_modules` tree;
- tampering and incompatible versions fail closed;
- rollback and revocation are tested;
- distribution does not add a mandatory Kujo service.

## Phase 8: Authentication and onboarding

Goal: make a first verified run straightforward without weakening credential
boundaries.

Implement:

- environment credential references for CI;
- Kujo Agent credential-store bridge;
- supported OS credential-store bridge;
- provider-native OAuth/OIDC where appropriate;
- short-lived credentials and refresh behavior;
- least-privilege scope documentation;
- account/project confirmation;
- credential expiry, rotation, and revocation diagnostics;
- enterprise proxy, private endpoint, CA bundle, and TLS inspection handling;
- provider-aware `doctor` checks for runtime, adapter integrity, credential
  presence, account identity, reachability, plan/tier, and profile support;
- reviewed host-profile templates;
- setup flows that keep provider mechanics outside the workload definition;
- actionable errors for auth, quota, region, plan, unsupported control, endpoint,
  and cleanup failures;
- safe uninstall and rollback;
- GitHub Actions and common CI examples;
- a first-run path from clean machine to offline-verified receipt;
- measured onboarding time and documented target.

Do not automatically download or execute adapters from an untrusted registry.
Do not print credentials in diagnostics. Do not fall back to ambient SDK auth when
the selected credential reference fails.

Exit criteria:

- each official adapter has a tested clean-machine onboarding path;
- provider identity is confirmed before provisioning;
- credentials never enter workload or evidence artifacts;
- onboarding ends with `workcell verify` success and zero owned resources.

## Phase 9: Kujo Agent, Plugin, Relay, Dispatch, and evidence integration

Goal: expose one bounded WorkCell abstraction to agent hosts without exposing
provider APIs or credentials.

WorkCell changes come first. Cross-repository changes must be separate, scoped
commits in the relevant repositories after reading each repository's `AGENTS.md`.
Do not mix unrelated repositories in one commit or bypass their release gates.

Implement and verify:

- host/operator backend profile mapping for Kujo Agent Projects;
- backend selection outside the agent intelligence definition;
- one Agent Plugin/Bridge operation for bounded WorkCell execution;
- compact inspect, execute, cancel, receipt, and evidence results;
- receipt-path returns rather than full receipt injection into model context;
- operator policy precedence over agent input;
- prevention of provider escape hatches and credential access by agents;
- caller, workflow, step, attempt, correlation, and causation propagation;
- cancellation propagation from Relay/Dispatch;
- explicit new WorkCell attempt IDs for Dispatch retries;
- no workflow repair/retry ownership inside WorkCell;
- RunLedger and Casefile evidence correlation;
- one unchanged Agent Project exercised across Docker, Podman, E2B, Vercel, and
  Daytona profiles;
- separate measurement of orchestration and token overhead.

Exit criteria:

- external agents request bounded WorkCell execution, not provider API calls;
- no agent sees provider credentials;
- retries, cancellation, and receipts correlate without hidden attempts;
- compact summaries are the normal agent-facing output.

## Phase 10: Enterprise operations and security review

Goal: make deployment, incident response, governance, and support boundaries
explicit and testable.

Deliver:

- current core and per-adapter threat models;
- independent security review of archive extraction, ownership cleanup,
  credentials, protocol transport, and supply chain;
- deployment reference architectures;
- provider IAM/RBAC guidance;
- account/project/region/data-residency guidance;
- provider retention and deletion matrices;
- provider-native audit-log guidance;
- recovery-journal storage and retention guidance;
- orphan detection and reconciliation runbooks;
- incident response for leaked credentials, compromised adapters, orphaned
  resources, and provider outages;
- rollback and emergency-disable runbooks;
- evidence retention and access-control guidance;
- adapter support ownership, escalation paths, and SLOs;
- enterprise proxy, custom CA, private endpoint, and controlled-network guidance;
- legal, privacy, dependency-license, and data-processing review inputs;
- compliance control mappings clearly labeled as mappings, not certifications.

Run security tests for:

- network-none and allowlist bypass;
- tenant/isolation claim wording;
- malicious adapters and manifests;
- wrong-account and wrong-project cleanup;
- incomplete or malicious inventory;
- credential and signed-URL leakage;
- cancellation and cleanup races;
- supply-chain tampering.

Exit criteria:

- no critical risk-register item remains open for a promoted provider;
- every operational owner and runbook exists;
- limitations and operator responsibilities are explicit;
- no compliance or isolation claim exceeds evidence.

## Phase 11: Add the next provider batch

Do not begin this phase until E2B, Vercel, and Daytona have completed their live,
packaging, onboarding, and operational gates.

### Modal

- refresh official API/SDK research;
- define the exact WorkCell-compatible subset;
- implement as an official external adapter;
- model scheduler attempts and disable hidden retries;
- map images, functions, volumes, logs, cancel, artifacts, inventory, and cleanup;
- add complete fixtures, conformance, live certification, packaging, onboarding,
  limits, performance, cost, recovery, and support evidence.

### Runloop

- refresh official API/SDK research;
- define ephemeral versus persistent devbox semantics;
- ensure persistent resources are never deleted implicitly;
- implement as an official external adapter;
- map process, logs, files, artifacts, cancel, inventory, recovery, and cleanup;
- add the same complete certification and productization evidence as Modal.

### Cloudflare Sandbox

- wait for a stable enough runtime/deployment contract;
- decide whether it is an operator bridge rather than a standard provider;
- define control-plane and deployment ownership before implementation;
- never infer Cloudflare-wide security guarantees from an operator deployment.

### Kubernetes Agent Sandbox

- wait for stable scheduler and lifecycle semantics;
- model pod/job/attempt IDs and prevent hidden retries;
- inventory pods, jobs, PVCs, snapshots, secrets, and supporting resources;
- represent gVisor/Kata as substrates;
- ship as an operator adapter with cluster-specific certification.

Later adapters require demonstrated demand and must not block the stable core:

- Cloud Run Jobs;
- AWS Fargate;
- Azure Container Apps Jobs;
- Fly Machines as community/operator work;
- Nomad as community/operator work;
- containerd as community/later local work.

Keep these deliberate classifications unless new evidence and an architecture
review justify change:

- raw Firecracker: unsupported direct backend;
- Apple Virtualization.framework: substrate/framework, not provider;
- gVisor and Kata: OCI/Kubernetes runtime profiles;
- Lima and Colima: host substrates;
- Codespaces, Gitpod, and Coder: invocation hosts;
- Wasmtime/WASI: future workload kind, not the current Linux contract.

Exit criteria for every new provider:

- no workload-schema contamination;
- offline conformance;
- exact live certification;
- zero-orphan evidence;
- installable signed/verifiable distribution candidate;
- onboarding, recovery, limits, performance, cost, security, and support docs;
- provider-specific production promotion independent of other providers.

## Phase 12: Beta, distribution, and stable release

Goal: promote only evidence-backed contracts and providers.

Implement:

- support-tier and compatibility policy;
- adapter/version support matrix;
- deprecation and removal policy;
- provider emergency-disable policy;
- release notes and migration guides;
- stable examples and tutorials;
- verified GitHub discovery metadata;
- provider integration-catalog submissions where available and authorized;
- E2B ecosystem distribution first;
- separate evaluation of Vercel marketplace requirements;
- Daytona hosted/self-hosted ecosystem documentation;
- provider demo repositories and agent/plugin examples;
- clear distinction between verified partnerships and speculative outreach;
- beta feedback and blocker tracking;
- release candidate checksums, provenance, SBOMs, signatures when authorized,
  conformance evidence, certification reports, and rollback proof.

Do not publish tags, packages, images, releases, marketplace entries, or partner
claims without explicit authorization.

Exit criteria for beta:

- stable candidate contracts;
- E2B, Vercel, and Daytona individually pass required live gates;
- clean-machine installation and onboarding pass;
- critical security and cleanup risks are closed;
- beta limitations and support policy are public-ready.

Exit criteria for stable:

- beta feedback is resolved;
- compatibility and migrations are proven;
- at least two independent remote providers are production-promoted;
- every promoted provider has exact current certification;
- support, incident, rollback, deprecation, and security ownership exists;
- complete CI and release gates pass from a clean checkout;
- Docker/Podman v1 behavior remains equivalent or stronger;
- working trees are clean and all approved changes are pushed.

# Universal per-provider production checklist

Apply this checklist independently to every official provider. Never let one
provider's evidence certify another.

## Contract and identity

- [ ] adapter and contract versions captured
- [ ] provider API/SDK versions captured
- [ ] account, project, plan/tier, region, endpoint, image/template captured
- [ ] provider and substrate identities separated
- [ ] unsupported routing fields rejected
- [ ] capability drift detected and fail-closed

## Authentication

- [ ] least-privilege credential flow
- [ ] missing/expired/revoked credential behavior
- [ ] no ambient credential fallback
- [ ] secret canary redaction
- [ ] account/project confirmation

## Provision and workspace

- [ ] idempotent provision
- [ ] lost provision response recovery
- [ ] clean exact-commit package only
- [ ] upload bounds
- [ ] remote digest agreement
- [ ] no unrequested persistence
- [ ] secondary resources inventoried

## Execution

- [ ] argv-safe execution
- [ ] success and non-zero exit
- [ ] timeout
- [ ] graceful cancellation where supported
- [ ] forced termination fallback
- [ ] disconnect and terminal-unknown handling
- [ ] no hidden workload retries
- [ ] exact attempt inventory

## Policy and security

- [ ] CPU semantics
- [ ] memory semantics
- [ ] PID semantics
- [ ] disk semantics
- [ ] timeout/output semantics
- [ ] writable/read-only filesystem semantics
- [ ] image/template identity
- [ ] network-none negative probes
- [ ] allowlist negative probes if advertised
- [ ] private/metadata/provider exceptions documented
- [ ] enforcement authority honestly classified

## Logs and evidence

- [ ] stdout/stderr bounds
- [ ] truncation and completeness
- [ ] ordering scope
- [ ] disconnect recovery
- [ ] provider timestamps only when real
- [ ] no provider raw-response dump in core receipt
- [ ] offline receipt and manifest verification

## Artifacts and changes

- [ ] declared-only export
- [ ] bounded compressed and expanded bytes
- [ ] traversal/link/device/archive-bomb rejection
- [ ] local revalidation and hashes
- [ ] partial download cleanup
- [ ] workspace delta completeness

## Cleanup and recovery

- [ ] run ID and nonce ownership
- [ ] account/profile agreement
- [ ] itemized destroy
- [ ] absent resource is idempotent
- [ ] ownership mismatch never deletes
- [ ] lost destroy response recovery
- [ ] complete paginated inventory
- [ ] snapshots/volumes/objects/images/tasks inventoried
- [ ] repeated zero-orphan proof
- [ ] TTL behavior documented

## Performance and cost

- [ ] cold and warm samples
- [ ] resolve/package/upload/provision/first-log/execute/export/destroy timing
- [ ] concurrency and rate limits
- [ ] provider queue/cold-start separated where evidence permits
- [ ] exact provider-reported usage/cost or unknown amount
- [ ] spend ceiling and budget gate
- [ ] documented regression envelope

## Productization

- [ ] immutable installable adapter
- [ ] checksums/provenance/SBOM/license review
- [ ] clean-machine test
- [ ] credential and profile setup
- [ ] doctor diagnostics
- [ ] five-minute quick start
- [ ] limitations and certification report
- [ ] recovery/uninstall/rollback/incident runbooks
- [ ] named maintainer and support policy
- [ ] drift and deprecation monitoring

# Third-party adapter conformance deliverables

Make third-party implementation possible without granting security certification.
An adapter author must be able to ship:

- a minimal versioned manifest;
- an explicit executable implementing the bounded JSONL protocol;
- a versioned namespaced profile schema;
- deterministic request/response/failure fixtures;
- base conformance results;
- capability-selected conformance results;
- credential redaction evidence;
- path/archive/ownership adversarial evidence;
- installation and integrity metadata;
- limitations and provider authority statements;
- optional exact live evidence.

Publish a machine-readable conformance report format. Make clear that conformance
proves protocol behavior, not provider isolation, compliance, retention, network,
or operator security.

# Required tests and verification

Use the exact pinned Kujo runtime. At minimum run from a clean checkout:

```bash
./bin/workcell --help
./bin/workcell --version
./bin/workcell validate --file workcell.json
./tests/version_consistency.sh
./tests/run.sh
./tests/run.sh --check-only
./tests/quality.sh
./tests/release_report.sh
./tests/markdown_links.sh
git diff --check
npm ci --ignore-scripts --prefix adapters/official
npm run integrity:check --prefix adapters/official
npm test --prefix adapters/official
```

Where approved engines are available, also run:

- Docker build, doctor, integration, load, egress, cleanup, self-proof, and receipt
  verification;
- Podman doctor, OCI smoke, integration, load, egress, cleanup, and receipt
  verification;
- the opt-in portable OCI vertical-slice gate.

For every official remote adapter, run the protected exact-version live matrix
only when explicitly authorized. Preserve redacted evidence outside Git and prove
zero owned resources. A skipped live test is a blocker, not a pass.

Add and maintain:

- Linux and macOS offline matrices;
- clean-install adapter matrices;
- contract backward/forward compatibility tests;
- capability-specific conformance;
- malformed protocol corpus;
- fuzzing and failure injection;
- scheduled SDK/API drift checks;
- narrow scheduled live smoke where authorized;
- issue/deprecation automation outside the runtime path;
- no flaky retry-based masking.

# Performance, cost, and token-efficiency rules

- Separate WorkCell, network, provider, queue/cold-start, and workload time where
  the evidence permits.
- Record benchmark environment, plan, region, image, versions, sample count, and
  cold/warm state.
- Report p50/p95 only with adequate samples.
- Never invent cost estimates.
- Use provider-reported exact amounts/usage or record class plus unknown amount.
- Apply strict spend ceilings to live tests.
- Keep compact summaries bounded by tests.
- Return paths and hashes instead of large embedded evidence.
- Keep CLI JSON stable and machine-readable.
- Do not print full capability ledgers, receipts, logs, or provider payloads in
  normal agent loops.
- Measure agent orchestration overhead and context size separately from workload
  execution.

# Release blockers and kill criteria

A provider must not be promoted if any of the following is true:

- exact ownership cannot be inventoried;
- effective termination cannot be proved;
- a timed-out or cancelled workload may continue without recovery evidence;
- cleanup leaves an unexplained owned or billable resource;
- required security controls are unknown, unsupported, not enforceable, changed,
  or contradicted;
- network-none or an advertised allowlist silently degrades;
- clean exact-source transfer cannot be proved;
- declared-only bounded artifact export cannot be implemented safely;
- provider retries create hidden workload attempts;
- credentials or signed URLs appear in evidence;
- receipts imply stronger isolation or enforcement than evidence supports;
- provider persistence cannot be disabled or inventoried;
- live behavior cannot be reproduced against an exact account/plan/region/version;
- API instability makes the adapter unmaintainable under the support policy;
- installation cannot be integrity-verified;
- critical risk-register items remain open.

If a provider fails these criteria, classify it as deferred, operator-only,
community, host-only, substrate-only, or unsupported. Do not weaken WorkCell to
force inclusion.

# Required documentation outputs

Keep these current throughout implementation:

- `README.md`
- `CHANGELOG.md`
- `AGENTS.md`
- `docs/backend-adapters.md`
- `docs/adapter-authoring.md`
- `docs/api-compatibility.md`
- `docs/known-limitations.md`
- `docs/development.md`
- `docs/security-model.md`
- `docs/enterprise-deployment.md`
- `docs/release-process.md`
- `docs/launch-checklist.md`
- `docs/plans/backend-matrix/README.md`
- `docs/plans/backend-matrix/IMPLEMENTATION_STATUS.md`
- `docs/plans/backend-matrix/ACCEPTANCE_CRITERIA.md`
- `docs/plans/backend-matrix/RISK_REGISTER.md`
- all machine-readable backend/capability/contract matrices;
- provider-specific setup, limits, certification, recovery, and support docs.

Do not leave stale checklists claiming missing work that has landed. Do not remove
open gates merely because they require credentials or operator action.

# Commit, handoff, and reporting discipline

For every phase:

1. inspect repository instructions and working-tree state;
2. state the bounded phase objective internally;
3. implement the smallest complete vertical slice;
4. add deterministic tests and fixtures;
5. run focused tests;
6. run proportional full gates;
7. update status, docs, changelog, schemas, and examples;
8. review security, compatibility, performance, and token impact;
9. commit a small meaningful change;
10. push when repository instructions require it;
11. leave the tree clean;
12. record exact passing evidence and external blockers.

Do not claim a phase complete because code compiles. Completion requires its exit
criteria and evidence.

When handing off, report only:

- phase and outcome;
- commits;
- exact verification results;
- provider resources remaining;
- external blockers and safe resume commands;
- status-ledger location;
- next dependency-ordered phase.

# Final definition of done

The entire program is complete only when:

- Docker and Podman retain equivalent or stronger stable behavior;
- provider-neutral contracts are stable, versioned, documented, and migrated;
- E2B, Vercel Sandbox, and Daytona have independent exact live certification;
- at least two remote providers are formally production-promoted;
- official adapters are immutable, installable, integrity-verifiable, and
  support-owned;
- clean-machine onboarding reaches an offline-verifiable receipt;
- credentials remain outside workload/evidence artifacts;
- all promoted controls have honest authority and observation evidence;
- cancellation, disconnect, recovery, and cleanup are proved;
- repeated live inventories show zero owned orphans;
- declared artifacts remain bounded, selective, and locally verified;
- performance, concurrency, cost, and spend envelopes are documented;
- third-party conformance is usable without implying certification;
- Kujo Agent, Plugin/Bridge, Relay, Dispatch, RunLedger, and Casefile boundaries
  are integrated and tested in their proper repositories;
- Modal and Runloop are either completed through the same gates or remain
  explicitly deferred with evidence;
- Cloudflare/Kubernetes/operator candidates are correctly classified;
- enterprise deployment, incident, retention, audit, rollback, deprecation, and
  support procedures exist;
- no critical risk-register item remains open for promoted providers;
- beta feedback and release gates pass;
- release artifacts, migration notes, provenance, SBOMs, and rollback proof are
  ready;
- no unsupported or unverified claim appears in docs, receipts, CLI output, or
  marketing material;
- every repository touched is verified, committed, pushed as authorized, and
  clean.

The target is not “many adapter files.” The target is a narrow, durable execution
contract with independently provable provider implementations, safe onboarding,
honest evidence, and operationally complete cleanup.
