#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"

if ! command -v docker >/dev/null 2>&1 || ! docker version >/dev/null 2>&1; then
  echo "SKIP Docker integration tests: Docker CLI/daemon unavailable"
  exit 0
fi

TMP_REPO="$(mktemp -d)"
OUT_ROOT="$(mktemp -d)"
UNRELATED_NAME=""
INTERNAL_NETWORK="workcell-internal-$$"
cleanup() {
  if [ -n "$UNRELATED_NAME" ]; then
    docker rm -f "$UNRELATED_NAME" >/dev/null 2>&1 || true
  fi
  docker network rm "$INTERNAL_NETWORK" >/dev/null 2>&1 || true
  rm -rf "$TMP_REPO" "$OUT_ROOT"
}
trap cleanup EXIT

git -C "$TMP_REPO" init -q
git -C "$TMP_REPO" config user.email workcell@example.invalid
git -C "$TMP_REPO" config user.name Workcell
printf '# Fixture\n' > "$TMP_REPO/README.md"
git -C "$TMP_REPO" add README.md
git -C "$TMP_REPO" commit -qm initial
docker network create --internal "$INTERNAL_NETWORK" >/dev/null

if docker buildx version >/dev/null 2>&1; then
  docker buildx build --load --tag kujolang/workcell-base:local "$ROOT/docker" >/dev/null
else
  docker build -q --tag kujolang/workcell-base:local "$ROOT/docker" >/dev/null
fi

BASE_DIGEST="$(docker image inspect --format '{{index .RepoDigests 0}}' kujolang/workcell-base:local 2>/dev/null || true)"
BASE_DIGEST="$(printf '%s' "$BASE_DIGEST" | sed 's/.*@//')"
if [ -n "$BASE_DIGEST" ]; then
  jq --arg digest "$BASE_DIGEST" '.runtime.image_digest = $digest' "$ROOT/examples/hello/workcell.json" > "$OUT_ROOT/digest.json"
  KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/digest.json" --repo "$TMP_REPO" --output "$OUT_ROOT/digest"
  jq --arg digest "sha256:$(printf '0%.0s' {1..64})" '.runtime.image_digest = $digest' "$ROOT/examples/hello/workcell.json" > "$OUT_ROOT/digest-mismatch.json"
  set +e
  KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/digest-mismatch.json" --repo "$TMP_REPO" --output "$OUT_ROOT/digest-mismatch" --json > "$OUT_ROOT/digest-mismatch.json.result"
  DIGEST_MISMATCH_CODE=$?
  set -e
  test "$DIGEST_MISMATCH_CODE" -eq 4
  jq -e '.stage == "preparing" and (.error | contains("image_digest mismatch"))' "$OUT_ROOT/digest-mismatch.json.result" >/dev/null
fi

jq '.runtime.signature_key = "missing-workcell.pub"' "$ROOT/examples/hello/workcell.json" > "$OUT_ROOT/signature-mismatch.json"
set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/signature-mismatch.json" --repo "$TMP_REPO" --output "$OUT_ROOT/signature-mismatch" --json > "$OUT_ROOT/signature-mismatch.json.result"
SIGNATURE_MISMATCH_CODE=$?
set -e
test "$SIGNATURE_MISMATCH_CODE" -eq 4
jq -e '.stage == "preparing" and (.error | contains("signature_key"))' "$OUT_ROOT/signature-mismatch.json.result" >/dev/null

jq --arg network "$INTERNAL_NETWORK" '.network.mode = "custom" | .network.name = $network' "$ROOT/examples/hello/workcell.json" > "$OUT_ROOT/internal-network.json"
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/internal-network.json" --repo "$TMP_REPO" --output "$OUT_ROOT/internal-network"

jq '.trust_profile = "native-guarded"' "$ROOT/examples/hello/workcell.json" > "$OUT_ROOT/native-guarded.json"
set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/native-guarded.json" --repo "$TMP_REPO" --output "$OUT_ROOT/native-guarded" --json > "$OUT_ROOT/native-guarded.json.result"
NATIVE_GUARDED_CODE=$?
set -e
if docker info --format '{{json .SecurityOptions}}' | grep -q 'rootless'; then
  test "$NATIVE_GUARDED_CODE" -eq 0
else
  test "$NATIVE_GUARDED_CODE" -eq 4
  jq -e '.stage == "preparing" and (.error | contains("native-guarded"))' "$OUT_ROOT/native-guarded.json.result" >/dev/null
fi

cp -R "$ROOT/docker" "$TMP_REPO/build-context"
git -C "$TMP_REPO" add build-context
git -C "$TMP_REPO" commit -qm "add runtime build context fixture"
jq '.runtime.image = "kujolang/workcell-runtime-build:integration" | .runtime.build_context = "build-context" | .artifacts.export = []' "$ROOT/examples/hello/workcell.json" > "$OUT_ROOT/runtime-build.json"
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/runtime-build.json" --repo "$TMP_REPO" --output "$OUT_ROOT/runtime-build" --no-pull

KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$ROOT/examples/hello/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/hello"
test -f "$OUT_ROOT/hello"/*/receipt.json
test -f "$OUT_ROOT/hello"/*/artifacts/hello.txt
git -C "$TMP_REPO" diff --quiet

KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$ROOT/examples/controlled-edit/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/edit"
PATCH="$(find "$OUT_ROOT/edit" -name changes.patch -print -quit)"
grep -q "Edited inside a disposable Workcell" "$PATCH"
CHANGE_REPORT="$(find "$OUT_ROOT/edit" -name changes.json -print -quit)"
jq -e '.files[] | select(.path == "README.md" and .status == "modified")' "$CHANGE_REPORT" >/dev/null
git -C "$TMP_REPO" diff --quiet

set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$ROOT/examples/failure/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/failure"
FAILURE_CODE=$?
set -e
test "$FAILURE_CODE" -eq 7
FAILURE_RECEIPT="$(find "$OUT_ROOT/failure" -name receipt.json -print -quit)"
FAILED_WORKSPACE="$(jq -r '.workspace_path' "$FAILURE_RECEIPT")"
test -d "$FAILED_WORKSPACE"
test -f "$FAILED_WORKSPACE.owner"

ln -s /tmp "$OUT_ROOT/output-symlink"
set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$ROOT/examples/hello/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/output-symlink"
SYMLINK_OUTPUT_CODE=$?
set -e
test "$SYMLINK_OUTPUT_CODE" -eq 3

SYMLINK_REPO="$(mktemp -d)"
git -C "$SYMLINK_REPO" init -q
git -C "$SYMLINK_REPO" config user.email workcell@example.invalid
git -C "$SYMLINK_REPO" config user.name Workcell
ln -s /tmp "$SYMLINK_REPO/escape-link"
git -C "$SYMLINK_REPO" add escape-link
git -C "$SYMLINK_REPO" commit -qm symlink-fixture
set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$ROOT/examples/hello/workcell.json" --repo "$SYMLINK_REPO" --output "$OUT_ROOT/symlink-workspace"
SYMLINK_WORKSPACE_CODE=$?
set -e
test "$SYMLINK_WORKSPACE_CODE" -eq 3
rm -rf "$SYMLINK_REPO"

set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$ROOT/examples/timeout/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/timeout"
TIMEOUT_CODE=$?
set -e
test "$TIMEOUT_CODE" -eq 6

UNRELATED_NAME="workcell-unrelated-$$"
docker run -d --name "$UNRELATED_NAME" kujolang/workcell-base:local sh -c "sleep 30" >/dev/null
KUJO="$KUJO" "$ROOT/bin/workcell" clean >/dev/null
test -n "$(docker ps -aq --filter "name=^/${UNRELATED_NAME}$")"
docker rm -f "$UNRELATED_NAME" >/dev/null
test -z "$(docker ps -aq --filter label=dev.kujo.workcell=true)"
KUJO="$KUJO" "$ROOT/bin/workcell" clean >/dev/null
test ! -e "$FAILED_WORKSPACE"
test ! -e "$FAILED_WORKSPACE.owner"
echo "Docker integration tests passed"
