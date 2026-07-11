# Workcell

Workcell is a Kujo-native, local Docker-backed execution sandbox for AI agents and Kujo workflows. It creates a disposable Git worktree, runs a declared command inside a bounded container, exports only declared artifacts, records a structured receipt, and cleans up the environment.

> The sandbox defines what is physically reachable. Kujo defines what is authorized, observable, verifiable, and exportable.

Workcell complements Kujo trust and policy controls; it does not replace them. The initial release is a local Docker MVP, not a hosted service or a custom container runtime.

## Requirements

- Kujo 1.0 or a compatible current runtime.
- Git.
- Docker for `run` and Docker integration tests.
- A clean Git source repository for execution. Workcell rejects dirty sources by default to avoid silently omitting user changes.

Build and run from this checkout:

```bash
export KUJO=/path/to/kujo/target/release/kujo
$KUJO check main.kujo
./tests/run.sh
./bin/workcell doctor
```

## Usage

### Quick start

```bash
./bin/workcell init
./bin/workcell validate --file workcell.json
./bin/workcell inspect --file workcell.json --json
./bin/workcell run --file workcell.json --repo .
```

`workcell init` creates a restrictive JSON definition. `workcell inspect` shows the resolved policy without starting a container. `workcell run` uses a temporary Git worktree and writes output under `.workcell/runs/<run-id>/`. Build `docker/` for the Hello, edit, failure, and timeout examples; build `docker/kujo/` for the Kujo project-check example.

## CLI

| Command | Purpose |
| --- | --- |
| `doctor` | Check Kujo, Git, Docker, repository, temp directory, and dangerous environment signals. |
| `init` | Create a starter `workcell.json`; refuses overwrite unless `--force` is supplied. |
| `validate` | Parse and semantically validate a definition without running Docker. |
| `inspect` | Display resolved config, mounts, resources, secrets by name, and security arguments. |
| `run` | Execute the complete validate/prepare/launch/collect/verify/export/record/clean lifecycle. |
| `clean` | Remove only Workcell-labeled Docker containers and Workcell temporary directories. |

Run options include `--file`, `--repo`, `--output`, `--dry-run`, `--keep-failed`, `--no-pull`, `--rebuild`, and `--json`.

## Security defaults

The default `contained-standard` profile uses Docker with network `none`, a non-root UID, a read-only root filesystem, bounded CPU/memory/PIDs/time, `no-new-privileges`, all Linux capabilities dropped, no devices, no host namespaces, no Docker socket, explicit environment passing, and a single disposable workspace mount. Only declared artifact paths leave the workspace. Secret names are audited; values are injected at runtime and redacted from captured logs.

Containers are not perfect isolation. Workcell trusts the local Docker daemon and host kernel, and does not provide a hardened microVM boundary. See [docs/security-model.md](docs/security-model.md).

## Output

Each run produces, when the lifecycle reaches the relevant stage:

```text
.workcell/runs/<run-id>/
├── receipt.json
├── stdout.log
├── stderr.log
├── changes.patch
├── changes.json
└── artifacts/
```

The receipt separates execution, verification, artifact export, and cleanup outcomes. It never stores secret values.

## Development

```bash
export KUJO=/path/to/kujo/target/release/kujo
./tests/run.sh
./tests/run.sh --check-only
git diff --check
```

Docker integration tests are opt-in because the local daemon may not be available. See [docs/development.md](docs/development.md) and [docs/runtime-lifecycle.md](docs/runtime-lifecycle.md).

## Architecture and roadmap

- [Architecture](docs/architecture.md)
- [Security model](docs/security-model.md)
- [Definition reference](docs/workcell-definition.md)
- [Lifecycle](docs/runtime-lifecycle.md)
- [Development](docs/development.md)
- [Roadmap](docs/roadmap.md)
- [Repository conventions](docs/repository-conventions.md)

The runtime boundary leaves room for Podman, gVisor-compatible Docker runtimes, remote execution, and microVMs later. Only Docker is implemented now.
