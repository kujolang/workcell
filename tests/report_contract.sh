#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

for name in policy-artifact-verification workspace-change-report performance stress-limits; do
  printf 'PASS fixture\nPassed: 2\nFailed: 0\n' > "$TMP_DIR/$name.log"
  printf '0\n' > "$TMP_DIR/$name.exit"
  printf '125\n' > "$TMP_DIR/$name.elapsed_ms"
done

"$KUJO" run "$ROOT/src/report/report.kujo" -- --dir "$TMP_DIR" | jq -e '.schema_version == "workcell-report/v1" and .ok == true and .totals.passed == 8 and .totals.failed == 0 and .totals.elapsed_ms == 500 and .deployment_gates.docker_integration == "skipped"' >/dev/null
echo "Report contract passed"
