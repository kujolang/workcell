# Workcell Examples

The JSON definitions below are intended to be copied into a clean Git fixture or passed to Workcell with `--file`. Build the local images before running them:

For a real run, the repository passed to `--repo` must be clean. The default offline test suite does not require Docker; integration commands are documented in `docs/development.md`.

Use Kujo 1.2.1 at the exact commit in `../RUNTIME_VERSION`. Docker examples run on supported Linux or macOS Docker hosts; Podman-compatible rows require supported Linux Podman and the backend/identity settings documented in [platform compatibility](../docs/compatibility.md).

Build the two local images used by the examples:

```bash
docker build --tag kujolang/workcell-base:local docker/
docker/kujo/build-local.sh /path/to/kujo-source
```

- `hello/workcell.json`: writes and exports one declared artifact.
- `kujo-project-check/workcell.json`: runs a pinned Kujo runtime image and executes a Kujo check inside it. The local-source image build avoids private repository credentials.
- `controlled-edit/workcell.json`: edits a tracked README and exports it, producing a patch.
- `verification/workcell.json`: creates an artifact, runs a declared post-run check, and records execution versus verification separately.
- `failure/workcell.json`: exits non-zero and preserves diagnostic evidence.
- `timeout/workcell.json`: exceeds a short timeout and exercises termination.
- `secrets/workcell.json`: passes a declared secret by name and redacts it from exported text.
- `custom-network/workcell.json`: attaches to a pre-created operator-owned internal network.
- `egress-policy/workcell.json`: declares a host-enforced deny-by-default egress policy, DNS/proxy ownership, and an enforcement profile; Workcell records the declaration but does not install the firewall or proxy. Run `tests/egress_integration.sh` to exercise the managed policy on a temporary Docker internal network.
- `provenance/workcell.json`: demonstrates fail-closed digest and registry policy; replace the placeholder digest before a successful run.
- `signature/workcell.json`: demonstrates fail-closed cosign verification; replace `signature/workcell.pub` with an approved key and sign the selected image.
- `artifact-policy/workcell.json`: demonstrates declared secret rejection during artifact export.
- `portable/workcell.json`: keeps the v2 workload independent of the Docker/Podman choice in `portable/host-profiles.json`; use `inspect --summary` for compact capability preflight.

The example matrix is intentionally explicit about dependencies:

| Example | Offline validation | Docker | Podman | Cosign/key | Sibling tools |
| --- | --- | --- | --- | --- | --- |
| `hello`, `controlled-edit`, `verification`, `failure`, `timeout` | yes | required to run | no | no | no |
| `secrets`, `artifact-policy` | yes | required; provide the named host secret | compatible backend optional | no | no |
| `custom-network` | yes | required; pre-create `workcell-internal-demo` | compatible backend optional | no | no |
| `egress-policy` | yes | required; pre-create the operator-enforced `workcell-egress-demo` network | compatible backend optional | no | host firewall/proxy profile required |
| `provenance` | yes | required; replace digest | compatible backend optional | no | no |
| `signature` | yes | required; replace key and sign image | compatible backend optional | required | no |
| `kujo-project-check` | yes | required | no | no | Kujo source checkout |
| `portable` | yes | selected by host profile | selected by host profile | no | no |
