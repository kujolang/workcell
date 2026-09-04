#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for provider in e2b vercel-sandbox daytona; do
  evidence="$TMP/$provider"
  report="$(WORKCELL_LIVE_EVIDENCE_DIR="$evidence" KUJO="$KUJO" "$ROOT/tests/live_certification.sh" "$provider" --fixture)"
  jq -e --arg provider "$provider" '
    .schema_version == "workcell-live-certification/v1" and
    .status == "passed" and .provider == $provider and .mode == "fixture" and
    .cleanup.status == "complete" and .cleanup.resources_remaining == 0 and
    .bounds.max_concurrency == 1 and .versions.runtime_commit != "" and
    .security_probes.status == "not-run"
  ' "$report" >/dev/null
  jq -e '.ok == true' "$evidence/verify.json" >/dev/null
done

set +e
blocked="$({ env -u E2B_API_KEY KUJO="$KUJO" "$ROOT/tests/live_certification.sh" e2b; } 2>&1)"
code=$?
set -e
if [ "$code" -ne 3 ] || ! printf '%s' "$blocked" | grep -q 'WORKCELL_LIVE_AUTHORIZED'; then
  echo "live certification did not fail closed without authorization" >&2
  exit 1
fi

set +e
oversize="$({ WORKCELL_LIVE_MAX_RUNTIME_SECONDS=301 KUJO="$KUJO" "$ROOT/tests/live_certification.sh" e2b --fixture; } 2>&1)"
code=$?
set -e
if [ "$code" -ne 2 ] || ! printf '%s' "$oversize" | grep -q 'between 1 and 300'; then
  echo "live certification accepted an unsafe runtime ceiling" >&2
  exit 1
fi

echo "Live certification contract passed."
