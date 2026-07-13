#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"

chmod +x "$ROOT/tests/fixtures/runtime-cleanup/docker"
PATH="$ROOT/tests/fixtures/runtime-cleanup:$PATH" \
  "$KUJO" run "$ROOT/tests/runtime_cleanup_contract.kujo"

echo "runtime cleanup integration passed"
