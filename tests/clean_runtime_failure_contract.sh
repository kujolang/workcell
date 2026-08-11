#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
TEMP_BASE="$(mktemp -d)"
OUTPUT="$(mktemp)"
RUN_ID="wc-0123456789abcdef0123456789abcdef"
WORKSPACE="$TEMP_BASE/kujo-workcell-$RUN_ID"
trap 'rm -rf "$TEMP_BASE" "$OUTPUT"' EXIT

chmod +x "$ROOT/tests/fixtures/runtime-unavailable/docker"
mkdir -p "$WORKSPACE"
printf 'workcell-run-id=%s\n' "$RUN_ID" > "$WORKSPACE.owner"

set +e
TMPDIR="$TEMP_BASE" PATH="$ROOT/tests/fixtures/runtime-unavailable:$PATH" \
  KUJO="$KUJO" "$ROOT/bin/workcell" clean --backend docker --json > "$OUTPUT"
code=$?
set -e

test "$code" -eq 9
jq -e '.ok == false and (.temporary_workspaces.skipped[0] | contains("preserved"))' "$OUTPUT" >/dev/null
test -d "$WORKSPACE"
test -f "$WORKSPACE.owner"
echo "Runtime-failure cleanup contract passed"
