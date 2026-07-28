# Launch Checklist

Current launch scope: `not yet proven` for this batch because Workcell's Docker proof could not run in the local environment. Native offline checks passed locally; release-candidate scope requires a current Workcell receipt for the exact commit.

## Local Gates

- [x] CLI help/version checked with `./bin/workcell --help` and `./bin/workcell --version`.
- [x] Definition validation checked with `./bin/workcell validate --file workcell.json`.
- [x] Native offline suite checked with `./tests/run.sh`.
- [x] Kujo/shell quality gate checked with `./tests/quality.sh`.
- [x] Formatting checked with `git diff --check`.
- [ ] Docker image build checked with `docker build --tag kujolang/workcell-base:local docker/`.
- [ ] Workcell run checked with `./bin/workcell run --file workcell.json --repo .`.
- [ ] Workcell receipt verification checked with `./bin/workcell verify --run <run-dir> --json`.

## Current External Blocker

Docker proof is blocked by the local Docker host's inability to fetch the pinned Alpine base image from Docker Hub. The attempted build failed after the credential-helper workaround with `lookup auth.docker.io: i/o timeout`.

Closest equivalent proof: native offline Workcell checks, definition validation, and local doctor checks.

Safe resume command:

```bash
export KUJO=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo
DOCKER_HOST=unix:///Users/robertdevore/.colima/kujo-workcell/docker.sock docker build --tag kujolang/workcell-base:local docker/
./bin/workcell run --file workcell.json --repo .
./bin/workcell verify --run .workcell/runs/<run-id> --json
```

## Forbidden Launch Actions

Publishing images, creating releases, pushing final tags, deploying hosted runners, live credential proof, signing/notarizing, branch-protection changes, force-pushes, and production/enterprise claims without target-environment proof remain out of scope.
