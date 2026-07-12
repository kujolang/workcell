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
- Workcell-built images receive deterministic ownership, run ID, project, and version labels; the integration suite verifies the label set.
- Source workspaces are scanned for symlinks, output roots reject symlink components, and temporary workspace deletion requires a Workcell ownership marker.
- Resource values are bounded (CPU, memory, PIDs, and a 24-hour timeout maximum); duration parsing rejects non-integer amounts.

## Adversarial review

Offline tests (74 assertions plus 8 workspace patch/change-report assertions) reject host network, parent traversal, absolute artifact paths, unsafe tmpfs targets and mount targets, symlink artifact sources, image shell metacharacters, unknown fields, invalid timeouts, duplicate secret/artifact inputs, undeclared secret assignments, invalid environment names/values, unbounded resources, bounded artifact policies, invalid verification plans, invalid workspace scan/run-as policies, privileged argument presence, Docker socket references, host-control/proxy environment exposure, arbitrary absolute output destinations, digest/signature-key errors, custom-network and security-profile validation errors, namespace regressions, null process output, exact/base64-derived secret leakage regressions, secret literals in receipts/errors/verification plans, spoofed ownership markers, optional integration defaults/bounds/redaction, Podman policy selection, and partial-default regressions. `inspect --json` was inspected to confirm the effective policy contains `--network none`, `--read-only`, `--init`, private IPC, `--cap-drop ALL`, `no-new-privileges`, host-mapped non-root identity, labels, bounded resources, and only the workspace mount. Fence reports zero boundary violations.

Docker integration now covers timeout termination, Docker exit-125 workload classification, arbitrary output-path rejection, and label-scoped cleanup on the local daemon. Privileged/socket/root-mount rejection remains policy-contract coverage rather than a separate adversarial container test.

## Residual risk

Docker daemon and host kernel trust, transformed secret leakage, external cosign key lifecycle/transparency policy, no hardened microVM, and no controlled proxy remain explicit limitations.
