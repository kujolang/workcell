#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"

for definition in "$ROOT"/examples/*/workcell.json; do
  "$KUJO" run "$ROOT/main.kujo" -- validate --file "$definition" --json >/dev/null
done

"$KUJO" run "$ROOT/main.kujo" -- validate --file "$ROOT/examples/provenance/workcell.json" --json | jq -e '.ok == true' >/dev/null

echo "Example definition validation passed"
