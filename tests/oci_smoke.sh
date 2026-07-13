#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
BACKEND="${1:-docker}"
REQUIRE_BACKEND="${REQUIRE_BACKEND:-false}"
EVIDENCE_FILE="${EVIDENCE_FILE:-}"

case "$BACKEND" in
  docker|podman) ;;
  *) echo "usage: $0 docker|podman" >&2; exit 2 ;;
esac

if ! command -v "$BACKEND" >/dev/null 2>&1; then
  if [ "$REQUIRE_BACKEND" = "true" ]; then echo "OCI backend unavailable: $BACKEND" >&2; exit 3; fi
  jq -n --arg backend "$BACKEND" '{schema_version:"workcell-oci-evidence/v1",backend:$backend,status:"skipped",reason:"backend CLI unavailable"}'
  exit 0
fi
if ! "$BACKEND" info >/dev/null 2>&1; then
  if [ "$REQUIRE_BACKEND" = "true" ]; then echo "OCI backend is not reachable: $BACKEND" >&2; exit 3; fi
  jq -n --arg backend "$BACKEND" '{schema_version:"workcell-oci-evidence/v1",backend:$backend,status:"skipped",reason:"backend engine unavailable"}'
  exit 0
fi

TMP_REPO="$(mktemp -d)"
OUT_ROOT="$(mktemp -d)"
IMAGE="kujolang/workcell-oci-$BACKEND:local"
hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}
cleanup() {
  KUJO="$KUJO" "$ROOT/bin/workcell" clean --backend "$BACKEND" >/dev/null 2>&1 || true
  "$BACKEND" rmi -f "$IMAGE" >/dev/null 2>&1 || true
  rm -rf "$TMP_REPO" "$OUT_ROOT"
}
trap cleanup EXIT

git -C "$TMP_REPO" init -q
git -C "$TMP_REPO" config user.email workcell@example.invalid
git -C "$TMP_REPO" config user.name Workcell
printf '# OCI fixture\n' > "$TMP_REPO/README.md"
git -C "$TMP_REPO" add README.md
git -C "$TMP_REPO" commit -qm initial

"$BACKEND" build --tag "$IMAGE" "$ROOT/docker" >/dev/null 2>&1
ROOTLESS="unknown"
if [ "$BACKEND" = "podman" ]; then
  ROOTLESS="$(podman info --format '{{.Host.Security.Rootless}}' 2>/dev/null || printf 'unknown')"
else
  SECURITY_OPTIONS="$(docker info --format '{{json .SecurityOptions}}' 2>/dev/null || printf '')"
  if printf '%s' "$SECURITY_OPTIONS" | grep -q rootless; then ROOTLESS=true; else ROOTLESS=false; fi
fi
if [ "$ROOTLESS" = "true" ]; then
  jq --arg backend "$BACKEND" --arg image "$IMAGE" '.runtime.backend = $backend | .runtime.image = $image' "$ROOT/examples/hello/workcell.json" > "$OUT_ROOT/rootful-identity.json"
  set +e
  KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/rootful-identity.json" --repo "$TMP_REPO" --output "$OUT_ROOT/rootful-identity" --no-pull --json > "$OUT_ROOT/rootful-identity.result"
  IDENTITY_CODE=$?
  set -e
  test "$IDENTITY_CODE" -eq 4
  jq -e '.stage == "preparing" and (.error | contains("requires workspace.run_as rootless"))' "$OUT_ROOT/rootful-identity.result" >/dev/null
  jq --arg backend "$BACKEND" --arg image "$IMAGE" '.runtime.backend = $backend | .runtime.image = $image | .workspace.run_as = "rootless"' "$ROOT/examples/hello/workcell.json" > "$OUT_ROOT/workcell.json"
else
  jq --arg backend "$BACKEND" --arg image "$IMAGE" '.runtime.backend = $backend | .runtime.image = $image' "$ROOT/examples/hello/workcell.json" > "$OUT_ROOT/workcell.json"
fi
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/run" --no-pull --json > "$OUT_ROOT/result.json"
RECEIPT="$(jq -r '.receipt_path' "$OUT_ROOT/result.json")"
RUN_DIR="$(dirname "$RECEIPT")"
jq -e --arg backend "$BACKEND" '.ok == true and .receipt.runtime_backend == $backend and .receipt.schema_version == "workcell-receipt/v1" and (.run_id | type) == "string"' "$OUT_ROOT/result.json" >/dev/null
KUJO="$KUJO" "$ROOT/bin/workcell" verify --run "$RUN_DIR" --json | jq -e '.ok == true and .manifest.schema_version == "workcell-manifest/v1"' >/dev/null

RUN_ID="$(jq -r '.run_id' "$OUT_ROOT/result.json")"
RECEIPT_SHA256="$(hash_file "$RECEIPT")"
MANIFEST_SHA256="$(hash_file "$RUN_DIR/manifest.json")"
EVIDENCE="$(jq -n --arg backend "$BACKEND" --arg rootless "$ROOTLESS" --arg run "$RUN_ID" --arg run_as "$(jq -r '.workspace.run_as // "host"' "$OUT_ROOT/workcell.json")" --arg receipt_sha256 "$RECEIPT_SHA256" --arg manifest_sha256 "$MANIFEST_SHA256" '{schema_version:"workcell-oci-evidence/v1",backend:$backend,status:"passed",rootless:($rootless == "true"),workspace_run_as:$run_as,run_id:$run,receipt_sha256:$receipt_sha256,manifest_sha256:$manifest_sha256}')"
if [ -n "$EVIDENCE_FILE" ]; then
  mkdir -p "$(dirname "$EVIDENCE_FILE")"
  printf '%s\n' "$EVIDENCE" > "$EVIDENCE_FILE"
fi
printf '%s\n' "$EVIDENCE"
