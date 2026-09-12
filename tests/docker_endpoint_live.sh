#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
if [[ "${WORKCELL_ENDPOINT_LIVE:-0}" != 1 ]]; then
  echo 'SKIP selected Docker endpoint live test: explicit local gate required'
  exit 0
fi
# Use only an existing local image. No build, pull, network or daemon mutation.
docker image inspect alpine:3.20 >/dev/null
run_as=host
if docker info --format '{{json .SecurityOptions}}' | jq -e 'any(.[]; contains("rootless"))' >/dev/null; then
  run_as=rootless
fi
mkdir -p "$ROOT/.muzzle/reports"
fixture="$(mktemp -d "$ROOT/.muzzle/reports/endpoint-live.XXXXXX")"
mkdir "$fixture/source"
git -C "$fixture/source" init -q
git -C "$fixture/source" config user.name 'Workcell Fixture'
git -C "$fixture/source" config user.email 'fixture@example.invalid'
printf 'endpoint fixture\n' > "$fixture/source/README.md"
git -C "$fixture/source" add README.md
git -C "$fixture/source" commit -qm fixture
jq --arg run_as "$run_as" '.runtime.image="alpine:3.20" | .workspace.run_as=$run_as | .command=["sh","-c","test -z \"${DOCKER_HOST:-}${DOCKER_CONTEXT:-}${DOCKER_CONFIG:-}${HTTP_PROXY:-}${http_proxy:-}\" && printf endpoint-ok > hello.txt"]' \
  "$ROOT/examples/hello/workcell.json" > "$fixture/definition.json"
TMPDIR="$fixture" KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$fixture/definition.json" --repo "$fixture/source" --output "$fixture/output" --no-pull --summary > "$fixture/summary.json"
receipt="$(find "$fixture/output" -name receipt.json -print -quit)"
test -n "$receipt"
jq -e '.final_status=="completed" and .cleanup_status=="complete"' "$receipt" >/dev/null
KUJO="$KUJO" "$ROOT/bin/workcell" verify --run "$(dirname "$receipt")" --json > "$fixture/integrity.json"
printf 'Selected endpoint live test passed; evidence: %s\n' "$fixture"
