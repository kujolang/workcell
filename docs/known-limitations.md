# Known Limitations

- Docker is the only backend and must be installed/running for `run`.
- The current Kujo process API has no working-directory option; Workcell uses `git -C` and Docker `--workdir` instead.
- Dirty repositories are rejected rather than snapshotting uncommitted changes.
- Patch generation is Git diff based; untracked files are reported and exported only when declared, but are not synthesized into a unified patch.
- The MVP supports `network: none|default`, not domain allowlists or a proxy.
- Secrets are redacted from known exact values in logs, not from arbitrary derived output or artifact contents.
- Verification records policy/artifact-boundary checks and command success; it does not automatically run ShipCheck or project tests inside every definition.
- Docker integration, timeout, failure, and cleanup behavior must be run on a host with Docker before release.
- RunLedger, ChangeBucket, ShipCheck, Fence, CaseFile, PackWrite, and Muzzle are documented integration points; the current runtime keeps them optional and standalone.
