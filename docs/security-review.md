# Workcell Security Review

## Implemented protections

- Clean-source enforcement prevents silent omission of dirty repository changes.
- Git worktree/clone isolation prevents direct writable mounts of the source repository.
- Structured argv prevents host-side command injection through image/path arguments.
- Docker policy rejects host networking, privileged mode, Docker socket/root/home/credential mounts, host namespaces, devices, and unbounded resource values.
- Containers receive non-root identity, read-only root by default, no-new-privileges, dropped capabilities, explicit network, resource, PID, and timeout limits.
- Artifact paths are normalized and contained; only declared outputs are copied.
- Secret names are explicit, values are runtime-only, and known values are redacted from captured logs and excluded from receipts.
- Cleanup filters Docker resources by Workcell ownership labels.

## Adversarial review

Offline tests (19 assertions) reject host network, parent traversal, absolute artifact paths, image shell metacharacters, unknown fields, invalid timeouts, undeclared secret assignments, privileged argument presence, and Docker socket references. `inspect --json` was inspected to confirm the effective policy contains `--network none`, `--read-only`, `--cap-drop ALL`, `no-new-privileges`, labels, bounded resources, and only the workspace mount. Fence reported zero boundary violations.

Docker-specific adversarial runs for privileged/socket/root mounts, container collisions, timeout termination, and label-scoped cleanup could not execute because Docker is not installed in the current environment. They remain required before an MVP release claim.

## Residual risk

Docker daemon and host kernel trust, transformed secret leakage, no image signature verification, no hardened microVM, and no controlled proxy remain explicit limitations.
