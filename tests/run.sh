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
  "$KUJO" check "$ROOT/tests/podman_security_contract.kujo"
  "$KUJO" check "$ROOT/tests/verification_cleanup_contract.kujo"
  "$KUJO" check "$ROOT/tests/runtime_cleanup_contract.kujo"
  bash -n "$ROOT/tests/egress_deployment_contract.sh"
  bash -n "$ROOT/tests/load_integration.sh"
  bash -n "$ROOT/tests/quality.sh"
  bash -n "$ROOT/tests/verification_cleanup_contract.sh"
  bash -n "$ROOT/tests/runtime_cleanup_contract.sh"
  bash -n "$ROOT/tests/startup_failure_contract.sh"
  bash -n "$ROOT/tests/lifecycle_failure_contract.sh"
  bash -n "$ROOT/tests/clean_runtime_failure_contract.sh"
  bash -n "$ROOT/tests/markdown_links.sh"
  bash -n "$ROOT/scripts/build_release_artifacts.sh"
}

if [ "${1:-}" = "--check-only" ]; then
  check_all
  exit 0
fi

check_all
KUJO="$KUJO" "$ROOT/tests/quality.sh"
EMPTY_SECRET="" LONG_SECRET="longsecret" AUDIT_SECRET="artifact-secret" "$KUJO" run "$ROOT/tests/workcell_test.kujo"
"$KUJO" run "$ROOT/tests/workspace_test.kujo"
"$KUJO" run "$ROOT/tests/performance_test.kujo"
WORKCELL_PERF_FILES=999999999999999999999 "$KUJO" run "$ROOT/tests/performance_test.kujo" >/dev/null
"$KUJO" run "$ROOT/tests/stress_test.kujo"
KUJO="$KUJO" "$ROOT/tests/path_safety.sh"
KUJO="$KUJO" "$ROOT/tests/adversarial.sh"
KUJO="$KUJO" "$ROOT/tests/dry_run.sh"
KUJO="$KUJO" "$ROOT/tests/examples.sh"
KUJO="$KUJO" "$ROOT/tests/cli_smoke.sh"
KUJO="$KUJO" "$ROOT/tests/schema_contract.sh"
KUJO="$KUJO" "$ROOT/tests/report_contract.sh"
KUJO="$KUJO" "$ROOT/tests/podman_security_contract.sh"
KUJO="$KUJO" "$ROOT/tests/verification_cleanup_contract.sh"
KUJO="$KUJO" "$ROOT/tests/runtime_cleanup_contract.sh"
KUJO="$KUJO" "$ROOT/tests/startup_failure_contract.sh"
KUJO="$KUJO" "$ROOT/tests/lifecycle_failure_contract.sh"
KUJO="$KUJO" "$ROOT/tests/clean_runtime_failure_contract.sh"
KUJO="$KUJO" "$ROOT/tests/version_consistency.sh"
"$ROOT/tests/markdown_links.sh"
