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
cleanup() {
  if [ -n "$UNRELATED_NAME" ]; then
    docker rm -f "$UNRELATED_NAME" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_REPO" "$OUT_ROOT"
}
trap cleanup EXIT

git -C "$TMP_REPO" init -q
git -C "$TMP_REPO" config user.email workcell@example.invalid
git -C "$TMP_REPO" config user.name Workcell
printf '# Fixture\n' > "$TMP_REPO/README.md"
git -C "$TMP_REPO" add README.md
git -C "$TMP_REPO" commit -qm initial

docker build -q --tag kujolang/workcell-base:local "$ROOT/docker" >/dev/null

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
