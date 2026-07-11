# Workcell Examples

The JSON definitions below are intended to be copied into a clean Git fixture or passed to Workcell with `--file`. Build the local images before running them:

For a real run, the repository passed to `--repo` must be clean. The default offline test suite does not require Docker; integration commands are documented in `docs/development.md`.

Build the two local images used by the examples:

```bash
docker build --tag kujolang/workcell-base:local docker/
docker build --tag kujolang/workcell-kujo:local docker/kujo/
```

- `hello/workcell.json`: writes and exports one declared artifact.
- `kujo-project-check/workcell.json`: builds a pinned Kujo runtime image and runs a Kujo check inside it.
- `controlled-edit/workcell.json`: edits a tracked README and exports it, producing a patch.
- `failure/workcell.json`: exits non-zero and preserves diagnostic evidence.
- `timeout/workcell.json`: exceeds a short timeout and exercises termination.
