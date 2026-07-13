#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
export KUJO
TMP_DIR="$(mktemp -d)"
MISSING_OUTPUT="$(mktemp -d)"
PODMAN_DEFINITION="$(mktemp)"
trap 'rm -rf "$TMP_DIR" "$MISSING_OUTPUT" "$PODMAN_DEFINITION"' EXIT

"$KUJO" run "$ROOT/main.kujo" -- init --file "$TMP_DIR/workcell.json"
test -f "$TMP_DIR/workcell.json"
"$KUJO" run "$ROOT/main.kujo" -- validate --schema | jq -e '.schema_version == "workcell-definition/v1" and (.fields | has("verification"))' >/dev/null
"$KUJO" run "$ROOT/main.kujo" -- help --json | jq -e '.schema_version == "workcell-cli/v1" and (.exit_codes["8"] | contains("verification"))' >/dev/null

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
"$KUJO" run "$ROOT/main.kujo" -- validate --file "$ROOT/workcell.json" | grep -Fq 'Backend: docker'
jq '.runtime.backend = "podman"' "$ROOT/workcell.json" > "$PODMAN_DEFINITION"
"$KUJO" run "$ROOT/main.kujo" -- validate --file "$PODMAN_DEFINITION" | grep -Fq 'Backend: podman'
set +e
DOCTOR_RESULT=$("$KUJO" run "$ROOT/main.kujo" -- doctor --repo "$TMP_DIR" --json)
DOCTOR_CODE=$?
set -e
printf '%s' "$DOCTOR_RESULT" | jq -e '([.checks[] | select(.status == "blocked" and .name != "Docker daemon" and .name != "Docker security profiles")] | length) == 0 and ([.checks[] | select(.name == "Host platform" and .status == "passed")] | length) == 1' >/dev/null
test "$DOCTOR_CODE" -eq 0 || test "$DOCTOR_CODE" -eq 3

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
