#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
MARKER_DIR="$(mktemp -d)"
TMP_REPO="$(mktemp -d)"
OUTPUT_DIR="$(mktemp -d)"
trap 'rm -rf "$MARKER_DIR" "$TMP_REPO" "$OUTPUT_DIR"' EXIT

chmod +x "$ROOT/tests/fixtures/startup-failure/docker"
git -C "$TMP_REPO" init -q
git -C "$TMP_REPO" config user.email workcell@example.invalid
git -C "$TMP_REPO" config user.name Workcell
printf '# Startup fixture\n' > "$TMP_REPO/README.md"
git -C "$TMP_REPO" add README.md
git -C "$TMP_REPO" commit -qm initial
jq '.environment.allow = ["WORKCELL_STARTUP_MARKER"]' "$ROOT/examples/hello/workcell.json" > "$OUTPUT_DIR/startup.json"

set +e
PATH="$ROOT/tests/fixtures/startup-failure:$PATH" \
WORKCELL_STARTUP_MARKER="$MARKER_DIR/marker" \
  "$KUJO" run "$ROOT/main.kujo" -- run --file "$OUTPUT_DIR/startup.json" --repo "$TMP_REPO" --output "$OUTPUT_DIR" --json > "$OUTPUT_DIR/result.json"
code=$?
set -e

test "$code" -eq 5
jq -e '.stage == "starting" and .exit_code == 5 and .cleanup_status == "complete" and (.error | contains("daemon startup failure"))' "$OUTPUT_DIR/result.json" >/dev/null
test -f "$MARKER_DIR/marker.run"
test -f "$MARKER_DIR/marker.inspect"
test -f "$MARKER_DIR/marker.stop"
test -f "$MARKER_DIR/marker.rm"
receipt="$(find "$OUTPUT_DIR" -name receipt.json -print -quit)"
jq -e '.final_status == "failed" and .cleanup_status == "complete" and .exit_code == 5' "$receipt" >/dev/null
echo "startup failure contract passed"
