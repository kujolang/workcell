#!/usr/bin/env bash
set -euo pipefail

# Exercise concurrent successful runs and prove run-scoped cleanup. This test
# intentionally uses one clean source repository and one shared output root.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
BACKEND="${1:-docker}"
REQUIRE_BACKEND="${REQUIRE_BACKEND:-false}"
RUN_COUNT="${WORKCELL_LOAD_RUNS:-4}"
EVIDENCE_FILE="${EVIDENCE_FILE:-}"

case "$BACKEND" in
  docker|podman) ;;
  *) echo "usage: $0 docker|podman" >&2; exit 2 ;;
esac
case "$RUN_COUNT" in
  ''|*[!0-9]*) echo "WORKCELL_LOAD_RUNS must be an integer from 2 through 16" >&2; exit 2 ;;
esac
if [ "$RUN_COUNT" -lt 2 ] || [ "$RUN_COUNT" -gt 16 ]; then
  echo "WORKCELL_LOAD_RUNS must be an integer from 2 through 16" >&2
  exit 2
fi

if ! command -v "$BACKEND" >/dev/null 2>&1; then
  if [ "$REQUIRE_BACKEND" = "true" ]; then echo "$BACKEND CLI unavailable" >&2; exit 3; fi
  jq -n --arg backend "$BACKEND" '{schema_version:"workcell-load-evidence/v1",backend:$backend,status:"skipped",reason:"backend CLI unavailable"}'
  exit 0
fi
if ! "$BACKEND" info >/dev/null 2>&1; then
  if [ "$REQUIRE_BACKEND" = "true" ]; then echo "$BACKEND engine unavailable" >&2; exit 3; fi
  jq -n --arg backend "$BACKEND" '{schema_version:"workcell-load-evidence/v1",backend:$backend,status:"skipped",reason:"backend engine unavailable"}'
  exit 0
fi

TMP_REPO="$(mktemp -d)"
OUT_ROOT="$(mktemp -d)"
STARTED="$(date +%s)"
PIDS=()
cleanup() {
  local pid
  for pid in "${PIDS[@]:-}"; do
    kill "$pid" >/dev/null 2>&1 || true
  done
  KUJO="$KUJO" "$ROOT/bin/workcell" clean --backend "$BACKEND" >/dev/null 2>&1 || true
  rm -rf "$TMP_REPO" "$OUT_ROOT"
}
trap cleanup EXIT

git -C "$TMP_REPO" init -q
git -C "$TMP_REPO" config user.email workcell@example.invalid
git -C "$TMP_REPO" config user.name Workcell
printf '# Concurrent Workcell fixture\n' > "$TMP_REPO/README.md"
git -C "$TMP_REPO" add README.md
git -C "$TMP_REPO" commit -qm initial

if ! "$BACKEND" image inspect kujolang/workcell-base:local >/dev/null 2>&1; then
  "$BACKEND" build -q --tag kujolang/workcell-base:local "$ROOT/docker" >/dev/null
fi

mkdir -p "$OUT_ROOT/results"
ROOTLESS=false
if [ "$BACKEND" = "podman" ]; then
  if [ "$(podman info --format '{{.Host.Security.Rootless}}' 2>/dev/null || printf 'false')" = "true" ]; then ROOTLESS=true; fi
elif docker info --format '{{json .SecurityOptions}}' 2>/dev/null | grep -q rootless; then
  ROOTLESS=true
fi
RUN_AS="host"
if [ "$ROOTLESS" = "true" ]; then RUN_AS="rootless"; fi

mutating_definition="$OUT_ROOT/definition.json"
jq --arg backend "$BACKEND" --arg run_as "$RUN_AS" \
  '.runtime.backend = $backend
   | .runtime.image = "kujolang/workcell-base:local"
   | .workspace.run_as = $run_as
   | .command = ["sh", "-lc", "printf \"%s\\n\" \"$WORKCELL_LOAD_MARKER\" > load.txt; sleep 1"]
   | .environment.set = {}
   | .artifacts.export = ["load.txt"]
   | .resources.timeout_ms = 30000
   | .cleanup.keep_failed = false' \
  "$ROOT/examples/hello/workcell.json" > "$mutating_definition"

for index in $(seq 1 "$RUN_COUNT"); do
  marker="workcell-load-$index"
  definition="$OUT_ROOT/definition-$index.json"
  result="$OUT_ROOT/results/result-$index.json"
  jq --arg marker "$marker" '.environment.set = {WORKCELL_LOAD_MARKER:$marker}' "$mutating_definition" > "$definition"
  (
    set +e
    KUJO="$KUJO" "$ROOT/bin/workcell" run --file "$definition" --repo "$TMP_REPO" --output "$OUT_ROOT/runs" --no-pull --json > "$result"
    printf '%s\n' "$?" > "$OUT_ROOT/results/status-$index"
  ) &
  PIDS+=("$!")
done

for pid in "${PIDS[@]}"; do
  wait "$pid"
done
PIDS=()

RUN_IDS_FILE="$OUT_ROOT/results/run-ids"
: > "$RUN_IDS_FILE"
for index in $(seq 1 "$RUN_COUNT"); do
  result="$OUT_ROOT/results/result-$index.json"
  test "$(cat "$OUT_ROOT/results/status-$index")" -eq 0
  jq -e --arg backend "$BACKEND" '.ok == true and .receipt.runtime_backend == $backend and (.run_id | type) == "string"' "$result" >/dev/null
  receipt="$(jq -r '.receipt_path' "$result")"
  run_dir="$(dirname "$receipt")"
  run_id="$(jq -r '.run_id' "$result")"
  printf '%s\n' "$run_id" >> "$RUN_IDS_FILE"
  test -f "$receipt"
  test -s "$run_dir/artifacts/load.txt"
  test "$(cat "$run_dir/artifacts/load.txt")" = "workcell-load-$index"
  KUJO="$KUJO" "$ROOT/bin/workcell" verify --run "$run_dir" --json | jq -e '.ok == true and .manifest.schema_version == "workcell-manifest/v1"' >/dev/null
  test ! -e "$(jq -r '.receipt.workspace_path' "$result")"
done

test "$(sort -u "$RUN_IDS_FILE" | wc -l | tr -d ' ')" -eq "$RUN_COUNT"
test -z "$(git -C "$TMP_REPO" status --porcelain --untracked-files=all)"
for index in $(seq 1 "$RUN_COUNT"); do
  container_name="kujo-workcell-$(jq -r '.receipt.run_id' "$OUT_ROOT/results/result-$index.json")"
  test -z "$($BACKEND ps -aq --filter "name=^/${container_name}$")"
done

ENDED="$(date +%s)"
ELAPSED_MS="$(((ENDED - STARTED) * 1000))"
EVIDENCE="$(jq -n \
  --arg backend "$BACKEND" \
  --arg rootless "$ROOTLESS" \
  --arg count "$RUN_COUNT" \
  --arg elapsed "$ELAPSED_MS" \
  '{schema_version:"workcell-load-evidence/v1",backend:$backend,status:"passed",rootless:($rootless == "true"),concurrent_runs:($count|tonumber),unique_run_ids:true,source_repository_unchanged:true,artifacts_verified:true,manifests_verified:true,workspaces_cleaned:true,containers_cleaned:true,elapsed_ms:($elapsed|tonumber)}')"
if [ -n "$EVIDENCE_FILE" ]; then
  mkdir -p "$(dirname "$EVIDENCE_FILE")"
  printf '%s\n' "$EVIDENCE" > "$EVIDENCE_FILE"
fi
printf '%s\n' "$EVIDENCE"
