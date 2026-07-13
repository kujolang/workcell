# Iteration 010 action

- Added `network.egress` fields for policy, DNS ownership, proxy ownership, and enforcement profile.
- Added fail-closed validation for `network.mode: none` and managed egress; older default/custom definitions receive explicit `unmanaged` compatibility mode.
- Added effective/configured network policy data to inspect output, security policy, and `workcell-receipt/v1`; unmanaged access emits a receipt warning.
- Added the managed-egress example and Docker/schema/offline contract coverage.
- Recorded the GitHub Actions billing block and Intel macOS Podman limitation as external evidence blockers.
