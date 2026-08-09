#!/usr/bin/env bash
set -euo pipefail

# Validate a deployment-owned network without creating, changing, or removing it.
# The operator supplies the network and two probe destinations:
# one that must be reachable and one that must be blocked.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
BACKEND="${1:-docker}"
REQUIRE_BACKEND="${REQUIRE_BACKEND:-false}"
NETWORK_MODE="${NETWORK_MODE:-custom}"
NETWORK_NAME="${NETWORK_NAME:-}"
NETWORK_INSPECT_NAME="${NETWORK_INSPECT_NAME:-$NETWORK_NAME}"
ALLOWED_URL="${ALLOWED_URL:-}"
DENIED_URL="${DENIED_URL:-}"
EGRESS_POLICY="${EGRESS_POLICY:-deny-by-default}"
EGRESS_DNS="${EGRESS_DNS:-operator-managed}"
EGRESS_PROXY="${EGRESS_PROXY:-operator-managed}"
ENFORCEMENT_PROFILE="${ENFORCEMENT_PROFILE:-corp-egress-v1}"
EVIDENCE_FILE="${EVIDENCE_FILE:-}"

usage() {
  echo "usage: $0 docker|podman" >&2
  echo "required env: NETWORK_MODE, ALLOWED_URL, DENIED_URL, ENFORCEMENT_PROFILE" >&2
  echo "custom mode also requires NETWORK_NAME" >&2
}

case "$BACKEND" in
  docker|podman) ;;
  *) usage; exit 2 ;;
esac
case "$NETWORK_MODE" in
  default) ;;
  custom)
    if [ -z "$NETWORK_NAME" ]; then usage; exit 2; fi
    ;;
  *) echo "NETWORK_MODE must be default or custom" >&2; exit 2 ;;
esac
if [ -z "$ALLOWED_URL" ] || [ -z "$DENIED_URL" ] || [ -z "$ENFORCEMENT_PROFILE" ]; then
  usage
  exit 2
fi
for probe_url in "$ALLOWED_URL" "$DENIED_URL"; do
  case "$probe_url" in
    http://*|https://*) ;;
    *) echo "probe destinations must use http:// or https://" >&2; exit 2 ;;
  esac
  case "$probe_url" in
    *://*@*) echo "probe destinations must not contain URL credentials" >&2; exit 2 ;;
  esac
done

if ! command -v "$BACKEND" >/dev/null 2>&1; then
  if [ "$REQUIRE_BACKEND" = "true" ]; then echo "$BACKEND CLI unavailable" >&2; exit 3; fi
  jq -n --arg backend "$BACKEND" '{schema_version:"workcell-egress-deployment-evidence/v1",backend:$backend,status:"skipped",reason:"backend CLI unavailable"}'
  exit 0
fi
if ! "$BACKEND" info >/dev/null 2>&1; then
  if [ "$REQUIRE_BACKEND" = "true" ]; then echo "$BACKEND engine unavailable" >&2; exit 3; fi
  jq -n --arg backend "$BACKEND" '{schema_version:"workcell-egress-deployment-evidence/v1",backend:$backend,status:"skipped",reason:"backend engine unavailable"}'
  exit 0
fi
if [ "$NETWORK_MODE" = "custom" ]; then
  if ! "$BACKEND" network inspect "$NETWORK_INSPECT_NAME" >/dev/null 2>&1; then
    echo "deployment-owned network is not reachable: $NETWORK_INSPECT_NAME" >&2
    exit 4
  fi
fi

TEMP_BASE="${TMPDIR:-/tmp}"
TMP_REPO="$(mktemp -d "$TEMP_BASE/workcell-egress-deployment-repo.XXXXXX")"
OUT_ROOT="$(mktemp -d "$TEMP_BASE/workcell-egress-deployment-output.XXXXXX")"
ROOTLESS=false
if [ "$BACKEND" = "podman" ]; then
  if [ "$(podman info --format '{{.Host.Security.Rootless}}' 2>/dev/null || printf 'false')" = "true" ]; then ROOTLESS=true; fi
elif docker info --format '{{json .SecurityOptions}}' 2>/dev/null | grep -q rootless; then
  ROOTLESS=true
fi
RUN_AS="host"
if [ "$ROOTLESS" = "true" ]; then RUN_AS="rootless"; fi
cleanup() {
  KUJO="$KUJO" "$ROOT/bin/workcell" clean --backend "$BACKEND" >/dev/null 2>&1 || true
  rm -rf "$TMP_REPO" "$OUT_ROOT"
}
trap cleanup EXIT

git -C "$TMP_REPO" init -q
git -C "$TMP_REPO" config user.email workcell@example.invalid
git -C "$TMP_REPO" config user.name Workcell
printf '# Egress deployment fixture\n' > "$TMP_REPO/README.md"
git -C "$TMP_REPO" add README.md
git -C "$TMP_REPO" commit -qm initial

if ! "$BACKEND" image inspect kujolang/workcell-base:local >/dev/null 2>&1; then
  "$BACKEND" build -q --tag kujolang/workcell-base:local "$ROOT/docker" >/dev/null
fi

NETWORK_VALUE="$NETWORK_NAME"
if [ "$NETWORK_MODE" = "default" ]; then NETWORK_VALUE=""; fi
jq \
  --arg backend "$BACKEND" \
  --arg run_as "$RUN_AS" \
  --arg mode "$NETWORK_MODE" \
  --arg network "$NETWORK_VALUE" \
  --arg allowed "$ALLOWED_URL" \
  --arg denied "$DENIED_URL" \
  --arg policy "$EGRESS_POLICY" \
  --arg dns "$EGRESS_DNS" \
  --arg proxy "$EGRESS_PROXY" \
  --arg profile "$ENFORCEMENT_PROFILE" \
  '.runtime.backend = $backend
   | .workspace.run_as = $run_as
   | .network.mode = $mode
   | .network.name = $network
   | .network.egress = {policy:$policy, dns:$dns, proxy:$proxy, enforcement_profile:$profile}
   | .environment.set = {EGRESS_ALLOWED_URL:$allowed, EGRESS_DENIED_URL:$denied}
   | .command = ["sh", "-lc", "set -eu; wget -q -T 10 -O allowed.txt \"$EGRESS_ALLOWED_URL\"; test -s allowed.txt; if wget -q -T 10 -O denied.txt \"$EGRESS_DENIED_URL\"; then echo denied destination was reachable >&2; exit 42; fi"]
   | .artifacts.export = ["allowed.txt"]' \
  "$ROOT/examples/egress-policy/workcell.json" > "$OUT_ROOT/workcell.json"

KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$OUT_ROOT/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/run" --no-pull --json > "$OUT_ROOT/result.json"
RECEIPT="$(jq -r '.receipt_path' "$OUT_ROOT/result.json")"
RUN_DIR="$(dirname "$RECEIPT")"
jq -e \
  --arg backend "$BACKEND" \
  --arg mode "$NETWORK_MODE" \
  --arg network "$NETWORK_NAME" \
  --arg policy "$EGRESS_POLICY" \
  --arg dns "$EGRESS_DNS" \
  --arg proxy "$EGRESS_PROXY" \
  --arg profile "$ENFORCEMENT_PROFILE" \
  '.ok == true
   and .receipt.runtime_backend == $backend
   and .receipt.network_policy.mode == $mode
   and (.receipt.network_policy.name // "") == $network
   and .receipt.network_policy.egress.policy == $policy
   and .receipt.network_policy.egress.dns == $dns
   and .receipt.network_policy.egress.proxy == $proxy
   and .receipt.network_policy.enforcement_profile == $profile
   and (.receipt.warnings | length) == 0' \
  "$OUT_ROOT/result.json" >/dev/null
KUJO="$KUJO" "$ROOT/bin/workcell" verify --run "$RUN_DIR" --json | jq -e '.ok == true and .manifest.schema_version == "workcell-manifest/v1"' >/dev/null
test -s "$RUN_DIR/artifacts/allowed.txt"

if command -v sha256sum >/dev/null 2>&1; then
  RECEIPT_SHA256="$(sha256sum "$RECEIPT" | awk '{print $1}')"
  MANIFEST_SHA256="$(sha256sum "$RUN_DIR/manifest.json" | awk '{print $1}')"
else
  RECEIPT_SHA256="$(shasum -a 256 "$RECEIPT" | awk '{print $1}')"
  MANIFEST_SHA256="$(shasum -a 256 "$RUN_DIR/manifest.json" | awk '{print $1}')"
fi
EVIDENCE="$(jq -n \
  --arg backend "$BACKEND" \
  --arg rootless "$ROOTLESS" \
  --arg mode "$NETWORK_MODE" \
  --arg network "$NETWORK_NAME" \
  --arg allowed "$ALLOWED_URL" \
  --arg denied "$DENIED_URL" \
  --arg policy "$EGRESS_POLICY" \
  --arg dns "$EGRESS_DNS" \
  --arg proxy "$EGRESS_PROXY" \
  --arg profile "$ENFORCEMENT_PROFILE" \
  --arg receipt "$RECEIPT_SHA256" \
  --arg manifest "$MANIFEST_SHA256" \
  '{schema_version:"workcell-egress-deployment-evidence/v1",backend:$backend,status:"passed",rootless:($rootless == "true"),network_mode:$mode,network:$network,allowed_destination:$allowed,allowed_destination_reached:true,denied_destination:$denied,denied_destination_blocked:true,network_mutation:false,egress_policy:$policy,dns_policy:$dns,proxy_policy:$proxy,enforcement_profile:$profile,receipt_sha256:$receipt,manifest_sha256:$manifest}')"
if [ -n "$EVIDENCE_FILE" ]; then
  mkdir -p "$(dirname "$EVIDENCE_FILE")"
  printf '%s\n' "$EVIDENCE" > "$EVIDENCE_FILE"
fi
printf '%s\n' "$EVIDENCE"
