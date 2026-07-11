# Workcell Examples

The JSON definitions below are intended to be copied into a clean Git fixture or passed to Workcell with `--file`. They use `alpine:3.20` unless otherwise noted. Build the local base image first when using the Dockerfile-based example:

```bash
docker build --tag kujolang/workcell-base:local docker/
```

For a real run, the repository passed to `--repo` must be clean. The default offline test suite does not require Docker; integration commands are documented in `docs/development.md`.

- `hello/workcell.json`: writes and exports one declared artifact.
- `kujo-project-check/workcell.json`: runs a Kujo check inside a Kujo image.
- `controlled-edit/workcell.json`: edits a tracked README and exports it, producing a patch.
- `failure/workcell.json`: exits non-zero and preserves diagnostic evidence.
- `timeout/workcell.json`: exceeds a short timeout and exercises termination.
