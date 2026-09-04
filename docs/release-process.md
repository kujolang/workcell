# Workcell Release Process

This process prepares and publishes Workcell source releases without publishing a container image, package registry entry, hosted runner, or hosted execution service. The current release is `v1.1.0`. Its stable guarantee covers the local and CI Docker/Podman contract on the host classes in [platform compatibility](compatibility.md). The provider-neutral contracts and remote adapters included in the source remain alpha and are not promoted by the core release.

Before preparing a release, choose its version through normal review, update `VERSION`, package metadata, the README badge, changelog heading, filenames below, and compatibility notes together, then run the consistency gate. Never recreate or move an existing tag.

## Release inputs

- Product version: `VERSION`, mirrored by `kujo.toml` and `kennel.toml`.
- Runtime: Kujo 1.2.1 at the exact commit in `RUNTIME_VERSION`.
- Release commit: one reviewed, clean commit that has passed local gates and hosted CI.
- Tag: annotated `v1.1.0`, created only after human approval.

Definition, receipt, manifest, report, provenance, CLI metadata, and other `/v1` identifiers are independent contract versions and are not replaced with the product version.

## Exact pre-tag checklist

- [ ] Confirm `git status --short` is empty and the approved commit is on `main`.
- [ ] Confirm `VERSION`, `kujo.toml`, `kennel.toml`, the CLI, README badge, changelog, release report, and artifact names agree on `1.1.0`.
- [ ] Confirm `kennel.toml` declares production, stable, public API status with the narrow local Docker/Podman scope note.
- [ ] Confirm `RUNTIME_VERSION` is `692512a9070fdba713f160d795bbddb8077db7b5` and the test binary was built from that commit.
- [ ] Run the offline, quality, version-consistency, release-report, Markdown-link, and whitespace gates below.
- [ ] Run official-adapter installation, offline conformance, and integrity verification; confirm the lockfile and executable digests match the reviewed source.
- [ ] Run Docker build, doctor, integration, concurrent-load, egress, self-proof, receipt verification, and cleanup evidence.
- [ ] Run Podman doctor, OCI smoke, integration, concurrent-load, and egress evidence on supported Linux.
- [ ] Run ShipCheck with exit code `0`, zero errors, and no warning that contradicts the v1 contract.
- [ ] Review the hosted CI run for the exact approved commit and confirm every job and step passed. Local evidence is not a substitute.
- [ ] Review [the security model](security-model.md), [enterprise boundary](enterprise-deployment.md), and [known limitations](known-limitations.md) for claim accuracy.
- [ ] If promoting an alpha remote adapter, retain credential-gated evidence for the exact account, plan, region, adapter/API/SDK version, capability probes, spend ceiling, and zero owned orphans. A core Workcell release does not automatically promote an adapter.
- [ ] Confirm no generated `.workcell`, CaseFile, RunLedger, test output, or temporary release artifacts are tracked.
- [ ] Obtain explicit human approval for the exact commit SHA before creating the tag.

## Reproduce release gates

```bash
export KUJO=/path/to/kujo-1.2.1/target/release/kujo
test "$(git -C /path/to/kujo-1.2.1 rev-parse HEAD)" = "$(cat RUNTIME_VERSION)"
./bin/workcell --help
./bin/workcell --version
./bin/workcell validate --file workcell.json
KUJO="$KUJO" ./tests/version_consistency.sh
KUJO="$KUJO" ./tests/run.sh
KUJO="$KUJO" ./tests/quality.sh
KUJO="$KUJO" ./tests/release_report.sh
./tests/markdown_links.sh
git diff --check
npm ci --ignore-scripts --prefix adapters/official
npm test --prefix adapters/official
npm run integrity:check --prefix adapters/official
KUJO="$KUJO" ./tests/live_certification_contract.sh
```

Docker:

```bash
docker build --tag kujolang/workcell-base:local docker/
KUJO="$KUJO" ./bin/workcell doctor --backend docker --json
KUJO="$KUJO" ./tests/docker_integration.sh docker
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/load_integration.sh docker
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/egress_integration.sh docker
KUJO="$KUJO" ./bin/workcell run --file workcell.json --repo . --no-pull --json
KUJO="$KUJO" ./bin/workcell verify --run <run-directory> --json
WORKCELL_LIVE_PORTABLE_OCI=1 KUJO="$KUJO" ./tests/portable_oci_contract.sh
```

Podman on supported Linux:

```bash
KUJO="$KUJO" ./bin/workcell doctor --backend podman --json
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/oci_smoke.sh podman
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/docker_integration.sh podman
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/load_integration.sh podman
REQUIRE_BACKEND=true KUJO="$KUJO" ./tests/egress_integration.sh podman
```

ShipCheck:

```bash
cd ../shipcheck
KUJO_BIN="$KUJO" "$KUJO" run shipcheck.kujo gate --dir ../workcell --format json
```

## Expected artifacts

The tag-triggered `release-artifacts` workflow calls the reusable CI workflow first. Only after all real release gates pass does it upload a workflow artifact containing:

- `workcell-1.1.0-source.tar.gz` — repository source at the tagged commit, rooted at `workcell-1.1.0/`;
- `workcell-1.1.0-release-report.json` — offline suite report with product version metadata;
- `workcell-1.1.0-provenance.json` — source commit, tag, Kujo runtime commit, filenames, and hashes;
- `workcell-1.1.0-checksums.txt` — SHA-256 checksums for the archive, report, and provenance record.

To reproduce before tagging, generate the report and artifacts outside the repository:

```bash
release_tmp="$(mktemp -d)"
KUJO="$KUJO" ./tests/release_report.sh > "$release_tmp/report.json"
./scripts/build_release_artifacts.sh "$release_tmp/artifacts" "$release_tmp/report.json" HEAD
cd "$release_tmp/artifacts"
shasum -a 256 -c workcell-1.1.0-checksums.txt
tar -tzf workcell-1.1.0-source.tar.gz | head
jq -e '.version == "1.1.0" and .tag == "v1.1.0"' workcell-1.1.0-provenance.json
```

## Tag and GitHub Release after approval

Do not run these commands until a human approves the exact commit:

```bash
git fetch origin
git switch main
git pull --ff-only origin main
test "$(git rev-parse HEAD)" = "<approved-commit-sha>"
git tag -a v1.1.0 -m "Workcell v1.1.0" <approved-commit-sha>
git push origin v1.1.0
```

Wait for the tag-triggered `release-artifacts` workflow to pass. Download its artifact, verify `workcell-1.1.0-checksums.txt`, verify the provenance commit equals the tagged commit, and inspect the archive. Then create the GitHub Release and attach all four files:

```bash
gh release create v1.1.0 \
  --repo kujolang/workcell \
  --verify-tag \
  --title "Workcell v1.1.0" \
  --notes-from-tag \
  workcell-1.1.0-source.tar.gz \
  workcell-1.1.0-release-report.json \
  workcell-1.1.0-provenance.json \
  workcell-1.1.0-checksums.txt
```

## Rollback and failed release handling

- If a pre-tag gate fails, do not tag. Fix on the preparation branch and repeat every affected gate.
- If the tag workflow fails, do not create a GitHub Release. Preserve the failed run URL and logs, fix forward, and obtain human approval for the new commit.
- If an unpublished incorrect tag must be replaced, a repository administrator must explicitly approve deleting the remote and local tag before recreating it. Never move a published tag silently.
- If the GitHub Release has been published, do not rewrite `v1.1.0`. Mark the release as affected, document remediation, and publish a new patch release such as `v1.1.1` from a separately approved commit.
- Source archives and checksums are immutable once published. A checksum mismatch blocks publication and requires rebuilding from the approved tag, not editing an artifact in place.
