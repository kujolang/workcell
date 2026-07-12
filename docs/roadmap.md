# Workcell Roadmap

Implemented now: local Docker backend, JSON v1 definitions and schema/help contracts, disposable Git workspaces with host UID/GID mapping, restrictive default policy, bounded resources/timeouts/output/scans, declared artifact export policies, versioned verification checks, image provenance, resource inventory, receipts, doctor/clean, performance signals, offline tests, compatibility documentation, and example definitions.

Future possibilities, not current behavior:

- Podman and other OCI-compatible adapters.
- gVisor-compatible Docker runtime and microVM backends.
- Controlled network proxy and honest domain allowlists.
- Signature key lifecycle/transparency policy and provenance integrations beyond the optional local cosign verification hook.
- Agent context adapters for PackWrite/Muzzle.
- Direct RunLedger/ChangeBucket/ShipCheck/Fence adapters where stable contracts justify them.
- Prepared image and package caching with explicit isolation.
- Parallel scheduling, remote execution, and hosted service controls.
