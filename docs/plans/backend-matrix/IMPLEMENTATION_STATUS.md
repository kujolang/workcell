# Backend Matrix Implementation Status

This ledger is the human-readable execution status for `MEGA_PROMPT.md`. The
machine-readable backend, capability, and protocol facts remain in the adjacent
JSON matrices. A fixture or offline conformance result never counts as live
provider evidence or production promotion.

Last reviewed: 2026-09-04

## Status vocabulary

- **implemented** — code or documentation exists in the repository.
- **verified offline** — deterministic credential-free evidence passed.
- **verified live** — credentialed evidence identifies the exact account plan,
  region, adapter, SDK/API, image/template, profile fingerprint, and date.
- **blocked** — an external prerequisite or dependency prevents completion; a
  safe resume command is listed.
- **deferred** — intentionally waits for an earlier dependency or demonstrated
  demand.
- **deliberately unsupported** — excluded by the WorkCell product boundary.
- **released** — included in an authorized immutable release. Unreleased `main`
  work is never labeled released.

## Baseline

| Item | Status | Evidence |
| --- | --- | --- |
| Stable WorkCell v1 Docker/Podman contract | implemented; release evidence exists for v1.0.0 | `VERSION`; `README.md`; `tests/docker_integration.sh`; `tests/oci_smoke.sh`; `tests/load_integration.sh`; `tests/egress_integration.sh` |
| Provider-neutral definition, backend protocol, receipt, recovery, package, and artifact alpha contracts | implemented; verified offline | `src/backend/`; `src/execution/portable_coordinator.kujo`; `src/receipts/v2.kujo`; `src/recovery/recovery.kujo`; `src/workspace/package.kujo`; `src/artifacts/archive.kujo`; `./tests/run.sh` |
| Official E2B, Vercel Sandbox, and Daytona alpha adapters | implemented; verified offline only | `adapters/official/`; `npm test --prefix adapters/official`; `npm run integrity:check --prefix adapters/official`; `tests/official_adapters_test.kujo` |
| Current implementation baseline | verified offline | Starting source commit `216cca2`; exact pinned runtime commit `692512a9070fdba713f160d795bbddb8077db7b5`; deterministic gates and diagnostic samples are recorded below. |

## Dependency-ordered program

| Phase | Status | Current evidence and remaining gate |
| --- | --- | --- |
| 0 — audit and freeze | verified offline; Docker refreshed live | Exact Kujo gates pass; the contract inventory, task Spec, Eval suite, Loop Engineering evidence, and 10-sample local diagnostic baseline are recorded. Rootless Docker on the local Colima Linux VM passed doctor, OCI smoke, integration, four-run load, and egress gates on 2026-09-04. Podman installation is blocked because current Homebrew Podman requires Apple silicon on this Intel host. |
| 1 — protected live certification harness | implemented; verified offline | `tests/live_certification.sh`, its contract test, schema, protected workflow, bounded fixture profiles, explicit authorization/credential/identity/spend gates, external evidence directory, offline verification, and recovery status are present. Negative security probes remain a mandatory live step and cannot be claimed by fixture mode. |
| 2 — E2B | implemented alpha; verified offline; live blocked | SDK `e2b@2.46.1`; adapter manifest and fixture conformance exist. Live capability, account/plan/region, performance, cost, security-probe, and zero-orphan certification are absent. |
| 3 — Vercel Sandbox | implemented alpha; verified offline; live blocked | SDK `@vercel/sandbox@3.2.1`; adapter manifest and fixture conformance exist. Exact OIDC/account/plan/region behavior, live negative probes, performance/cost, and zero-orphan certification are absent. |
| 4 — Daytona | implemented alpha; verified offline; live blocked | SDK `@daytona/sdk@0.207.1`; adapter manifest and fixture conformance exist. Hosted and self-hosted account/tier/class/region/TLS evidence, performance/cost, and zero-orphan certification are absent. |
| 5 — stabilize v2 | blocked by phases 2–4 live evidence | Alpha schemas and compatibility policy exist. Stable identifiers and evidence-driven migrations cannot be finalized before at least two independent exact live providers resolve contract ambiguity. |
| 6 — robustness, fuzzing, and scale | partial; verified offline | Existing adversarial, archive, workspace, malformed protocol, recovery, stress, and performance tests pass. New regressions cover receipt traversal, operation-scoped workload secrets, ownership-safe recovery, pre/post-destroy inventory, handle bounds/credential rejection, and bundled SDK tamper detection. Provider-specific concurrency/rate/fault evidence remains live-blocked. |
| 7 — official adapter packaging | implemented candidate; verified offline; publication blocked | The installable package bundles exact provider dependencies and authenticates every shipped dependency file before Node starts. Candidate tooling produces checksum, SPDX SBOM, unsigned provenance, npm audit gate, clean install/tamper test, rollback/revocation/uninstall docs. Signing and publication require explicit authorization. |
| 8 — authentication and onboarding | partial | Explicit `env:` references are implemented. Kujo Agent/OS-store bridges, provider-aware doctor flows, clean-machine onboarding evidence, and live identity confirmation remain. |
| 9 — Agent/Plugin/Relay/Dispatch/evidence integration | contract documented; implementation pending in separate repositories | Caller context and compact WorkCell summaries exist. Cross-repository bridges, cancellation propagation, explicit attempt mapping, and correlated evidence integration require separately gated repository changes. |
| 10 — enterprise operations and security review | implemented offline; live approvals blocked | `docs/provider-operations.md`, per-provider guides, enterprise/security boundaries, incident/recovery/retention/drift duties, support ownership and no-SLO posture, privacy/legal inputs, and an independent multi-pass source review are present. Provider audit, deletion, legal, privacy, and live isolation evidence require operator/provider approval. |
| 11 — next providers | deferred; Cloudflare entitlement checked | Modal and Runloop wait for phases 2–4 live, packaging, onboarding, and operational gates. Cloudflare Sandbox is a technically compatible operator bridge, but the connected Free account cannot access Containers and ordinary Workers cannot execute the Linux-process contract. The read-only preflight and ownership decision are implemented; bridge implementation remains gated by Workers Paid and the phase-11 architecture/dependency review. Kubernetes Agent Sandbox remains an operator candidate. |
| 12 — beta, distribution, and stable release | blocked | Requires exact live certification and production promotion of at least two independent remote providers, beta feedback, authorized release actions, and complete hosted gates. |

## Provider certification

| Provider/profile | Offline | Live | Production | Exact live identity |
| --- | --- | --- | --- | --- |
| Docker | verified by deterministic regression suite; engine gates are host-specific | rootless Colima Linux VM gates passed on 2026-09-04 | stable v1 contract only | Local OCI evidence only; not a remote-provider certification claim. |
| Podman | verified by deterministic regression suite | blocked on this macOS host where Podman is unavailable | stable v1 contract on documented supported Linux hosts | Resume on supported Linux; do not substitute Docker evidence. |
| E2B | verified offline | blocked — credentials and explicit live authorization absent | not promoted | Account plan: unknown; region: unknown; adapter: 2.46.1; SDK/API: `e2b@2.46.1`; template: unknown; date: no live claim. |
| Vercel Sandbox | verified offline | blocked — credentials and explicit live authorization absent | not promoted | Account plan: unknown; region: unknown; adapter: 3.2.1; SDK/API: `@vercel/sandbox@3.2.1`; image: unknown; date: no live claim. |
| Daytona hosted | verified offline | blocked — credentials and explicit live authorization absent | not promoted | Account tier/class: unknown; region: unknown; adapter: 0.207.1; SDK/API: `@daytona/sdk@0.207.1`; date: no live claim. |
| Daytona self-hosted | verified offline contract only | blocked — approved endpoint, CA/TLS policy, credentials, and authorization absent | not promoted | Endpoint/class/region unknown; no live claim. |

## Deliberate classifications

- Modal and Runloop: deferred official candidates until first-batch production
  dependencies are complete.
- Cloudflare Sandbox and Kubernetes Agent Sandbox: deferred operator adapters
  pending stable runtime/deployment and attempt-ownership semantics.
- Cloud Run Jobs, AWS Fargate, and Azure Container Apps Jobs: later candidates.
- Fly Machines, Nomad, and containerd: community/operator or later local work.
- raw Firecracker: deliberately unsupported direct backend.
- gVisor and Kata: OCI/Kubernetes runtime substrates, not providers.
- Lima, Colima, and Apple Virtualization.framework: host substrates/frameworks.
- Codespaces, Gitpod, and Coder: invocation hosts.
- Wasmtime/WASI: future workload kind, not the current Linux process contract.

## Evidence commands and artifacts

The required clean-checkout evidence set is:

```bash
export KUJO=/path/to/kujo-at-692512a9070fdba713f160d795bbddb8077db7b5/target/release/kujo
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

Generated run receipts, manifests, provider payloads, benchmark samples, and
live certification bundles stay outside Git. Their committed contracts and safe
locations are documented by the applicable test or operator guide.

## External blockers and safe resume

### Remote providers

No live-provider execution is authorized for this implementation session. After
an operator selects an approved account, exact plan, region, image/template,
profile, credential reference, maximum runtime/concurrency/upload/download/log
bounds, and spend ceiling, resume only through the protected harness:

```bash
WORKCELL_LIVE_AUTHORIZED=1 WORKCELL_LIVE_E2B=1 \
  WORKCELL_LIVE_EVIDENCE_DIR=/approved/outside-git/e2b \
  ./tests/live_certification.sh e2b

WORKCELL_LIVE_AUTHORIZED=1 WORKCELL_LIVE_VERCEL_SANDBOX=1 \
  WORKCELL_LIVE_EVIDENCE_DIR=/approved/outside-git/vercel \
  ./tests/live_certification.sh vercel-sandbox

WORKCELL_LIVE_AUTHORIZED=1 WORKCELL_LIVE_DAYTONA=1 \
  WORKCELL_LIVE_EVIDENCE_DIR=/approved/outside-git/daytona \
  ./tests/live_certification.sh daytona
```

These are the implemented resume contracts. The harness also requires the exact
provider credential, profile, account/plan, region, image/template, bounded
limits, and spend ceiling documented in `docs/live-provider-certification.md`;
it must not be run merely because credentials happen to exist.

### Podman host evidence

On a supported Linux host with rootless Podman installed and started:

```bash
KUJO="$KUJO" ./bin/workcell doctor --backend podman --json
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/oci_smoke.sh podman
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/docker_integration.sh podman
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/load_integration.sh podman
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/egress_integration.sh podman
```

### Cloudflare Sandbox entitlement

The connected Cloudflare account authenticates with Wrangler, but Containers
returns a Workers Paid requirement. A Free Worker cannot substitute for the
required Linux process/container runtime. The check is read-only and creates no
resources:

```bash
./scripts/cloudflare-sandbox-preflight.sh
```

After Workers Paid is intentionally enabled, rerun the same command and complete
the architecture and phase-order gates in
[Cloudflare Sandbox operator-bridge decision](../../providers/cloudflare-sandbox.md)
before deploying anything.

### Hosted CI and release effects

Hosted CI must pass for the exact pushed commit. Publishing, tagging, signing,
marketplace submission, partnership claims, and production promotion remain
human-authorized actions and have no automatic resume command in this ledger.

## Phase 0 measurements

Measurements are diagnostic, not release budgets. Record the exact OS, runtime,
source commit, sample count, warm/cold state, and raw external evidence path
before setting a regression threshold. Provider queue, network, and workload
time must never be inferred from WorkCell wall time.

The 10-sample offline changed-file performance fixture ran on macOS 26.3.1
(`x86_64`) with exact Kujo commit
`692512a9070fdba713f160d795bbddb8077db7b5`. Wall time ranged from 6.53s to
6.97s with a 6.905s median. Raw logs and the machine-readable summary are at
`/tmp/workcell-phase0.T0y9Is` on the implementation host. Ten diagnostic samples
are not enough for a release-grade p95 claim. Remote/provider timings and costs
remain unknown until authorized live certification.
