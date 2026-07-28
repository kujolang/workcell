# Launch Checklist

Current launch scope: `locally verified technical preview`. Native offline checks and Workcell self-proof passed locally for the exact batch commit. Release-candidate scope still requires clean-machine setup proof and the broader Docker/Podman integration gate set.

## Local Gates

- [x] CLI help/version checked with `./bin/workcell --help` and `./bin/workcell --version`.
- [x] Definition validation checked with `./bin/workcell validate --file workcell.json`.
- [x] Native offline suite checked with `./tests/run.sh`.
- [x] Kujo/shell quality gate checked with `./tests/quality.sh`.
- [x] Formatting checked with `git diff --check`.
- [x] Docker image build checked with `DOCKER_BUILDKIT=0 docker build --tag kujolang/workcell-base:local docker/`.
- [x] Workcell run checked with `./bin/workcell run --file workcell.json --repo . --no-pull`.
- [x] Workcell receipt verification checked with `./bin/workcell verify --run <run-dir> --json`.

## Workcell Proof Notes

The initial Workcell proof was blocked by Docker Desktop credential-helper and BuildKit IPv6/DNS behavior. The successful local proof used a credential-free temporary Docker config, the Colima Workcell Docker host, `DOCKER_BUILDKIT=0`, and `TMPDIR` under `/Users/robertdevore/2026/Kujolang/kujo-repos/.workcell-host-tmp` so the mounted worktree was visible inside the Colima VM.

Reproduction command:

```bash
export KUJO=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo
export DOCKER_HOST=unix:///Users/robertdevore/.colima/kujo-workcell/docker.sock
export DOCKER_CONFIG=/tmp/kujo-next-batch-docker-config
export DOCKER_BUILDKIT=0
export TMPDIR=/Users/robertdevore/2026/Kujolang/kujo-repos/.workcell-host-tmp
docker build --tag kujolang/workcell-base:local docker/
./bin/workcell run --file workcell.json --repo . --no-pull
./bin/workcell verify --run .workcell/runs/<run-id> --json
```

## Forbidden Launch Actions

Publishing images, creating releases, pushing final tags, deploying hosted runners, live credential proof, signing/notarizing, branch-protection changes, force-pushes, and production/enterprise claims without target-environment proof remain out of scope.
