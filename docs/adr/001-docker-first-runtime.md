# ADR 001: Docker-First Runtime

## Context

Workcell needs a portable local execution boundary and must remain open to future OCI or isolated runtimes.

## Decision

Implement Docker as the default runtime adapter and keep OCI engine-specific operations behind `src/runtime/docker.kujo`; compatible backends such as Podman may implement the same boundary without weakening policy guarantees.

## Alternatives

At the original pre-1.0 decision, Podman, Firecracker, gVisor, Kubernetes, and a custom OCI engine were deferred because they added operational scope beyond a credible local MVP. Podman was subsequently implemented for the stable v1 OCI contract; the other alternatives remain outside the v1 guarantee.

## Consequences

The original MVP depended on a trusted Docker daemon and did not claim microVM isolation. Stable v1 supports Docker and Podman while retaining daemon and host-kernel trust and no microVM claim. Additional backends can reuse the domain, policy, and lifecycle contracts only if they document their guarantees explicitly.

## Reconsider when

Local Docker is insufficient for the threat model or a stable OCI/runtime adapter contract is available.
