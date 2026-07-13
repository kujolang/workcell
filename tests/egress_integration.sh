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
  if [ "$REQUIRE_BACKEND" = "true" ]; then echo "$BACKEND CLI unavailable" >&2; exit 3; fi
  jq -n --arg backend "$BACKEND" '{schema_version:"workcell-egress-evidence/v1",backend:$backend,status:"skipped",reason:"backend CLI unavailable"}'
  exit 0
fi
if ! "$BACKEND" info >/dev/null 2>&1; then
  if [ "$REQUIRE_BACKEND" = "true" ]; then echo "$BACKEND engine unavailable" >&2; exit 3; fi
  jq -n --arg backend "$BACKEND" '{schema_version:"workcell-egress-evidence/v1",backend:$backend,status:"skipped",reason:"backend engine unavailable"}'
  exit 0
fi

TMP_REPO="$(mktemp -d)"
OUT_ROOT="$(mktemp -d)"
SERVER_ROOT="$(mktemp -d)"
NETWORK="workcell-egress-$$"
SERVICE="workcell-egress-fixture-$$"
ROOTLESS=false
if [ "$BACKEND" = "podman" ]; then
  if [ "$(podman info --format '{{.Host.Security.Rootless}}' 2>/dev/null || printf 'false')" = "true" ]; then ROOTLESS=true; fi
elif docker info --format '{{json .SecurityOptions}}' 2>/dev/null | grep -q rootless; then
  ROOTLESS=true
fi
RUN_AS="host"
if [ "$ROOTLESS" = "true" ]; then RUN_AS="rootless"; fi
cleanup() {
  "$BACKEND" rm -f "$SERVICE" >/dev/null 2>&1 || true
  "$BACKEND" network rm "$NETWORK" >/dev/null 2>&1 || true
  KUJO="$KUJO" "$ROOT/bin/workcell" clean --backend "$BACKEND" >/dev/null 2>&1 || true
  rm -rf "$TMP_REPO" "$OUT_ROOT" "$SERVER_ROOT"
}
trap cleanup EXIT

git -C "$TMP_REPO" init -q
git -C "$TMP_REPO" config user.email workcell@example.invalid
git -C "$TMP_REPO" config user.name Workcell
printf '# Egress fixture\n' > "$TMP_REPO/README.md"
git -C "$TMP_REPO" add README.md
git -C "$TMP_REPO" commit -qm initial
printf 'allowed\n' > "$SERVER_ROOT/allowed.txt"

if ! "$BACKEND" image inspect kujolang/workcell-base:local >/dev/null 2>&1; then
  "$BACKEND" build -q --tag kujolang/workcell-base:local "$ROOT/docker" >/dev/null
fi
"$BACKEND" network create --internal "$NETWORK" >/dev/null
"$BACKEND" run -d --name "$SERVICE" --network "$NETWORK" --network-alias egress-fixture \
  --volume "$SERVER_ROOT:/srv:ro" kujolang/workcell-base:local \
  sh -lc 'while true; do printf "HTTP/1.1 200 OK\\r\\nContent-Length: 8\\r\\nConnection: close\\r\\n\\r\\nallowed\\n" | nc -l -p 8080; done' >/dev/null

jq --arg backend "$BACKEND" --arg run_as "$RUN_AS" --arg network "$NETWORK" '.runtime.backend = $backend | .workspace.run_as = $run_as | .network.name = $network | .command = ["sh", "-lc", "set -eu; wget -q -O egress.txt http://egress-fixture:8080/allowed.txt; if wget -q -T 3 -O external.txt http://example.com; then echo external destination was reachable >&2; exit 42; fi; test \"$(cat egress.txt)\" = allowed"]' \
  "$ROOT/examples/egress-policy/workcell.json" > "$OUT_ROOT/workcell.json"
KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/run" --no-pull --json > "$OUT_ROOT/result.json"

RECEIPT="$(jq -r '.receipt_path' "$OUT_ROOT/result.json")"
RUN_DIR="$(dirname "$RECEIPT")"
jq --arg backend "$BACKEND" -e '.ok == true and .receipt.runtime_backend == $backend and .receipt.network_policy.mode == "custom" and .receipt.network_policy.egress.policy == "deny-by-default" and .receipt.network_policy.egress.dns == "operator-managed" and .receipt.network_policy.egress.proxy == "operator-managed" and .receipt.network_policy.enforcement_profile == "corp-egress-v1" and (.receipt.warnings | length) == 0' "$OUT_ROOT/result.json" >/dev/null
KUJO="$KUJO" "$ROOT/bin/workcell" verify --run "$RUN_DIR" --json | jq -e '.ok == true and .manifest.schema_version == "workcell-manifest/v1"' >/dev/null
test "$(cat "$RUN_DIR/artifacts/egress.txt")" = "allowed"

if command -v sha256sum >/dev/null 2>&1; then
  RECEIPT_SHA256="$(sha256sum "$RECEIPT" | awk '{print $1}')"
  MANIFEST_SHA256="$(sha256sum "$RUN_DIR/manifest.json" | awk '{print $1}')"
else
  RECEIPT_SHA256="$(shasum -a 256 "$RECEIPT" | awk '{print $1}')"
  MANIFEST_SHA256="$(shasum -a 256 "$RUN_DIR/manifest.json" | awk '{print $1}')"
fi
EVIDENCE="$(jq -n --arg backend "$BACKEND" --arg rootless "$ROOTLESS" --arg network "$NETWORK" --arg receipt "$RECEIPT_SHA256" --arg manifest "$MANIFEST_SHA256" '{schema_version:"workcell-egress-evidence/v1",backend:$backend,status:"passed",rootless:($rootless == "true"),network_mode:"custom",network:$network,allowed_destination:"egress-fixture:8080",allowed_destination_reached:true,denied_destination:"http://example.com",denied_destination_blocked:true,enforcement_profile:"corp-egress-v1",receipt_sha256:$receipt,manifest_sha256:$manifest}')"
if [ -n "$EVIDENCE_FILE" ]; then
  mkdir -p "$(dirname "$EVIDENCE_FILE")"
  printf '%s\n' "$EVIDENCE" > "$EVIDENCE_FILE"
fi
printf '%s\n' "$EVIDENCE"
