#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
MARKER_DIR="$(mktemp -d)"
trap 'rm -rf "$MARKER_DIR"' EXIT

PATH="$ROOT/tests/fixtures/verification-cleanup:$PATH" \
WORKCELL_VERIFICATION_MARKER="$MARKER_DIR/marker" \
  "$KUJO" run "$ROOT/tests/verification_cleanup_contract.kujo"

test -f "$MARKER_DIR/marker.run"
test -f "$MARKER_DIR/marker.stop"
test -f "$MARKER_DIR/marker.rm"
echo "verification cleanup integration passed"
