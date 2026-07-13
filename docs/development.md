# Workcell Development

## Runtime and tests

Use the current Kujo runtime, not the unrelated Python `kujo` linter:

```bash
export KUJO=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo
./tests/run.sh --check-only
./tests/run.sh
```

The offline suite checks every `.kujo` file, runs 108 policy/validation/path/redaction/artifact/verification contract assertions, 11 workspace patch/change-report/cleanup/scan assertions, and 5 deterministic stress assertions without Docker, plus the dedicated adversarial suite, a 200-file changed-file performance signal, malformed performance-environment input handling, partial-section validation without runtime crashes, path-safety, dry-run lifecycle, example-definition, CLI schema/help smoke, schema compatibility, release-report, and version-consistency scripts. Every source and test file also passes `kujo format --check` and every source module passes `kujo lint --json` with zero findings. For the larger local performance signal, run `WORKCELL_PERF_FILES=2000 $KUJO run tests/performance_test.kujo`; Docker/Podman integration tests should run in a clean temporary Git repository and are intentionally not part of the default suite when a daemon is unavailable.

`tests/quality.sh` is the shared quality gate for syntax-preserving Kujo formatting, zero source lint findings, shell syntax, and `git diff --check`; `tests/run.sh` and CI both execute it. The CLI smoke suite also verifies global `--help`/`--version`, rejection of extra positionals, and rejection of options that belong to another command.

Kujo lint is currently clean across Workcell source modules. Kujo format is syntax-preserving and `format --check` passes across source and test files; wrapping remains intentionally conservative until Kujo has an AST-aware formatting pass.

CI reads the pinned Kujo commit from `RUNTIME_VERSION`, checks that the Kujo example Dockerfiles use the same commit, requires Docker BuildKit/buildx, runs the offline suite, Docker and Podman integration suites, Docker and Podman egress evidence, doctor check, and a required Podman OCI smoke. Local Docker hosts without buildx use the legacy builder as a compatibility fallback and will emit Docker's deprecation warning.

For a deployment-owned network acceptance signal, run `REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/egress_integration.sh docker` or `... ./tests/egress_integration.sh podman`. It creates a temporary backend-specific internal network, proves an allowlisted fixture is reachable while external DNS is blocked, verifies the managed egress policy in the receipt, and emits `workcell-egress-evidence/v1`. This does not install or validate a host firewall, transparent proxy, or default-network policy; those remain deployment controls.

For a real deployment network, use `tests/egress_deployment_contract.sh`. It never creates or mutates a network; the operator supplies the backend, network mode, allowed URL, denied URL, and reviewed enforcement profile. Probe URLs must be credential-free `http://` or `https://` destinations. Set `EVIDENCE_FILE` to persist the JSON receipt alongside deployment evidence. For a pre-created custom network:

```bash
REQUIRE_BACKEND=true \
NETWORK_NAME=corp-egress-v1 \
ALLOWED_URL=https://packages.example.invalid/health \
DENIED_URL=https://example.com \
KUJO="$KUJO" ./tests/egress_deployment_contract.sh docker
```

Set `NETWORK_MODE=default` when the host firewall or transparent proxy protects the engine's default network. A passing `workcell-egress-deployment-evidence/v1` result proves the selected network path allowed the supplied destination and blocked the supplied destination; it does not prove that a proxy controls arbitrary child processes beyond the probe.

For supported Linux/CI hosts, `REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/oci_smoke.sh podman` runs the selected backend's doctor preflight, produces a `workcell-oci-evidence/v1` receipt, and records whether the engine reports rootless mode and the required security signals. Run `REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/docker_integration.sh podman` for the full Podman matrix. The local macOS Docker path can run `./tests/oci_smoke.sh docker`; this does not substitute for a rootless Linux receipt.

For concurrent deployment load evidence, run `REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/load_integration.sh docker` or `... ./tests/load_integration.sh podman`. The default four-run matrix shares one clean source repository and output root, then verifies unique run IDs, artifacts, manifests, source immutability, workspace cleanup, and container cleanup. Set `WORKCELL_LOAD_RUNS` from 2 through 16 for a larger bounded signal; the script emits `workcell-load-evidence/v1`.

Build example images when Docker is available:

```bash
docker build --tag kujolang/workcell-base:local docker/
docker/kujo/build-local.sh /path/to/kujo-source
```

## Adding a runtime adapter

Keep the lifecycle contract in `src/execution/coordinator.kujo`. Runtime selection is explicit through `runtime.backend`; Docker and Podman share the same policy, image, execution, output, and ownership-scoped cleanup contract. Preserve the policy fields and receipt distinctions; do not let a backend silently weaken network, mount, resource, or cleanup guarantees. Optional ecosystem evidence adapters belong in `src/integrations/integrations.kujo`, use bounded argv execution, redact environment secrets, and must not change the primary run result.

## Adding a receipt integration

Keep the local receipt writer as the fallback. An adapter to RunLedger should receive the completed Workcell receipt and retain the same run ID, source commit, result status, and evidence paths. Never store secret values or claim a RunLedger write succeeded without checking its command result.

## Debugging

Run `workcell inspect --json` before Docker. On failure, inspect the run directory's receipt, stdout, stderr, changes.patch, failure.txt, and preserved workspace path if `--keep-failed` was used. Run `workcell clean` only after confirming it will target Workcell-owned resources.
