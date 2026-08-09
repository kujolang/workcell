#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
BACKEND="${1:-docker}"
REQUIRE_BACKEND="${REQUIRE_BACKEND:-false}"

case "$BACKEND" in
  docker|podman) ;;
  *) echo "usage: $0 docker|podman" >&2; exit 2 ;;
esac

if ! command -v "$BACKEND" >/dev/null 2>&1 || ! "$BACKEND" info >/dev/null 2>&1; then
  if [ "$REQUIRE_BACKEND" = "true" ]; then
    echo "$BACKEND integration backend unavailable" >&2
    exit 3
  fi
  echo "SKIP $BACKEND integration tests: backend unavailable"
  exit 0
fi
TIMEOUT_BIN=""
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN="$(command -v timeout)"
fi

remove_test_container() {
  local name="$1"
  if [ -n "$TIMEOUT_BIN" ] && "$TIMEOUT_BIN" 30 "$BACKEND" rm -f "$name" >/dev/null 2>&1; then
    return 0
  fi
  if [ -z "$TIMEOUT_BIN" ]; then
    "$BACKEND" rm -f "$name" >/dev/null 2>&1
    return $?
  fi
  "$BACKEND" kill "$name" >/dev/null 2>&1 || true
  "$TIMEOUT_BIN" 30 "$BACKEND" rm -f "$name" >/dev/null 2>&1
}

TEMP_BASE="${TMPDIR:-/tmp}"
TMP_REPO="$(mktemp -d "$TEMP_BASE/workcell-docker-repo.XXXXXX")"
OUT_ROOT="$(mktemp -d "$TEMP_BASE/workcell-docker-output.XXXXXX")"
UNRELATED_NAME=""
INTERNAL_NETWORK="workcell-internal-$$"
ROOTLESS=false
if [ "$BACKEND" = "podman" ] && [ "$(podman info --format '{{.Host.Security.Rootless}}' 2>/dev/null || printf 'false')" = "true" ]; then
  ROOTLESS=true
elif [ "$BACKEND" = "docker" ] && docker info --format '{{json .SecurityOptions}}' 2>/dev/null | grep -q 'rootless'; then
  ROOTLESS=true
fi
EXAMPLES_ROOT="$ROOT/examples"
cleanup() {
  if [ -n "$UNRELATED_NAME" ]; then
    remove_test_container "$UNRELATED_NAME" || true
  fi
  "$BACKEND" network rm "$INTERNAL_NETWORK" >/dev/null 2>&1 || true
  rm -rf "$TMP_REPO" "$OUT_ROOT"
}
trap cleanup EXIT

if [ "$ROOTLESS" = "true" ]; then
  EXAMPLES_ROOT="$OUT_ROOT/examples"
  cp -R "$ROOT/examples" "$EXAMPLES_ROOT"
  while IFS= read -r -d '' definition_file; do
    jq --arg backend "$BACKEND" '.runtime.backend = $backend | .workspace.run_as = "rootless"' "$definition_file" > "$definition_file.tmp"
    mv "$definition_file.tmp" "$definition_file"
  done < <(find "$EXAMPLES_ROOT" -name workcell.json -print0)
elif [ "$BACKEND" != "docker" ]; then
  EXAMPLES_ROOT="$OUT_ROOT/examples"
  cp -R "$ROOT/examples" "$EXAMPLES_ROOT"
  while IFS= read -r -d '' definition_file; do
    jq --arg backend "$BACKEND" '.runtime.backend = $backend' "$definition_file" > "$definition_file.tmp"
    mv "$definition_file.tmp" "$definition_file"
  done < <(find "$EXAMPLES_ROOT" -name workcell.json -print0)
fi

git -C "$TMP_REPO" init -q
git -C "$TMP_REPO" config user.email workcell@example.invalid
git -C "$TMP_REPO" config user.name Workcell
printf '# Fixture\n' > "$TMP_REPO/README.md"
git -C "$TMP_REPO" add README.md
git -C "$TMP_REPO" commit -qm initial
"$BACKEND" network create --internal "$INTERNAL_NETWORK" >/dev/null

if [ "$BACKEND" = "docker" ] && docker buildx version >/dev/null 2>&1; then
  docker buildx build --load --tag kujolang/workcell-base:local "$ROOT/docker" >/dev/null
else
  "$BACKEND" build -q --tag kujolang/workcell-base:local "$ROOT/docker" >/dev/null
fi

BASE_DIGEST="$($BACKEND image inspect --format '{{index .RepoDigests 0}}' kujolang/workcell-base:local 2>/dev/null || true)"
BASE_DIGEST="$(printf '%s' "$BASE_DIGEST" | sed 's/.*@//')"
if [ -n "$BASE_DIGEST" ]; then
  jq --arg digest "$BASE_DIGEST" '.runtime.image_digest = $digest' "$EXAMPLES_ROOT/hello/workcell.json" > "$OUT_ROOT/digest.json"
  KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/digest.json" --repo "$TMP_REPO" --output "$OUT_ROOT/digest"
  jq --arg digest "sha256:$(printf '0%.0s' {1..64})" '.runtime.image_digest = $digest' "$EXAMPLES_ROOT/hello/workcell.json" > "$OUT_ROOT/digest-mismatch.json"
  set +e
  KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/digest-mismatch.json" --repo "$TMP_REPO" --output "$OUT_ROOT/digest-mismatch" --json > "$OUT_ROOT/digest-mismatch.json.result"
  DIGEST_MISMATCH_CODE=$?
  set -e
  test "$DIGEST_MISMATCH_CODE" -eq 4
  jq -e '.stage == "preparing" and (.error | contains("image_digest mismatch"))' "$OUT_ROOT/digest-mismatch.json.result" >/dev/null
fi

jq '.runtime.signature_key = "missing-workcell.pub"' "$EXAMPLES_ROOT/hello/workcell.json" > "$OUT_ROOT/signature-mismatch.json"
set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/signature-mismatch.json" --repo "$TMP_REPO" --output "$OUT_ROOT/signature-mismatch" --json > "$OUT_ROOT/signature-mismatch.json.result"
SIGNATURE_MISMATCH_CODE=$?
set -e
test "$SIGNATURE_MISMATCH_CODE" -eq 4
jq -e '.stage == "preparing" and (.error | contains("signature_key"))' "$OUT_ROOT/signature-mismatch.json.result" >/dev/null

jq --arg network "$INTERNAL_NETWORK" '.network.mode = "custom" | .network.name = $network' "$EXAMPLES_ROOT/hello/workcell.json" > "$OUT_ROOT/internal-network.json"
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/internal-network.json" --repo "$TMP_REPO" --output "$OUT_ROOT/internal-network"

jq --arg network "$INTERNAL_NETWORK" '.network.name = $network' "$EXAMPLES_ROOT/custom-network/workcell.json" > "$OUT_ROOT/custom-network-example.json"
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/custom-network-example.json" --repo "$TMP_REPO" --output "$OUT_ROOT/custom-network-example"
CUSTOM_NETWORK_RECEIPT="$(find "$OUT_ROOT/custom-network-example" -name receipt.json -print -quit)"
jq --arg network "$INTERNAL_NETWORK" -e '.network_mode == $network and .network_policy.mode == "custom" and .network_policy.egress.policy == "unmanaged" and (.warnings | any(. == "network egress is unmanaged; enforce a host firewall or transparent proxy before production use")) and .artifact_files == 1' "$CUSTOM_NETWORK_RECEIPT" >/dev/null

jq --arg network "$INTERNAL_NETWORK" '.network.name = $network' "$EXAMPLES_ROOT/egress-policy/workcell.json" > "$OUT_ROOT/egress-policy-example.json"
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/egress-policy-example.json" --repo "$TMP_REPO" --output "$OUT_ROOT/egress-policy-example"
EGRESS_POLICY_RECEIPT="$(find "$OUT_ROOT/egress-policy-example" -name receipt.json -print -quit)"
jq -e '.network_policy.mode == "custom" and .network_policy.egress.policy == "deny-by-default" and .network_policy.egress.proxy == "operator-managed" and .network_policy.enforcement_profile == "corp-egress-v1" and (.warnings | length) == 0 and .artifact_files == 1' "$EGRESS_POLICY_RECEIPT" >/dev/null

WORKCELL_GREETING="secret-example-value" KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$EXAMPLES_ROOT/secrets/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/secrets-example"
SECRETS_RECEIPT="$(find "$OUT_ROOT/secrets-example" -name receipt.json -print -quit)"
SECRETS_RUN_DIR="$(dirname "$SECRETS_RECEIPT")"
jq -e '.artifact_files == 1 and .schema_version == "workcell-receipt/v1"' "$SECRETS_RECEIPT" >/dev/null
grep -Fq '[REDACTED]' "$SECRETS_RUN_DIR/artifacts/greeting.txt"

set +e
WORKCELL_ARTIFACT_SECRET="artifact-example-secret" KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$EXAMPLES_ROOT/artifact-policy/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/artifact-policy-example" --json > "$OUT_ROOT/artifact-policy-example.json"
ARTIFACT_POLICY_CODE=$?
set -e
test "$ARTIFACT_POLICY_CODE" -eq 8
jq -e '.stage == "artifact-failed" and (.error | contains("secret"))' "$OUT_ROOT/artifact-policy-example.json" >/dev/null

set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$EXAMPLES_ROOT/provenance/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/provenance-example" --json > "$OUT_ROOT/provenance-example.json"
PROVENANCE_EXAMPLE_CODE=$?
set -e
test "$PROVENANCE_EXAMPLE_CODE" -eq 4
jq -e '.stage == "preparing" and (.error | contains("image_digest"))' "$OUT_ROOT/provenance-example.json" >/dev/null

set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$EXAMPLES_ROOT/signature/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/signature-example" --json > "$OUT_ROOT/signature-example.json"
SIGNATURE_EXAMPLE_CODE=$?
set -e
test "$SIGNATURE_EXAMPLE_CODE" -eq 4
jq -e '.stage == "preparing" and (.error | contains("cosign") or contains("signature_key"))' "$OUT_ROOT/signature-example.json" >/dev/null

jq '.trust_profile = "native-guarded"' "$EXAMPLES_ROOT/hello/workcell.json" > "$OUT_ROOT/native-guarded.json"
set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/native-guarded.json" --repo "$TMP_REPO" --output "$OUT_ROOT/native-guarded" --json > "$OUT_ROOT/native-guarded.json.result"
NATIVE_GUARDED_CODE=$?
set -e
if [ "$ROOTLESS" = "true" ]; then
  test "$NATIVE_GUARDED_CODE" -eq 0
else
  test "$NATIVE_GUARDED_CODE" -eq 4
  jq -e '.stage == "preparing" and (.error | contains("native-guarded"))' "$OUT_ROOT/native-guarded.json.result" >/dev/null
fi

cp -R "$ROOT/docker" "$TMP_REPO/build-context"
git -C "$TMP_REPO" add build-context
git -C "$TMP_REPO" commit -qm "add runtime build context fixture"
jq '.runtime.image = "kujolang/workcell-runtime-build:integration" | .runtime.build_context = "build-context" | .artifacts.export = []' "$EXAMPLES_ROOT/hello/workcell.json" > "$OUT_ROOT/runtime-build.json"
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/runtime-build.json" --repo "$TMP_REPO" --output "$OUT_ROOT/runtime-build" --no-pull --rebuild
test "$($BACKEND image inspect --format '{{index .Config.Labels "dev.kujo.workcell"}}' kujolang/workcell-runtime-build:integration)" = "true"
test "$($BACKEND image inspect --format '{{index .Config.Labels "dev.kujo.workcell.project"}}' kujolang/workcell-runtime-build:integration)" = "hello-workcell"
test "$($BACKEND image inspect --format '{{index .Config.Labels "dev.kujo.workcell.version"}}' kujolang/workcell-runtime-build:integration)" = "$(tr -d '[:space:]' < "$ROOT/VERSION")"

KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$EXAMPLES_ROOT/hello/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/hello"
HELLO_RECEIPT="$(find "$OUT_ROOT/hello" -name receipt.json -print -quit)"
test -f "$HELLO_RECEIPT"
test -f "$OUT_ROOT/hello"/*/artifacts/hello.txt
HELLO_RUN_DIR="$(dirname "$HELLO_RECEIPT")"
test -f "$HELLO_RUN_DIR/stdout.log"
test -f "$HELLO_RUN_DIR/stderr.log"
jq -e '.container_image_id | startswith("sha256:")' "$HELLO_RECEIPT" >/dev/null
jq -e --arg version "$(tr -d '[:space:]' < "$ROOT/VERSION")" '.schema_version == "workcell-receipt/v1" and .workcell_version == $version and .definition_version == 1' "$HELLO_RECEIPT" >/dev/null
jq -e '.container_image_platform != "" and (.container_image_digest_source == "image_id" or .container_image_digest_source == "repo_digest")' "$HELLO_RECEIPT" >/dev/null
jq -e '.cancelled == false' "$HELLO_RECEIPT" >/dev/null
jq -e '.manifest_path == "manifest.json" and .manifest_schema_version == "workcell-manifest/v1"' "$HELLO_RECEIPT" >/dev/null
KUJO="$KUJO" "$ROOT/bin/workcell" verify --run "$HELLO_RUN_DIR" --json | jq -e '.ok == true and .manifest.files >= 4' >/dev/null
printf 'tampered\n' >> "$HELLO_RUN_DIR/stdout.log"
set +e
VERIFY_TAMPERED="$(KUJO="$KUJO" "$ROOT/bin/workcell" verify --run "$HELLO_RUN_DIR" --json 2>/dev/null)"
VERIFY_TAMPERED_CODE=$?
set -e
test "$VERIFY_TAMPERED_CODE" -eq 8
printf '%s' "$VERIFY_TAMPERED" | jq -e '.ok == false and (.manifest.error | contains("mismatch"))' >/dev/null
git -C "$TMP_REPO" diff --quiet

KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$EXAMPLES_ROOT/verification/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/verification"
VERIFICATION_RECEIPT="$(find "$OUT_ROOT/verification" -name receipt.json -print -quit)"
jq -e '.verification.execution_succeeded == true and .verification.verification_succeeded == true and .verification.checks[0].status == "passed" and .artifact_files == 1' "$VERIFICATION_RECEIPT" >/dev/null

KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$EXAMPLES_ROOT/controlled-edit/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/edit"
PATCH="$(find "$OUT_ROOT/edit" -name changes.patch -print -quit)"
grep -q "Edited inside a disposable Workcell" "$PATCH"
CHANGE_REPORT="$(find "$OUT_ROOT/edit" -name changes.json -print -quit)"
jq -e '.files[] | select(.path == "README.md" and .status == "modified")' "$CHANGE_REPORT" >/dev/null
git -C "$TMP_REPO" diff --quiet

set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$EXAMPLES_ROOT/failure/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/failure"
FAILURE_CODE=$?
set -e
test "$FAILURE_CODE" -eq 7
FAILURE_RECEIPT="$(find "$OUT_ROOT/failure" -name receipt.json -print -quit)"
FAILED_WORKSPACE="$(jq -r '.workspace_path' "$FAILURE_RECEIPT")"
test -d "$FAILED_WORKSPACE"
test -f "$FAILED_WORKSPACE.owner"

jq '.command = ["sh", "-lc", "exit 125"] | .cleanup.keep_failed = false' "$EXAMPLES_ROOT/hello/workcell.json" > "$OUT_ROOT/exit-125.json"
set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/exit-125.json" --repo "$TMP_REPO" --output "$OUT_ROOT/exit-125" --json > "$OUT_ROOT/exit-125.json.result"
EXIT_125_CODE=$?
set -e
test "$EXIT_125_CODE" -eq 7
jq -e '.stage == "workload-failed" and .exit_code == 125' "$OUT_ROOT/exit-125.json.result" >/dev/null

set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$EXAMPLES_ROOT/hello/workcell.json" --repo "$TMP_REPO" --output "/var/tmp/workcell-outside-$$" --json > "$OUT_ROOT/outside-output.json.result"
OUTSIDE_OUTPUT_CODE=$?
set -e
test "$OUTSIDE_OUTPUT_CODE" -eq 3
jq -e '.stage == "preparing" and (.error | contains("absolute output paths"))' "$OUT_ROOT/outside-output.json.result" >/dev/null

ln -s /tmp "$OUT_ROOT/output-symlink"
set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$EXAMPLES_ROOT/hello/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/output-symlink"
SYMLINK_OUTPUT_CODE=$?
set -e
test "$SYMLINK_OUTPUT_CODE" -eq 3

SYMLINK_REPO="$(mktemp -d "$TEMP_BASE/workcell-docker-symlink.XXXXXX")"
git -C "$SYMLINK_REPO" init -q
git -C "$SYMLINK_REPO" config user.email workcell@example.invalid
git -C "$SYMLINK_REPO" config user.name Workcell
ln -s /tmp "$SYMLINK_REPO/escape-link"
git -C "$SYMLINK_REPO" add escape-link
git -C "$SYMLINK_REPO" commit -qm symlink-fixture
set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$EXAMPLES_ROOT/hello/workcell.json" --repo "$SYMLINK_REPO" --output "$OUT_ROOT/symlink-workspace"
SYMLINK_WORKSPACE_CODE=$?
set -e
test "$SYMLINK_WORKSPACE_CODE" -eq 3
rm -rf "$SYMLINK_REPO"

set +e
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$EXAMPLES_ROOT/timeout/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/timeout"
TIMEOUT_CODE=$?
set -e
test "$TIMEOUT_CODE" -eq 6

UNRELATED_NAME="workcell-unrelated-$$"
"$BACKEND" run -d --name "$UNRELATED_NAME" kujolang/workcell-base:local sh -c "sleep 30" >/dev/null
KUJO="$KUJO" "$ROOT/bin/workcell" clean --backend "$BACKEND" >/dev/null
test -n "$($BACKEND ps -aq --filter "name=^/${UNRELATED_NAME}$")"
remove_test_container "$UNRELATED_NAME"
test -z "$($BACKEND ps -aq --filter label=dev.kujo.workcell=true)"
ACTIVE_NAME="workcell-active-$$"
"$BACKEND" run -d --name "$ACTIVE_NAME" --label dev.kujo.workcell=true kujolang/workcell-base:local sh -c "sleep 30" >/dev/null
KUJO="$KUJO" "$ROOT/bin/workcell" clean --backend "$BACKEND" --json | jq -e --arg name "$ACTIVE_NAME" '.runtime.preserved_active | any(.[]; contains($name))' >/dev/null
KUJO="$KUJO" "$ROOT/bin/workcell" clean --backend "$BACKEND" --dry-run --json | jq -e --arg name "$ACTIVE_NAME" '.runtime.container_details | any(.[]; .name == $name and (.id | length) > 0)' >/dev/null
test -n "$($BACKEND ps -q --filter "name=^/${ACTIVE_NAME}$")"
remove_test_container "$ACTIVE_NAME"
test -z "$($BACKEND ps -aq --filter label=dev.kujo.workcell=true)"
KUJO="$KUJO" "$ROOT/bin/workcell" clean --backend "$BACKEND" --dry-run --json | jq --arg backend "$BACKEND" -e '.dry_run == true and .runtime_backend == $backend and (.runtime == .docker or .runtime == .podman) and .actions.images == "preserve"' >/dev/null
KUJO="$KUJO" "$ROOT/bin/workcell" clean --backend "$BACKEND" >/dev/null
test ! -e "$FAILED_WORKSPACE"
test ! -e "$FAILED_WORKSPACE.owner"
echo "$BACKEND integration tests passed"
