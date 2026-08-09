# Workcell Development

## Runtime

Use Kujo 1.0.0 built from the exact commit in `RUNTIME_VERSION`, not the unrelated Python package named `kujo` and not a newer checkout that happens to report the same semantic version.

```bash
export KUJO=/path/to/kujo-1.0.0/target/release/kujo
test "$(git -C /path/to/kujo-1.0.0 rev-parse HEAD)" = "$(cat RUNTIME_VERSION)"
"$KUJO" --version
```

The v1.0.0 runtime commit is `2b3e07d398016e92008d8399e79c441e012dce38`.

## Offline and quality gates

```bash
KUJO="$KUJO" ./tests/version_consistency.sh
KUJO="$KUJO" ./tests/run.sh --check-only
KUJO="$KUJO" ./tests/run.sh
KUJO="$KUJO" ./tests/quality.sh
KUJO="$KUJO" ./tests/release_report.sh | jq .
./tests/markdown_links.sh
git diff --check
```

The offline suite checks all Kujo sources, policy and definition validation, path and symlink safety, redaction, artifact boundaries, receipt and manifest integrity, lifecycle results, cleanup regressions, CLI/schema contracts, examples, deterministic stress and performance signals, shell syntax, formatting, lint, product/runtime version consistency, and local Markdown links. It does not require a container daemon.

`tests/quality.sh` requires `kujo format --check`, zero Kujo lint findings for source modules, valid shell syntax, and `git diff --check`. `tests/release_report.sh` emits `workcell-report/v1` with `workcell_version`, suite counts, elapsed time, and explicit deployment-gate status.

## Docker gates

Run on a supported host with a reachable Docker daemon:

```bash
docker build --tag kujolang/workcell-base:local docker/
KUJO="$KUJO" ./bin/workcell doctor --backend docker --json | jq .
KUJO="$KUJO" ./tests/docker_integration.sh docker
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/load_integration.sh docker
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/egress_integration.sh docker
```

The integration suite exercises successful, failed, timed-out, digest/signature, custom-network, artifact, secret, verification, image-build, receipt-integrity, cleanup, and tamper-detection paths. Load evidence runs four isolated executions by default and verifies unique run IDs, unchanged source, artifacts, manifests, workspaces, and containers. Egress evidence proves one allowed internal destination and one blocked external DNS destination on a temporary internal network; it does not replace a host firewall or proxy acceptance test.

On macOS VM-backed engines, point `TMPDIR` at an existing host directory shared into the engine VM. The integration scripts create their temporary repositories and outputs beneath that exact directory instead of relying on the platform `mktemp` default.

## Podman gates

Run on supported Linux with a reachable Podman engine:

```bash
KUJO="$KUJO" ./bin/workcell doctor --backend podman --json | jq .
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/oci_smoke.sh podman
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/docker_integration.sh podman
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/load_integration.sh podman
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/egress_integration.sh podman
```

Rootless definitions must set `workspace.run_as` to `rootless`. `doctor` reports the observed seccomp, AppArmor, and rootless signals; it does not manufacture host evidence.

## Deployment-owned egress acceptance

`tests/egress_deployment_contract.sh` never creates or mutates network infrastructure. The operator supplies a pre-created custom network or a protected default network, one allowed URL, one denied URL, and the reviewed enforcement profile. Probe URLs must be credential-free HTTP or HTTPS destinations.

```bash
REQUIRE_BACKEND=true \
NETWORK_NAME=corp-egress-v1 \
ALLOWED_URL=https://packages.example.invalid/health \
DENIED_URL=https://example.com \
EVIDENCE_FILE=/safe/evidence/workcell-egress.json \
KUJO="$KUJO" ./tests/egress_deployment_contract.sh docker
```

Set `NETWORK_MODE=default` only when the host firewall or transparent proxy protects the engine's default network. Passing evidence covers the supplied probes, not arbitrary child-process routing or organization-wide egress policy.

## Real self-proof

Build the local image, run Workcell against its own clean checkout, and verify the resulting receipt:

```bash
KUJO="$KUJO" ./bin/workcell run --file workcell.json --repo . --no-pull --json > /tmp/workcell-self-proof.json
run_dir="$(dirname "$(jq -r '.receipt_path' /tmp/workcell-self-proof.json)")"
KUJO="$KUJO" ./bin/workcell verify --run "$run_dir" --json | jq -e '.ok == true'
```

Do not commit `.workcell/`, test output, temporary release artifacts, CaseFile, or RunLedger data.

## ShipCheck

Run the sibling release gate with the same Kujo binary:

```bash
cd ../shipcheck
KUJO_BIN="$KUJO" "$KUJO" run shipcheck.kujo gate \
  --dir ../workcell \
  --format json
```

ShipCheck is a repository-readiness gate, not a security or deployment certification. Release requires exit code `0`, zero error findings, and review of all warnings against the narrow v1 contract.

## Runtime and receipt changes

Keep lifecycle policy in `src/execution/coordinator.kujo`; Docker and Podman share the same definition, policy, output, and ownership-scoped cleanup contract. A backend must not silently weaken network, mount, resource, provenance, receipt, or cleanup guarantees. Optional ecosystem adapters use bounded argv execution, redact environment secrets, persist separate reports, and never alter the primary Workcell verdict.

The local receipt is the offline source of truth. Preserve run ID, product version, definition version, source commit, result status, and evidence paths in any adapter. Never store secret values or claim an external evidence write succeeded without checking its result.

## Debugging

Run `workcell inspect --json` before starting a container. On failure, inspect the run directory's receipt, stdout, stderr, changes patch, failure diagnostics, and explicit preserved workspace. Run `workcell clean --dry-run --json` before cleanup and confirm that every target is Workcell-owned.
