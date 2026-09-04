# Workcell

[![Version](https://img.shields.io/badge/version-1.0.0-black)](https://github.com/kujolang/workcell)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)
[![built with Kujo](https://img.shields.io/badge/built%20with-Kujo-white.svg)](https://github.com/kujolang/kujo)
[![CI](https://github.com/kujolang/workcell/actions/workflows/ci.yml/badge.svg)](https://github.com/kujolang/workcell/actions/workflows/ci.yml)

Workcell 1.0 is a stable local and CI execution harness for bounded Kujo and agent workflows on Docker or Podman. It creates a disposable Git worktree, validates a declarative execution definition, applies bounded container resources and filesystem access, enforces an explicit network policy, exports only declared artifacts, records a structured receipt and integrity manifest, and performs ownership-scoped cleanup.

The repository also contains an additive alpha provider-neutral contract: `workcell-definition/v2alpha1`, `workcell-backend/v1alpha1`, and `workcell-receipt/v2alpha1`. Docker and Podman implement that contract through the existing stable OCI lifecycle. Digest-pinned external adapters for E2B, Vercel Sandbox, and Daytona are separately installed, strictly capability-negotiated, ownership-recoverable, and receipt-visible. gVisor and Kata are OCI runtime selections, not provider adapters. Offline conformance is not live-provider or security certification. See [backend adapters](docs/backend-adapters.md).

> The container boundary defines what is physically reachable. Kujo defines what is authorized, observable, verifiable, and exportable.

The v1 guarantee is deliberately narrow. It covers the local Docker/Podman CLI, definition, receipt, verification, artifact, cleanup, and recovery contracts documented in this repository. It does not protect against a compromised daemon or host kernel, provide microVM isolation or hosted multi-tenant execution, provision organization-specific egress infrastructure, govern operator images or signing keys, set retention policy, or confer compliance or enterprise certification.

## Supported contract

Workcell 1.0 supports:

- disposable Git worktrees and isolated-clone workspaces from clean repositories;
- strict, versioned JSON definitions with safe defaults and unknown-field rejection;
- Docker and Podman execution with bounded CPU, memory, PIDs, time, output, mounts, and writable paths;
- explicit `none`, `default`, or pre-created `custom` network selection plus a recorded egress declaration;
- declared artifact export, structured receipts, SHA-256 integrity manifests, and offline verification;
- label-scoped container cleanup, ownership-marked workspace cleanup, timeout recovery, and explicit failed-workspace preservation.

Supported host classes are Linux with Docker Engine or rootless Docker/Podman, and macOS with Docker Desktop or Colima. Windows and unsupported Unix hosts are outside v1. Run `workcell doctor` on every target host; host file sharing, user namespaces, seccomp/AppArmor, DNS, proxy, and firewall behavior remain deployment-specific. See [platform compatibility](docs/compatibility.md).

## Requirements and installation

- Kujo 1.2.1 at commit `692512a9070fdba713f160d795bbddb8077db7b5` (the exact pin is in `RUNTIME_VERSION`).
- Git and `jq`.
- Docker for the default backend, or Podman on a supported Linux host.
- A clean Git source repository for execution. Workcell refuses dirty sources by default so it cannot silently omit user changes.

Workcell is distributed as a source archive and can also run directly from a checkout:

```bash
git clone https://github.com/kujolang/workcell.git
cd workcell
git checkout v1.0.0
export KUJO=/path/to/kujo-1.2.1/kujo
./bin/workcell --version
```

The `v1.0.0` tag contains the stable release. Unreleased provider-neutral work on `main` must be pinned by exact commit until a later version is approved; do not treat `main` as the tagged release. The launcher reads `KUJO` and does not download or replace the runtime.

## Quick Start

```bash
export KUJO=/path/to/kujo-1.2.1/kujo
docker build --tag kujolang/workcell-base:local docker/
./bin/workcell init
./bin/workcell validate --file workcell.json
./bin/workcell inspect --file workcell.json --json
./bin/workcell run --file workcell.json --repo . --no-pull
./bin/workcell verify --run .workcell/runs/<run-id> --json
```

Agent hosts can use `workcell run ... --summary` for one compact `workcell-run-summary/v1` JSON object containing the verdict and evidence paths without embedding the full receipt. The receipt and integrity manifest remain authoritative.

`workcell init` creates a restrictive starter definition. `inspect` resolves policy without starting a container. `run` creates a temporary Git workspace and writes evidence under `.workcell/runs/<run-id>/`. For Podman, set `runtime.backend` to `podman` and follow the identity guidance in [platform compatibility](docs/compatibility.md).

## Portable backend quick start

The v2 workload stays provider-neutral; the host profile selects compute. This example resolves through built-in Docker without installing an adapter:

```bash
./bin/workcell validate --file examples/portable/workcell.json
./bin/workcell inspect \
  --file examples/portable/workcell.json \
  --profiles examples/portable/host-profiles.json \
  --profile docker \
  --summary
./bin/workcell run \
  --file examples/portable/workcell.json \
  --repo . \
  --profiles examples/portable/host-profiles.json \
  --profile docker \
  --summary
```

Switching profiles changes the provider, not the workload contract. Remote profiles and explicit adapter manifests are documented in [backend adapters](docs/backend-adapters.md). Unsupported security or resource requirements fail before provisioning; Workcell never silently substitutes provider defaults.

## Agent-efficient interface

Agents should use `inspect --summary` for a compact preflight and `run --summary` for the verdict and evidence pointers. These emit single-line `workcell-inspect-summary/v1` and `workcell-run-summary/v1` objects without commands, mounts, secrets, full capability ledgers, logs, or embedded receipts. Read `receipt.json` only when detailed evidence is needed, and use `verify --json` before trusting persisted evidence. Pass correlation through a bounded `workcell-caller-context/v1` file with `--context`; never put credentials or provider options in caller context.

## Stable CLI surface

| Command | Contract |
| --- | --- |
| `doctor` | Check Kujo, Git, selected backend, engine security signals, repository, temp directory, and dangerous environment overrides. |
| `init` | Create a starter `workcell.json`; refuse overwrite unless `--force` is explicit. |
| `validate` | Parse and validate a definition; `--schema` emits `workcell-definition/v1`. |
| `inspect` | Render resolved mounts, resources, environment names, backend, and security arguments without execution. |
| `run` | Execute validate, prepare, launch, collect, verify, export, record, and clean. |
| `verify` | Verify a run directory's `workcell-manifest/v1` hashes offline. |
| `clean` | Inventory or remove only Workcell-owned containers and workspaces; images require `--prune-images`. |
| `backends` | List built-ins and explicitly supplied external adapter manifests. |
| `recover` | Reconcile a durable external-backend journal without deleting resources whose ownership does not match. |

Global `--help` and `--version` are stable. Command-specific options and unexpected positional arguments fail with usage code `2`. The machine-readable CLI and exit-code contract is available from `workcell help --json`.

## Output and exit codes

Each completed lifecycle writes the applicable evidence:

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

The receipt separates Workcell product version, definition version, execution, verification, artifact export, and cleanup results. It records secret names but never intentionally stores secret values. `workcell verify` detects changes to immutable evidence.

Portable runs use receipt v2. Its controls ledger distinguishes requested, accepted, enforced or provider-claimed, observed, unsupported, and unknown state. A provider name or marketing claim never upgrades an enforcement status.

| Exit | Meaning |
| --- | --- |
| `0` | Completed successfully. |
| `2` | Usage or definition validation failure. |
| `3` | Git/source dependency or workspace preparation failure. |
| `4` | Backend or image preparation failure. |
| `5` | Container startup failure. |
| `6` | Timeout. |
| `7` | Workload command failure. |
| `8` | Verification or artifact export failure. |
| `9` | Cleanup failure. |
| `10` | Internal Workcell failure. |

The workload's own exit code remains in `receipt.json`; the Workcell exit code identifies the lifecycle category.

## Security posture

The default `contained-standard` profile uses network `none`, a non-root or rootless-mapped identity, a read-only root filesystem, bounded resources, `no-new-privileges`, dropped Linux capabilities, private IPC, no devices or host namespaces, no daemon socket, explicit environment passing, and one disposable workspace mount. Only declared artifacts leave the workspace.

Network access must be explicit. Workcell records the egress declaration but does not install firewalls, control DNS, or force arbitrary child processes through a proxy. For release deployments, use reviewed image digests, signature keys, registry allowlists, and host-enforced egress where required.

Containers are not universal isolation. Workcell trusts the selected engine and host kernel. Higher-risk or multi-tenant workloads need an operator-provided VM, gVisor/Kata class runtime, microVM service, or equivalent stronger boundary. Read the [security model](docs/security-model.md), [enterprise deployment boundary](docs/enterprise-deployment.md), and [known limitations](docs/known-limitations.md) before deployment.

## Compatibility and upgrades

Workcell follows semantic versioning for the product. The `workcell-definition/v1`, `workcell-cli/v1`, `workcell-receipt/v1`, `workcell-manifest/v1`, and other evidence identifiers are independent contract versions; product 1.0.0 does not rename them. Additive fields may appear within a v1 contract. Removing or repurposing a field or exit code requires a new contract identifier and migration notes.

Patch releases contain compatible fixes. Minor releases may add optional CLI or schema surface with safe defaults. A future product major may change supported contracts only with changelog and migration guidance. Pin both the Workcell release and Kujo runtime commit for reproducible automation. See the [API compatibility policy](docs/api-compatibility.md).

## Verification

Run the offline release gates with the pinned runtime:

```bash
export KUJO=/path/to/kujo-1.2.1/kujo
./bin/workcell --help
./bin/workcell --version
./bin/workcell validate --file workcell.json
KUJO="$KUJO" ./tests/version_consistency.sh
KUJO="$KUJO" ./tests/run.sh
KUJO="$KUJO" ./tests/quality.sh
KUJO="$KUJO" ./tests/release_report.sh
./tests/markdown_links.sh
git diff --check
```

Docker and Podman integration, concurrent-load, egress, doctor, cleanup, self-proof, receipt verification, and ShipCheck commands are documented in [development](docs/development.md) and the [release process](docs/release-process.md).

## Release and support boundary

GitHub source archives and the versioned source archive, checksums, provenance record, and release report produced by the tag workflow are the supported v1 release artifacts. The workflow publishes no container image, hosted runner, package registry entry, or hosted execution service. Target-host hardening, image governance, key custody, evidence retention, egress infrastructure, and organization-specific compliance remain operator responsibilities.

Use [GitHub issues](https://github.com/kujolang/workcell/issues) for reproducible defects in the supported v1 contract. Security reports follow the private process in [the security model](docs/security-model.md). The exact pre-tag and rollback procedures are in [the release process](docs/release-process.md).

## Documentation

- [Architecture](docs/architecture.md)
- [Backend adapters](docs/backend-adapters.md)
- [Backend adapter authoring](docs/adapter-authoring.md)
- [Live provider certification](docs/live-provider-certification.md)
- [Remote provider operations](docs/provider-operations.md)
- [Official adapter distribution](docs/official-adapter-distribution.md)
- Provider operations: [E2B](docs/providers/e2b.md), [Vercel Sandbox](docs/providers/vercel-sandbox.md), [Daytona](docs/providers/daytona.md)
- [Backend matrix research and implementation package](docs/plans/backend-matrix/README.md)
- [Backend matrix productionization mega prompt](MEGA_PROMPT.md)
- [API compatibility and machine contracts](docs/api-compatibility.md)
- [Workcell definition](docs/workcell-definition.md)
- [Runtime lifecycle](docs/runtime-lifecycle.md)
- [Platform compatibility](docs/compatibility.md)
- [Security model](docs/security-model.md)
- [Security review](docs/security-review.md)
- [Known limitations](docs/known-limitations.md)
- [Enterprise deployment boundary](docs/enterprise-deployment.md)
- [Development](docs/development.md)
- [Release process](docs/release-process.md)
- [Launch checklist](docs/launch-checklist.md)
- [Examples](examples/README.md)

Workcell is licensed under the [MIT License](LICENSE).
