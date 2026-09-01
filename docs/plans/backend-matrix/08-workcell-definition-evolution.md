# WorkCell definition and host configuration evolution

## Decision

Separate the portable workload contract from provider selection and operator configuration. Existing v1 definitions remain valid and continue to select Docker/Podman. Remote execution uses definition v2 and receipt v2 until the new semantics stabilize.

## Proposed v2 shape

```json
{
  "schema": "workcell-definition/v2alpha1",
  "name": "hello-workcell",
  "workload": {
    "kind": "linux-process",
    "image": {
      "reference": "alpine:3.20",
      "digest": "sha256:optional",
      "signature_key": "optional/repo/path.pub"
    },
    "command": ["sh", "-lc", "printf 'hello\\n' > hello.txt"],
    "working_directory": "/workspace"
  },
  "workspace": {
    "source": "clean-git-commit",
    "materialization": "portable-clone",
    "mount_path": "/workspace"
  },
  "environment": {"allow": [], "set": {}},
  "secrets": [],
  "requirements": {
    "compute": {"cpus": 2, "memory": "1g", "pids": 256},
    "execution": {"timeout_ms": 300000, "max_output_bytes": 4000000},
    "network": {"mode": "none"},
    "filesystem": {"read_only_root": true, "writable": ["/workspace", "/tmp"]}
  },
  "artifacts": {"export": ["hello.txt"]},
  "verification": {"version": 1, "commands": []},
  "cleanup": {"keep_failed": false},
  "receipt": {"path": ".workcell/runs"}
}
```

The definition contains no E2B, Vercel, Daytona, region, account, endpoint, API key, or provider project fields.

## Host profile

Provider configuration belongs in an operator-owned profile, selected by `--profile` or a host/Agent Project mapping:

```json
{
  "schema": "workcell-host-profiles/v1alpha1",
  "profiles": {
    "ci-remote": {
      "backend": "e2b",
      "credential_ref": "kujo-agent:e2b",
      "region": "us-east",
      "provider_project": "project-id",
      "adapter_options": {
        "e2b": {"template": "template-id"}
      },
      "policy": {
        "required_adapter_digest": "sha256:...",
        "allow_degradation": ["metrics.cpu", "cost.provider_amount"]
      }
    }
  }
}
```

Provider-specific options are namespaced and validated by the adapter's versioned profile schema. They are not copied into the workload definition or raw receipt. The receipt records a redacted resolved summary and profile fingerprint.

Recommended profile locations:

- user/operator: XDG-compatible WorkCell config directory;
- CI: explicitly supplied file with owner/job permissions;
- project-local: ignored `.workcell/host-profiles.json` only when explicitly selected;
- enterprise: read-only operator path/policy injection.

Do not implicitly search arbitrary parent directories or accept credential values in profile JSON.

## Selection precedence

```text
operator forced policy
  > CLI --backend/--profile
  > Kujo Agent environment mapping
  > configured host default
  > v1 runtime.backend compatibility
```

`--backend` alone selects an adapter with its default profile; remote adapters should normally require an explicit profile. An operator policy may forbid adapters or force an approved profile regardless of project input.

## Semantic fields

### Image

`workload.image` is an execution-environment intent. An adapter resolves it to an OCI digest, provider template, snapshot, or supported base image and records the mapping. Provider snapshot IDs normally belong in a host profile because they may be account-specific. A project may pin a portable OCI digest; it cannot assume a provider snapshot has equivalent identity.

### Region and placement

Region, cloud, private pool, organization/project, and endpoint belong in the host profile. A workload may declare a semantic data-residency/placement requirement only after WorkCell defines a versioned capability for it. A string region in a workload would be vendor contamination.

### Backend credentials

Definitions may name workload secret environment variables. Provider control-plane credentials are separate adapter credentials and never enter the sandbox. `credential_ref` identifies Kujo Agent auth/OS store/environment conventions; it does not hold a value.

### Network

The workload declares intent: `none`, `default`, or a semantic allowlist/private-network requirement. Provider firewall IDs, VPCs, proxies, and Worker handlers live in profiles. `inspect` shows exactly how intent resolves.

### Strictness

Definition requests are required by default. There is no definition-wide best-effort switch. Optional evidence requests may be marked optional in a future additive field, but security/resource controls remain fail-closed. Operator `allow_degradation` is a list of exact non-security capability IDs and cannot use wildcards.

## v1 migration

1. Parse v1 exactly as today.
2. Convert internally to semantic intent while preserving original definition hash and version.
3. Only `docker` and `podman` are valid v1 backend selections.
4. Preserve `workspace.strategy`, image/build context, security profiles, engine runtime, and current receipt fields.
5. Do not allow `--backend e2b` to reinterpret a v1 definition. Provide an explicit `workcell migrate-definition` preview later, never an implicit rewrite.
6. Definition v2 initially supports Docker/Podman too, proving the same workload file can use local and remote profiles.

## Provider extensions policy

An adapter option is acceptable only when it controls provider mechanics not representable as a portable requirement: provider template/snapshot ID, region, project/account, endpoint, private pool, or transport tuning. CPU, memory, timeout, network, image, environment, artifacts, and cleanup are core semantics and cannot be redefined inside `adapter_options`.

Unknown provider options fail validation through the adapter profile schema. The adapter may add fields only compatibly within its profile-schema version.

## Agent Project mapping

`agent.project.json` should continue to reference the WorkCell definition path. Add an environment mapping outside the agent intelligence definition:

```json
{
  "execution_profiles": {
    "developer": "local-docker",
    "ci": "ci-podman",
    "codex": "e2b-project",
    "enterprise": "daytona-private"
  }
}
```

The host selects the environment key. The agent does not edit the WorkCell definition or call provider APIs.

