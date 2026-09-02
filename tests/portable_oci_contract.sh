#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"

if [ "${WORKCELL_LIVE_PORTABLE_OCI:-0}" != "1" ]; then
  printf 'portable OCI contract skipped (set WORKCELL_LIVE_PORTABLE_OCI=1 to enable)\n'
  exit 0
fi

if ! command -v docker >/dev/null 2>&1; then
  printf 'portable OCI contract requires docker\n' >&2
  exit 1
fi

TMP_REPO="$(mktemp -d "${TMPDIR:-/tmp}/workcell-portable-oci-repo.XXXXXX")"
OUT_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/workcell-portable-oci-output.XXXXXX")"
trap 'rm -rf "$TMP_REPO" "$OUT_ROOT"' EXIT

git -C "$TMP_REPO" init -q
cp "$ROOT/README.md" "$TMP_REPO/README.md"
git -C "$TMP_REPO" add README.md
git -C "$TMP_REPO" -c user.name=Workcell -c user.email=workcell@example.invalid commit -qm fixture

set +e
"$KUJO" run "$ROOT/main.kujo" -- run \
  --file "$ROOT/tests/fixtures/portable/workcell.json" \
  --repo "$TMP_REPO" \
  --output "$OUT_ROOT" \
  --profiles "$ROOT/tests/fixtures/portable/profiles.json" \
  --profile docker \
  --json > "$OUT_ROOT/result.json"
run_status=$?
set -e
if [ "$run_status" -ne 0 ]; then
  cat "$OUT_ROOT/result.json" >&2
  exit "$run_status"
fi

receipt="$(jq -r '.receipt_path' "$OUT_ROOT/result.json")"
run_id="$(jq -r '.run_id' "$OUT_ROOT/result.json")"
jq -e '.ok == true and .receipt.schema_version == "workcell-receipt/v2alpha1" and .receipt.backend.adapter_id == "docker" and .receipt.cleanup.status == "complete"' "$OUT_ROOT/result.json" >/dev/null
"$KUJO" run "$ROOT/main.kujo" -- verify --run "$(dirname "$receipt")" --json | jq -e '.ok == true' >/dev/null
test -z "$(docker ps -aq --filter label=dev.kujo.workcell=true --filter label=dev.kujo.workcell.run_id="$run_id")"
test -z "$(git -C "$TMP_REPO" status --porcelain --untracked-files=all)"

printf 'portable OCI contract passed\n'
