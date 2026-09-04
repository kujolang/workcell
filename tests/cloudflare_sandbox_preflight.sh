#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

make_fake_wrangler() {
  local mode="$1" path="$2"
  cat >"$path" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >>"$TMP/calls-$mode.log"
case "\${1:-}" in
  whoami)
    if [ "$mode" = auth-failed ]; then echo 'not authenticated' >&2; exit 1; fi
    echo 'authenticated'
    ;;
  containers)
    if [ "$mode" = paid ]; then echo '[]'; exit 0; fi
    echo 'Unauthorized: You do not have access to Cloudflare Containers. Deploying containers requires the Workers Paid plan.' >&2
    exit 1
    ;;
  *) exit 2 ;;
esac
EOF
  chmod +x "$path"
}

cat >"$TMP/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
test "${1:-}" = info
EOF
chmod +x "$TMP/docker"

make_fake_wrangler free "$TMP/wrangler-free"
set +e
WRANGLER_BIN="$TMP/wrangler-free" DOCKER_BIN="$TMP/docker" "$ROOT/scripts/cloudflare-sandbox-preflight.sh" >"$TMP/free.json"
free_code=$?
set -e
test "$free_code" -eq 3
jq -e '.status == "blocked" and .authenticated == true and .containers_access == false and .workers_free_suitable_for_linux_process_workloads == false and .blocker == "workers-paid-plan" and .local_build.docker_daemon == true' "$TMP/free.json" >/dev/null
test "$(wc -l <"$TMP/calls-free.log" | tr -d ' ')" -eq 2
grep -Eq '^whoami --cwd ' "$TMP/calls-free.log"
grep -Eq '^containers list --cwd ' "$TMP/calls-free.log"

make_fake_wrangler paid "$TMP/wrangler-paid"
WRANGLER_BIN="$TMP/wrangler-paid" DOCKER_BIN="$TMP/docker" "$ROOT/scripts/cloudflare-sandbox-preflight.sh" >"$TMP/paid.json"
jq -e '.status == "eligible" and .authenticated == true and .containers_access == true and .blocker == null' "$TMP/paid.json" >/dev/null

make_fake_wrangler auth-failed "$TMP/wrangler-auth-failed"
set +e
WRANGLER_BIN="$TMP/wrangler-auth-failed" DOCKER_BIN="$TMP/docker" "$ROOT/scripts/cloudflare-sandbox-preflight.sh" >"$TMP/auth-failed.json"
auth_code=$?
set -e
test "$auth_code" -eq 3
jq -e '.status == "blocked" and .authenticated == false and .blocker == "cloudflare-auth"' "$TMP/auth-failed.json" >/dev/null

echo "Cloudflare Sandbox preflight contract passed."
