# ADR 001: Docker-First Runtime

## Context

Workcell needs a portable local execution boundary and must remain open to future OCI or isolated runtimes.

## Decision

Implement Docker as the default runtime adapter and keep OCI engine-specific operations behind `src/runtime/docker.kujo`; compatible backends such as Podman may implement the same boundary without weakening policy guarantees.

## Alternatives

Podman, Firecracker, gVisor, Kubernetes, and a custom OCI engine were deferred because they add operational scope beyond a credible local MVP.

## Consequences

The MVP depends on a trusted Docker daemon and does not claim microVM isolation. Additional backends can reuse the domain/policy/lifecycle contracts.

## Reconsider when

Local Docker is insufficient for the threat model or a stable OCI/runtime adapter contract is available.
