#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
TMP_DIR="$(mktemp -d)"
MISSING_OUTPUT="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR" "$MISSING_OUTPUT"' EXIT

"$KUJO" run "$ROOT/main.kujo" -- init --file "$TMP_DIR/workcell.json"
test -f "$TMP_DIR/workcell.json"

set +e
"$KUJO" run "$ROOT/main.kujo" -- init --file "$TMP_DIR/workcell.json" >/dev/null
INIT_CODE=$?
set -e
test "$INIT_CODE" -eq 2

git -C "$TMP_DIR" init -q
git -C "$TMP_DIR" config user.email workcell@example.invalid
git -C "$TMP_DIR" config user.name Workcell
printf '# Fixture\n' > "$TMP_DIR/README.md"
git -C "$TMP_DIR" add README.md
git -C "$TMP_DIR" commit -qm initial
git -C "$TMP_DIR" add workcell.json
git -C "$TMP_DIR" commit -qm "add workcell definition fixture"

"$KUJO" run "$ROOT/main.kujo" -- inspect --file "$ROOT/examples/hello/workcell.json" --repo "$TMP_DIR" --json | jq -e '.network_mode == "none" and (.docker_security_arguments | contains(["--read-only"]))' >/dev/null

jq '.runtime.build_context="missing-build-context"' "$ROOT/examples/hello/workcell.json" > "$TMP_DIR/missing-context.json"
git -C "$TMP_DIR" add missing-context.json
git -C "$TMP_DIR" commit -qm "add missing build context fixture"
set +e
MISSING_CONTEXT_RESULT="$($KUJO run "$ROOT/main.kujo" -- run --file "$TMP_DIR/missing-context.json" --repo "$TMP_DIR" --output "$MISSING_OUTPUT" --json 2>/dev/null)"
MISSING_CONTEXT_CODE=$?
set -e
test "$MISSING_CONTEXT_CODE" -eq 4
printf '%s' "$MISSING_CONTEXT_RESULT" | jq -e '.stage == "preparing" and .exit_code == 4 and (.error | contains("build_context does not exist"))' >/dev/null
echo "CLI smoke tests passed"
