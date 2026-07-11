# Known Limitations

- Docker is the only backend and must be installed/running for `run`.
- The Kujo example image builds Kujo from a pinned upstream commit and therefore needs network access during its one-time Docker image build.
- The current Kujo process API has no working-directory option; Workcell uses `git -C` and Docker `--workdir` instead.
- Dirty repositories are rejected rather than snapshotting uncommitted changes.
- Patch generation is Git diff based and now includes untracked files through Git's binary no-index diff; rename detection remains Git's responsibility.
- The MVP supports `network: none|default|custom`; custom networks must be pre-created by the operator, and domain allowlists or a transparent proxy remain external controls.
- Secrets are redacted from known exact values and common base64 encodings in logs, not from arbitrary hashed output or artifact contents.
- Verification records policy/artifact-boundary checks and command success; it does not automatically run ShipCheck or project tests inside every definition.
- Docker integration, timeout, failure, and cleanup behavior run in CI on a clean Docker host; local daemon validation remains recommended before release.
- RunLedger, ChangeBucket, ShipCheck, Fence, CaseFile, PackWrite, and Muzzle are documented integration points; the current runtime keeps them optional and standalone.
- Digest pinning and optional cosign public-key verification are supported through `runtime.image_digest` and `runtime.signature_key`; key lifecycle and transparency policy remain deployment responsibilities.
