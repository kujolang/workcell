#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

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

"$KUJO" run "$ROOT/main.kujo" -- inspect --file "$ROOT/examples/hello/workcell.json" --repo "$TMP_DIR" --json | jq -e '.network_mode == "none" and (.docker_security_arguments | contains(["--read-only"]))' >/dev/null
echo "CLI smoke tests passed"
