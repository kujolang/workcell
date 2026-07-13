#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
FAKE_DIR="$ROOT/tests/fixtures/podman-security"

PATH="$FAKE_DIR:$PATH" \
  PODMAN_SECURITY_JSON='{"rootless":true,"seccompEnabled":true,"apparmorEnabled":false,"selinuxEnabled":false}' \
  EXPECTED_OK=true "$KUJO" run "$ROOT/tests/podman_security_contract.kujo" >/dev/null

if PATH="$FAKE_DIR:$PATH" \
  PODMAN_SECURITY_JSON='{"rootless":true,"seccompEnabled":false,"apparmorEnabled":false,"selinuxEnabled":false}' \
  EXPECTED_OK=true "$KUJO" run "$ROOT/tests/podman_security_contract.kujo" >/dev/null 2>&1; then
  echo "Podman security contract accepted disabled seccomp" >&2
  exit 1
fi

PATH="$FAKE_DIR:$PATH" \
  PODMAN_SECURITY_JSON='{"rootless":true,"seccompEnabled":false,"apparmorEnabled":false,"selinuxEnabled":false}' \
  EXPECTED_OK=false "$KUJO" run "$ROOT/tests/podman_security_contract.kujo" >/dev/null

echo "Podman security contract passed"
