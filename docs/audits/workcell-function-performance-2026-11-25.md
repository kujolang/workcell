# Workcell function performance audit · 2026-11-25

## Repository and scope

Workcell on `main` runs bounded workloads on Docker and Podman, collects workspace
changes, and records verifiable evidence. This pass covers the shared workspace,
policy, verification, and run-manifest code used by those lifecycles. It starts
at `189d7ab6e975301a0e5100b65e8ad3fe4a584573` and ends at implementation commit
`684fecd05ef00c039c13dcc07e691fb5552129e1`.

The verification runtime was the released macOS x64 Kujo 1.6.0 binary. Its
archive SHA-256 matched the release checksum, and release provenance names
`44af277848173664f72ca85f2a1b3b98d634ecdd`, the commit in `RUNTIME_VERSION`.

## Findings and changes

| ID | Priority | Function | Evidence and implemented change |
| --- | --- | --- | --- |
| WC-01 | P1 | `binary_paths_for_batch` | The independent 256-path `file` batches waited for each other. Run up to four read-only probes at once and associate ordered results with the original paths. A single batch runs directly. |
| WC-02 | P2 | `change_details` | `git diff --numstat` ran even when `git diff --name-status` reported no tracked changes. Skip the subprocess in that case. |
| WC-03 | P2 | `change_details` | The function built provisional records, then made two passes to update binary flags. Use the binary lookups when emitting each record, preserving tracked-first order and rename destinations. |
| WC-04 | P2 | `make_patch` | Two growing arrays assembled the untracked staging arguments. Concatenate the Git argv prefix and the NUL-delimited path list in one operation after dropping the empty trailing record. |
| WC-05 | P1 | `verify_manifest` | The coverage traversal hashed every file again after validating the listed hashes. Keep the coverage traversal for paths, size totals, bounds, and symlinks, and skip the unused hashes and entry objects. |
| WC-06 | P2 | `build_policy` | Label creation revalidated the definition during policy construction. The policy builder and standalone label entry point each validate once. |
| WC-07 | P2 | `run_verification_checks` | Each command override serialized and reparsed the whole validated definition. Use a local copy and update its command directly. |
| WC-08 | P2 | `run_verification_checks` | Verification receipts reread secret environment variables per argument and redacted streams that timeout recovery could replace. Read secret values once and redact the selected streams before writing receipt data. |
| WC-09 | P2 | `clean_stale_workspaces` | Each candidate serialized the same active-run list. Serialize once per sweep and reuse it for the existing active-run check. |

Regressions cover a clean worktree, binary changes split across file-type probe
batches, mixed tracked and untracked changes, tab-bearing Git paths, preservation
of the original workload command during verification, same-size evidence
tampering, and an unlisted symlink. The workspace cleanup tests now set a private
temporary root before sweeping. An initial overlapping baseline run exposed
that two suites could otherwise remove each other's fixtures.

## Compatibility and security

The documented APIs, CLI flags and exit codes, schemas, evidence formats,
configuration, and supported dependencies retain their current contracts.
Verification commands still run in order, and existing container ownership
checks, cleanup, output bounds, and evidence redaction apply. Manifest
verification checks each file against its expected digest and checks coverage of
the directory separately. The file-type probes use the same host utility,
structured argv, batch size, and per-process timeout as before.

The review covered execution contracts, process and filesystem costs, resource
bounds, errors, concurrency, compatibility, test and CI gates, and development
docs for the paths above. Compact agent summaries already point to durable
evidence. Tool schemas, replay and handoff payloads, provider transport,
artifact packaging, image governance, dependency audits, and release publishing
were outside this function-speed pass. No timing threshold was added to CI.

## Open dependency finding

The production adapter audit (`npm audit --omit=dev --json --prefix adapters/official`)
reported nine affected package entries, four rated high. The unchanged
`adapters/official/npm-shrinkwrap.json` pins flagged versions of
`follow-redirects` through Axios, two aliases of Undici, and Zod. This is
dependency-range evidence. Reachability within the official adapter SDKs is
unverified. SignalBox tracks the review as
`sig_265e8745-bc95-461b-9669-49fa1cb9d6a8`.
[Follow-redirects advisory](https://github.com/advisories/GHSA-mrwp-f3q8-3g9p)
[Undici TLS advisory](https://github.com/advisories/GHSA-2m5v-pch6-74hx)
[Zod advisory](https://github.com/advisories/GHSA-mrhx-c7xc-m3w5)

## Timings

Two complete baseline/candidate pairs used the checked-in benchmark fixture,
the same released runtime, Git 2.42.0, and macOS `file` 5.41 on an Intel i7-9750H
host. Pair order was baseline-first, then candidate-first. The harness checks
the outcomes and excludes fixture setup from the timings. Other host workloads
varied considerably. A third pair was stopped when the host became heavily
loaded and is excluded from the table.

| Workload | Baseline elapsed ms, median (range) | Candidate elapsed ms, median (range) |
| --- | ---: | ---: |
| Collect changes for 512 untracked files | 22,687 (16,474–28,900) | 13,568 (9,251–17,885) |
| Produce a patch for 512 untracked files | 902 (740–1,064) | 1,600 (598–2,602) |
| Verify four evidence files totaling 128 MiB | 4,755 (4,123–5,387) | 1,659 (1,361–1,956) |
| Build policy 60 times | 34,450 (16,169–52,731) | 10,464 (9,244–11,684) |
| Validate and redact 120 skipped checks | 18,821 (6,236–31,405) | 9,255 (7,268–11,241) |

The largest directly attributable saving is manifest verification. The fixture
went from hashing 256 MiB to hashing 128 MiB, and both candidate timings were
below both baseline timings. Change collection and policy results show lower
medians under these conditions. The sample is too small and the load too
variable to establish a general patch or redaction latency improvement. No
end-to-end engine timing, peak-memory figure, or token savings was measured.

Reproduce with
`WORKCELL_BENCH_ROOT="$(mktemp -d /tmp/workcell-bench.XXXXXX)" WORKCELL_BENCH_SECRET=workcell-bench-secret "$KUJO" run tests/performance_hot_paths.kujo`.
Copy the same harness into a detached baseline checkout to compare.

## Verification

The baseline CLI help, version, and definition validation passed. The pinned
baseline also passed version consistency, quality, the release report, Markdown
links, the official adapter Node tests and integrity check, the Git effect
contracts, and the offline adapter conformance fixture. An overlapping
baseline attempt failed four workspace cleanup assertions because the fixtures
shared a temporary root. The workspace tests passed with isolated roots.
On macOS, the path-safety shell wrapper needed the native `TMPDIR` because its
`mktemp -d` calls use the system temporary directory.

Candidate checks on the released runtime:

| Command | Result |
| --- | --- |
| `./bin/workcell --help`, `./bin/workcell --version`, `./bin/workcell validate --file workcell.json` | Passed. |
| `./tests/version_consistency.sh`, `./tests/quality.sh`, `./tests/markdown_links.sh`, `git diff --check` | Passed. |
| `./tests/release_report.sh` | Passed. 215 policy/artifact/verification assertions, 30 workspace assertions, the performance fixture, and 7 stress assertions passed. |
| `"$KUJO" run tests/performance_test.kujo`, `"$KUJO" run --interpreter tests/performance_test.kujo` | Passed with binary entries in different batches. The fixture also passed on the optional Kujo 1.5.0 runtime. |
| `./tests/run.sh` | Core tests passed through portable coordinator. Under heavy host load the final suite and a direct `"$KUJO" run tests/official_adapters_test.kujo` retry hit 10-second adapter startup timeouts. The same direct check hit those timeouts on the untouched baseline under that load. |
| `./tests/path_safety.sh`, `./tests/adversarial.sh`, `./tests/dry_run.sh`, `./tests/examples.sh`, `./tests/cli_smoke.sh`, `./tests/schema_contract.sh`, `./tests/report_contract.sh`, `./tests/podman_security_contract.sh` | Passed independently with the native temporary-root configuration. |
| `./tests/secret_scope_contract.sh`, `./tests/verification_cleanup_contract.sh`, `./tests/runtime_cleanup_contract.sh`, `./tests/startup_failure_contract.sh`, `./tests/lifecycle_failure_contract.sh`, `./tests/clean_runtime_failure_contract.sh`, `python3 tests/docker_endpoint_contract.py`, `bash tests/effect_assurance.sh` | Passed independently. |
| `./tests/live_certification_contract.sh`, `./tests/cloudflare_sandbox_preflight.sh` | Passed in offline fixture mode. The live portable OCI contract reported its expected opt-in skip. |
| `npm test --prefix adapters/official`, `npm run integrity:check --prefix adapters/official` | All 30 Node tests and the package integrity check passed on Node 22.23.4. |
| `./tests/adapter_release_candidate.sh`, `npm audit --audit-level=high --omit=dev --json --prefix adapters/official` | The packaging gate stopped. The direct audit returned 1 for pre-existing dependency advisories documented above. |
| `docker info`, `docker --context colima info` | No reachable daemon. Podman was unavailable. Live engine and provider measurements are pending. |
