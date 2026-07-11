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
trap 'rm -rf "$TMP_REPO" "$OUT_ROOT"' EXIT

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
git -C "$TMP_REPO" diff --quiet

set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$ROOT/examples/timeout/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/timeout"
TIMEOUT_CODE=$?
set -e
test "$TIMEOUT_CODE" -eq 6

test -z "$(docker ps -aq --filter label=dev.kujo.workcell=true)"
echo "Docker integration tests passed"
