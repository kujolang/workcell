# Backend matrix risk register

| ID | Risk | Likelihood | Impact | Mitigation / release gate | Owner |
| --- | --- | --- | --- | --- | --- |
| R1 | Receipt overstates provider isolation | High | Critical | Per-control authority ledger; prohibited wording tests; security review for every adapter | WorkCell core + adapter maintainer |
| R2 | Capability changes between inspect and provision | High | High | Re-resolve on provision; drift comparison; fail closed for required fields | Adapter |
| R3 | Remote workspace upload includes secrets/dirty/ignored files | Medium | Critical | Core-built clean one-commit package; manifest; no arbitrary directory upload | WorkCell core |
| R4 | Provider-side mutable Git clone changes input | Medium | High | Portable package default; clone capability optional; exact commit and post-materialization hash | Core + adapter |
| R5 | Artifact traversal/symlink/archive bomb | High | Critical | In-sandbox declared exporter, compressed/expanded limits, no-follow extraction, hashes, adversarial conformance | WorkCell core |
| R6 | Client dies after provision, leaving billable resource | High | High | Durable handle before prepare; provider TTL; inventory/recover; scheduled operator smoke | Core + adapter |
| R7 | Cleanup deletes an unowned resource | Low | Critical | Run ID + nonce + profile/account match; ownership mismatch fails without deletion; conformance attack | Core + adapter |
| R8 | Adapter retries workload invisibly | Medium | Critical | Protocol forbids workload retry; attempt ID; scheduler retry disabled; receipt attempt inventory | Adapter |
| R9 | Aggregated logs appear complete/ordered when not | High | High | Log-quality schema, discontinuities, per-stream/global distinction, provider recovery tests | Core + adapter |
| R10 | Timeout kills local client but remote command continues | High | Critical | Host watchdog plus cancel/destroy fallback; terminal-unknown status; recovery journal | Core + adapter |
| R11 | Secrets leak via SDK logs/errors/protocol fixtures | Medium | Critical | One-shot credential channel, adapter/core redaction, canary scan, no raw response dumps | Adapter + core |
| R12 | Signed URLs/tokens persist in receipts | Medium | High | Protocol schema rejection/redaction; attachment audit; expiry URL never stored | Core |
| R13 | Provider default persistence violates disposable semantics | High | High | Explicit ephemeral configuration; inventory snapshots/volumes; reject unresolved persistence | Adapter |
| R14 | Network none silently degrades | High | Critical | Required capability; account/tier-aware resolution; negative probes; no provider-default fallback | Core + adapter |
| R15 | Domain allowlist bypass via protocol/DNS/redirect/provider exception | Medium | Critical | Capability limitation schema; TLS/protocol tests; disclose proxy/interception/exceptions | Adapter/security review |
| R16 | Runtime label (gVisor/Kata/Firecracker) treated as proof | High | High | Separate provider/substrate fields and authority; inspect actual config; documentation claim only otherwise | Core |
| R17 | SDK/API churn breaks adapters | High | Medium | Version capture, fixtures, scheduled smoke, adapter repo release cadence, deprecation gate | Adapter |
| R18 | Provider SDK adds heavy runtime to WorkCell core | Medium | Medium | Executable external adapters; built-in core remains Kujo-only | Architecture owner |
| R19 | v1 Docker/Podman behavior regresses | Medium | Critical | Golden policy/receipt/exit tests; all existing gates before remote merge | WorkCell core |
| R20 | Portable clone differs from current Git semantics | Medium | High | Explicit v2 strategy; functional one-commit repo; v1 unchanged; compatibility fixtures | Core |
| R21 | Submodules/LFS/history produce incomplete source | Medium | High | Reject unsupported source features initially; future explicit capabilities only | Core |
| R22 | Provider object store creates secondary orphan/cost | Medium | High | Every object in handle inventory; short TTL; delete and reconcile | Adapter |
| R23 | Metrics/cost fields are mistaken for exact bill | High | Medium | source/interval/completeness; provider-only amounts; unknown default | Core |
| R24 | Adapter executable is malicious or substituted | Medium | Critical | explicit paths, digest/signature operator policy, no automatic download, bounded sandboxing where practical | Operator + core |
| R25 | External adapter protocol output exhausts host | Medium | High | line/event/byte/deadline bounds; kill adapter; protocol violation evidence | Core |
| R26 | Cloud scheduler replacement creates multiple attempts | Medium | Critical | retries/restarts zero; enumerate task/pod UIDs; reject ambiguous attempt | Adapter |
| R27 | Pause/resume implies process continuity when only disk persists | High | High | separate snapshot from pause; capability semantics/conformance | Core + adapter |
| R28 | Failure workspace cannot be preserved remotely | High | Medium | export bounded failure evidence; capability-visible preservation; never promise inaccessible state | Core |
| R29 | Receipt/provider attachments become unbounded | Medium | Medium | attachment allowlist/size caps/redaction/hash; normalized receipt only | Core |
| R30 | Marketplace/distribution claim creates unsupported service obligations | Medium | Medium | adapter release separate from marketplace product; verify partnerships before claim | Product/release owner |

## Top release blockers

R1, R3, R5, R7, R8, R10, R11, R14, R19, and R26 are blocking at any likelihood. A failed cleanup live smoke is blocking until inventory proves the resource is absent or an operator documents and resolves the orphan. Unknown security capability resolution is a rejection, not a warning.

