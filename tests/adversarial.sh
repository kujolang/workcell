#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

reject_definition() {
  local name="$1"
  local filter="$2"
  local definition="$TMP_ROOT/$name.json"
  jq "$filter" "$ROOT/workcell.json" > "$definition"
  set +e
  local output
  output="$($KUJO run "$ROOT/main.kujo" -- validate --file "$definition" --json 2>/dev/null)"
  local code=$?
  set -e
  test "$code" -eq 2
  printf '%s' "$output" | jq -e '.ok == false' >/dev/null
  printf 'PASS %s\n' "$name"
}

reject_definition "host-network" '.network.mode = "host"'
reject_definition "docker-socket-mount-field" '.mounts = ["/var/run/docker.sock:/var/run/docker.sock"]'
reject_definition "privileged-field" '.privileged = true'
reject_definition "artifact-traversal" '.artifacts.export = ["../escape"]'
reject_definition "absolute-artifact" '.artifacts.export = ["/tmp/escape"]'
reject_definition "image-injection" '.runtime.image = "alpine;touch"'
reject_definition "unsafe-runtime-class" '.runtime.engine_runtime = "runsc;touch"'
reject_definition "invalid-timeout" '.resources.timeout_ms = 0'
reject_definition "unbounded-memory" '.resources.memory = "128g"'
reject_definition "host-control-secret" '.environment.allow = ["DOCKER_HOST"]'
reject_definition "build-context-traversal" '.runtime.build_context = "../escape"'

inspect_output="$($KUJO run "$ROOT/main.kujo" -- inspect --file "$ROOT/workcell.json" --repo "$ROOT" --json)"
printf '%s' "$inspect_output" | jq -e '
  (.docker_args | index("--privileged") | not) and
  (.docker_args | index("docker.sock") | not) and
  (.effective_security_policy.privileged == false) and
  (.effective_security_policy.docker_socket == false) and
  (.network_mode == "none")
' >/dev/null
echo "PASS restrictive inspect policy"

if ! command -v podman >/dev/null 2>&1; then
  set +e
  podman_doctor="$($KUJO run "$ROOT/main.kujo" -- doctor --backend podman --repo "$ROOT" --json)"
  podman_doctor_code=$?
  set -e
  test "$podman_doctor_code" -eq 3
  printf '%s' "$podman_doctor" | jq -e '.ok == false and (.checks | any(.name == "Podman CLI" and .status == "blocked"))' >/dev/null
  echo "PASS missing Podman doctor diagnostics"
fi

echo "Adversarial tests passed"
