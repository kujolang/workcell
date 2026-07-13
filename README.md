# Workcell

Workcell is a Kujo-native, local Docker-backed execution sandbox for AI agents and Kujo workflows. It creates a disposable Git worktree, runs a declared command inside a bounded container, exports only declared artifacts, records a structured receipt, and cleans up the environment.

> The sandbox defines what is physically reachable. Kujo defines what is authorized, observable, verifiable, and exportable.

Workcell complements Kujo trust and policy controls; it does not replace them. The current release is a release-gated local Docker MVP, not a universally isolated enterprise sandbox, hosted service, or custom container runtime. It is suitable for production-oriented local and CI workflows when the operator supplies the required host boundary, but enterprise deployments still need an appropriately trusted Docker host, rootless/VM boundary, egress controls, image governance, and retention policy.

Workcell is intentionally honest about that boundary: the repository is production-oriented and heavily tested, but “production ready” does not mean “universally safe on every host.” See [docs/enterprise-deployment.md](docs/enterprise-deployment.md) for the deployment controls that remain outside the Kujo program.

## Why use Workcell?

- Give an agent a disposable Git workspace instead of the real repository.
- Run commands with explicit CPU, memory, PID, timeout, network, filesystem, and secret policy.
- Export only declared artifacts, patches, logs, and structured evidence.
- Keep Docker-specific behavior behind a runtime boundary that can support stronger backends later.
- Use a practical Kujo example for structured process execution, validation, lifecycle modeling, and safety-oriented testing.

## Requirements

- Kujo 1.0 or a compatible current runtime.
- Git.
- `jq` for the shell-based contract and integration suites.
- Docker for `run` and Docker integration tests.
- Podman is optional and supported through `runtime.backend`; it is not required for the Docker-first path.
- A clean Git source repository for execution. Workcell rejects dirty sources by default to avoid silently omitting user changes.

Build and run from this checkout:

```bash
export KUJO=/path/to/kujo/target/release/kujo
$KUJO check main.kujo
docker build --tag kujolang/workcell-base:local docker/
./tests/run.sh
./tests/release_report.sh
./bin/workcell doctor --backend docker
```

## Usage

### Quick start

```bash
./bin/workcell init
./bin/workcell validate --file workcell.json
./bin/workcell inspect --file workcell.json --json
./bin/workcell run --file workcell.json --repo .
```

`workcell init` creates a restrictive JSON definition. `workcell validate --schema` emits the versioned machine-readable definition contract, and `workcell help --json` emits the CLI/exit-code contract. `workcell inspect` shows the resolved policy without starting a container. `workcell run` uses a temporary Git worktree and writes output under `.workcell/runs/<run-id>/`. Build `docker/` before running the local examples; build `docker/kujo/Dockerfile.local` from a Kujo checkout at the exact commit in `RUNTIME_VERSION` for the Kujo project-check example. Podman is available through `runtime.backend`; opt-in ecosystem evidence adapters write under each run's `integrations/` directory.

`workcell verify --run <run-directory> --json` verifies the run's versioned integrity manifest and detects tampering in immutable evidence files without exposing secret values.

`tests/release_report.sh` runs the Kujo-native offline suites and emits one `workcell-report/v1` JSON summary with assertion counts, elapsed time, and explicitly skipped deployment gates.

For operator-owned egress validation, `tests/egress_deployment_contract.sh` accepts a pre-created custom or default network plus one allowed and one denied URL. It never creates or mutates network infrastructure and emits `workcell-egress-deployment-evidence/v1` with receipt and manifest hashes.

Explicit absolute `--output` paths are accepted only under the host `TMPDIR` or the repository's `.workcell` directory; this prevents a run from writing arbitrary host paths.

After a run, inspect the evidence directly:

```bash
jq . .workcell/runs/<run-id>/receipt.json
less .workcell/runs/<run-id>/changes.patch
cat .workcell/runs/<run-id>/stdout.log
cat .workcell/runs/<run-id>/stderr.log
```

## CLI

| Command | Purpose |
| --- | --- |
| `doctor` | Check Kujo, Git, the selected Docker/Podman CLI and engine, repository, temp directory, and dangerous environment signals. |
| `init` | Create a starter `workcell.json`; refuses overwrite unless `--force` is supplied. |
| `validate` | Parse and semantically validate a definition without running Docker; `--schema` emits the versioned contract. |
| `inspect` | Display resolved config, mounts, resources, secrets by name, runtime backend, and security arguments. |
| `run` | Execute the complete validate/prepare/launch/collect/verify/export/record/clean lifecycle. |
| `verify` | Verify a run directory's versioned SHA-256 integrity manifest offline. |
| `clean` | Remove only Workcell-owned containers and temporary workspaces; `--dry-run` inventories resources, and `--prune-images` explicitly removes labeled images. |

Run options include `--file`, `--repo`, `--output`, `--dry-run`, `--keep-failed`, `--no-pull`, `--rebuild`, and `--json`. `doctor` and `clean` accept `--backend docker|podman`; Docker remains the default. Verification commands run in separate labeled containers with the same policy and appear under `receipt.json.verification.checks`.

## Security defaults

The default `contained-standard` profile uses Docker with network `none`, a non-root host-mapped UID/GID, a read-only root filesystem, bounded CPU/memory/PIDs/time/output, `no-new-privileges`, all Linux capabilities dropped, no devices, no host namespaces, no Docker socket, explicit environment passing, and a single disposable workspace mount. Only declared artifact paths leave the workspace. Secret names are audited; values are injected at runtime and redacted incrementally in stream logs and captured output. Cancellation is recorded explicitly and triggers labeled cleanup. Artifact limits, extension policies, and reject/redact secret hooks are opt-in. Rootless Docker and Podman deployments set `workspace.run_as` to `rootless`; Workcell verifies the engine mode and maps the container identity through the rootless user namespace.

Containers are not perfect isolation. Workcell trusts the local Docker daemon and host kernel, and does not provide a hardened microVM boundary. For release deployments, set `runtime.require_digest`, `runtime.require_signature`, and `runtime.registry_allowlist` alongside reviewed `runtime.image_digest` and `runtime.signature_key` values. When network access is required, declare `network.egress` and enforce its profile outside Workcell; receipts preserve the selected network policy. See [docs/security-model.md](docs/security-model.md) and [docs/enterprise-deployment.md](docs/enterprise-deployment.md).

## Output

Each run produces, when the lifecycle reaches the relevant stage:

```text
.workcell/runs/<run-id>/
├── receipt.json
├── stdout.log
├── stderr.log
├── integrations/
├── changes.patch
├── changes.json
├── manifest.json
└── artifacts/
```

The receipt separates execution, verification, artifact export, and cleanup outcomes. It never stores secret values.

## Repository layout

The root files are intentional and are not duplicate application implementations:

| Path | Role |
| --- | --- |
| `main.kujo` | Thin Kujo entrypoint; dispatches into `src/`. |
| `src/` | All Workcell application logic, grouped by domain. |
| `workcell.json` | Safe starter definition used by `workcell init` and local inspection. |
| `bin/workcell` | Thin launcher that locates the project and pinned-compatible Kujo runtime. |
| `docker/` | OCI image definitions and the pinned Kujo example-image builder. |
| `tests/` | Kujo contracts plus thin shell orchestration for Docker and CLI integration. |
| `docs/` | Architecture, security, compatibility, operations, and release-readiness records. |
| `fence.toml`, `kennel.toml`, `kujo.toml` | Repository boundary, package, and Kujo project metadata. |

Moving `main.kujo`, `workcell.json`, or the project metadata into `src/` would break the established Kujo repository and CLI conventions; they remain at the root by design.

## Development

```bash
export KUJO=/path/to/kujo/target/release/kujo
./tests/run.sh
./tests/run.sh --check-only
KUJO="$KUJO" ./tests/docker_integration.sh
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/egress_integration.sh
git diff --check
```

Docker and Podman integration tests are opt-in because an engine may not be available. `tests/egress_integration.sh docker|podman` emits `workcell-egress-evidence/v1` after proving an allowed internal destination and blocked external DNS on a temporary backend-specific internal network; it does not replace host firewall or proxy validation. On supported Linux/CI hosts, `tests/oci_smoke.sh podman` adds explicit OCI backend evidence. See [docs/development.md](docs/development.md) and [docs/runtime-lifecycle.md](docs/runtime-lifecycle.md).

## Architecture and roadmap

- [Architecture](docs/architecture.md)
- [Security model](docs/security-model.md)
- [Enterprise deployment boundary](docs/enterprise-deployment.md)
- [Definition reference](docs/workcell-definition.md)
- [Platform compatibility](docs/compatibility.md)
- [API compatibility](docs/api-compatibility.md)
- [Lifecycle](docs/runtime-lifecycle.md)
- [Development](docs/development.md)
- [Roadmap](docs/roadmap.md)
- [Next hardening backlog](docs/next-hardening-backlog.md)
- [Next review backlog](docs/next-review-backlog.md)
- [Repository conventions](docs/repository-conventions.md)

The runtime boundary leaves room for gVisor-compatible Docker runtimes, remote execution, and microVMs later. Docker is the default implementation and Podman is available through the explicit OCI backend contract; remote and microVM execution are not implemented.
