#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"

check_all() {
  "$KUJO" check "$ROOT/main.kujo"
  while IFS= read -r file; do
    "$KUJO" check "$ROOT/$file"
  done < <(cd "$ROOT" && find src -type f -name '*.kujo' | sort)
  "$KUJO" check "$ROOT/tests/workcell_test.kujo"
  "$KUJO" check "$ROOT/tests/workspace_test.kujo"
  "$KUJO" check "$ROOT/tests/performance_test.kujo"
  "$KUJO" check "$ROOT/tests/stress_test.kujo"
}

if [ "${1:-}" = "--check-only" ]; then
  check_all
  exit 0
fi

check_all
EMPTY_SECRET="" LONG_SECRET="longsecret" AUDIT_SECRET="artifact-secret" "$KUJO" run "$ROOT/tests/workcell_test.kujo"
"$KUJO" run "$ROOT/tests/workspace_test.kujo"
"$KUJO" run "$ROOT/tests/performance_test.kujo"
"$KUJO" run "$ROOT/tests/stress_test.kujo"
KUJO="$KUJO" "$ROOT/tests/path_safety.sh"
KUJO="$KUJO" "$ROOT/tests/adversarial.sh"
KUJO="$KUJO" "$ROOT/tests/dry_run.sh"
KUJO="$KUJO" "$ROOT/tests/examples.sh"
KUJO="$KUJO" "$ROOT/tests/cli_smoke.sh"
"$ROOT/tests/version_consistency.sh"
