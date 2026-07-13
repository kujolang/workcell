#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
REPORT_DIR="$(mktemp -d)"
trap 'rm -rf "$REPORT_DIR"' EXIT

run_suite() {
  local name="$1"
  local script="$2"
  local started ended code
  started="$(date +%s)"
  set +e
  EMPTY_SECRET="" LONG_SECRET="longsecret" AUDIT_SECRET="artifact-secret" "$KUJO" run "$script" > "$REPORT_DIR/$name.log" 2>&1
  code=$?
  set -e
  ended="$(date +%s)"
  printf '%s\n' "$code" > "$REPORT_DIR/$name.exit"
  printf '%s\n' "$(((ended - started) * 1000))" > "$REPORT_DIR/$name.elapsed_ms"
}

cd "$ROOT"
run_suite policy-artifact-verification "$ROOT/tests/workcell_test.kujo"
run_suite workspace-change-report "$ROOT/tests/workspace_test.kujo"
run_suite performance "$ROOT/tests/performance_test.kujo"
run_suite stress-limits "$ROOT/tests/stress_test.kujo"

"$KUJO" run "$ROOT/src/report/report.kujo" -- --dir "$REPORT_DIR"
