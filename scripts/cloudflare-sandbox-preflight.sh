#!/usr/bin/env bash
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "cloudflare preflight requires jq" >&2
  exit 2
fi

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

run_wrangler() {
  if [ -n "${WRANGLER_BIN:-}" ]; then
    "$WRANGLER_BIN" "$@"
  elif command -v wrangler >/dev/null 2>&1; then
    wrangler "$@"
  elif command -v npx >/dev/null 2>&1; then
    npx --yes wrangler@latest "$@"
  else
    return 127
  fi
}

run_docker() {
  if [ -n "${DOCKER_BIN:-}" ]; then
    "$DOCKER_BIN" "$@"
  else
    docker "$@"
  fi
}

authenticated=false
containers_access=false
docker_cli=false
docker_daemon=false
status="blocked"
blocker="cloudflare-auth"
next_action="Authenticate Wrangler, then rerun scripts/cloudflare-sandbox-preflight.sh."

if run_wrangler whoami --cwd "$scratch" >"$scratch/whoami.log" 2>&1; then
  authenticated=true
  if run_wrangler containers list --cwd "$scratch" >"$scratch/containers.log" 2>&1; then
    containers_access=true
    status="eligible"
    blocker=""
    next_action="Complete the architecture gate before scaffolding the operator bridge."
  elif grep -Eq "requires the Workers Paid plan|do not have access to Cloudflare Containers" "$scratch/containers.log"; then
    blocker="workers-paid-plan"
    next_action="Upgrade to Workers Paid, then rerun scripts/cloudflare-sandbox-preflight.sh."
  else
    blocker="containers-entitlement-or-api"
    next_action="Resolve the Containers entitlement or API error, then rerun scripts/cloudflare-sandbox-preflight.sh."
  fi
fi

if [ -n "${DOCKER_BIN:-}" ] || command -v docker >/dev/null 2>&1; then
  docker_cli=true
  if run_docker info >/dev/null 2>&1; then
    docker_daemon=true
  fi
fi

jq -n \
  --arg status "$status" \
  --arg blocker "$blocker" \
  --arg next_action "$next_action" \
  --argjson authenticated "$authenticated" \
  --argjson containers_access "$containers_access" \
  --argjson docker_cli "$docker_cli" \
  --argjson docker_daemon "$docker_daemon" \
  '{
    schema_version:"workcell-cloudflare-sandbox-preflight/v1",
    status:$status,
    authenticated:$authenticated,
    workers_free_suitable_for_linux_process_workloads:false,
    containers_access:$containers_access,
    local_build:{docker_cli:$docker_cli,docker_daemon:$docker_daemon},
    blocker:(if $blocker == "" then null else $blocker end),
    next_action:$next_action
  }'

if [ "$status" != "eligible" ]; then
  exit 3
fi
