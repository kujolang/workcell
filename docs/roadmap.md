# Workcell Roadmap

Implemented now: local Docker backend, JSON v1 definitions, disposable Git workspaces, restrictive default policy, bounded resources/timeouts, declared artifact export, receipts, doctor/clean, offline tests, and example definitions.

Future possibilities, not current behavior:

- Podman and other OCI-compatible adapters.
- gVisor-compatible Docker runtime and microVM backends.
- Controlled network proxy and honest domain allowlists.
- Image signing/verification and provenance policy.
- Agent context adapters for PackWrite/Muzzle.
- Direct RunLedger/ChangeBucket/ShipCheck/Fence adapters where stable contracts justify them.
- Prepared image and package caching with explicit isolation.
- Parallel scheduling, remote execution, and hosted service controls.
