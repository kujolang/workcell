# ADR 003: Restrictive Default Policy

## Context

Sandbox safety should not depend on every caller remembering to set security flags.

## Decision

Default to network none, non-root, read-only root, dropped capabilities, no-new-privileges, bounded resources, explicit environment, no sensitive host mounts, and declared artifact export.

## Consequences

Some dependency-installing workflows need an explicit `network: default` policy and still remain bounded. Domain allowlists are not modeled until a controlled proxy exists.
