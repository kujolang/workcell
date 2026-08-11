#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
MARKER_DIR="$(mktemp -d)"
TMP_REPO="$(mktemp -d)"
OUTPUT_DIR="$(mktemp -d)"
workspace=""

cleanup() {
  if [ -n "$workspace" ] && [ -e "$workspace" ]; then
    git -C "$TMP_REPO" worktree remove --force "$workspace" >/dev/null 2>&1 || true
    rm -f "$workspace.owner"
  fi
  rm -rf "$MARKER_DIR" "$TMP_REPO" "$OUTPUT_DIR"
}
trap cleanup EXIT

chmod +x "$ROOT/tests/fixtures/lifecycle/docker"
git -C "$TMP_REPO" init -q
git -C "$TMP_REPO" config user.email workcell@example.invalid
git -C "$TMP_REPO" config user.name Workcell
printf '# Lifecycle fixture\n' > "$TMP_REPO/README.md"
git -C "$TMP_REPO" add README.md
git -C "$TMP_REPO" commit -qm initial
jq '.environment.allow = ["WORKCELL_LIFECYCLE_MARKER"] | .verification.commands = [{"name":"must-not-run","command":["true"]}]' \
  "$ROOT/examples/hello/workcell.json" > "$OUTPUT_DIR/lifecycle.json"

set +e
PATH="$ROOT/tests/fixtures/lifecycle:$PATH" \
WORKCELL_LIFECYCLE_MARKER="$MARKER_DIR/marker" \
  "$KUJO" run "$ROOT/main.kujo" -- run --file "$OUTPUT_DIR/lifecycle.json" --repo "$TMP_REPO" --output "$OUTPUT_DIR" --keep-failed --json > "$OUTPUT_DIR/result.json"
code=$?
set -e

test "$code" -eq 8
jq -e '.stage == "verification-failed" and .exit_code == 8 and .cleanup_status == "preserved"' "$OUTPUT_DIR/result.json" >/dev/null
receipt="$(jq -r '.receipt_path' "$OUTPUT_DIR/result.json")"
workspace="$(jq -r '.receipt.workspace_path' "$OUTPUT_DIR/result.json")"
jq -e '.final_status == "verification-failed" and (.lifecycle | index("completed") | not) and (.lifecycle | index("failed") != null) and .verification.checks[0].status == "skipped"' "$receipt" >/dev/null
test -f "$MARKER_DIR/marker.workload"
test ! -e "$MARKER_DIR/marker.verify"
test -d "$workspace"
test -f "$workspace.owner"
echo "Lifecycle failure contract passed"
