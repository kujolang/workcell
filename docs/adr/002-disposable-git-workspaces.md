# ADR 002: Disposable Git Workspaces

## Context

An agent workload must not receive uncontrolled write access to the real repository.

## Decision

Reject dirty sources by default and execute in a detached Git worktree, with isolated clone fallback available by definition.

## Alternatives

Mounting the source repository read-write was rejected. Copying arbitrary directories was rejected because it loses commit/patch provenance and needs more symlink policy.

## Consequences

Source commits and patches are attributable. Uncommitted user changes are preserved by refusing execution rather than being silently omitted.
