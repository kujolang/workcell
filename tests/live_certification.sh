#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
PROVIDER="${1:-}"
MODE="${2:-}"

case "$PROVIDER" in
  e2b) gate_name=WORKCELL_LIVE_E2B; credential_name=E2B_API_KEY ;;
  vercel-sandbox) gate_name=WORKCELL_LIVE_VERCEL_SANDBOX; credential_name=VERCEL_OIDC_TOKEN ;;
  daytona) gate_name=WORKCELL_LIVE_DAYTONA; credential_name=DAYTONA_API_KEY ;;
  *) echo "usage: tests/live_certification.sh {e2b|vercel-sandbox|daytona} [--fixture]" >&2; exit 2 ;;
esac

fixture=false
if [ "$MODE" = "--fixture" ]; then
  fixture=true
elif [ -n "$MODE" ]; then
  echo "unknown live-certification option: $MODE" >&2
  exit 2
fi

manifest="$ROOT/adapters/official/$PROVIDER/manifest.json"
test -f "$manifest"

require_positive_int() {
  local name="$1" value="$2" maximum="$3"
  case "$value" in ''|*[!0-9]*) echo "$name must be a positive integer" >&2; exit 2 ;; esac
  if [ "$value" -le 0 ] || [ "$value" -gt "$maximum" ]; then
    echo "$name must be between 1 and $maximum" >&2
    exit 2
  fi
}

max_runtime_seconds="${WORKCELL_LIVE_MAX_RUNTIME_SECONDS:-120}"
max_concurrency="${WORKCELL_LIVE_MAX_CONCURRENCY:-1}"
max_upload_bytes="${WORKCELL_LIVE_MAX_UPLOAD_BYTES:-10485760}"
max_download_bytes="${WORKCELL_LIVE_MAX_DOWNLOAD_BYTES:-10485760}"
max_log_bytes="${WORKCELL_LIVE_MAX_LOG_BYTES:-262144}"
require_positive_int WORKCELL_LIVE_MAX_RUNTIME_SECONDS "$max_runtime_seconds" 300
require_positive_int WORKCELL_LIVE_MAX_CONCURRENCY "$max_concurrency" 1
require_positive_int WORKCELL_LIVE_MAX_UPLOAD_BYTES "$max_upload_bytes" 10485760
require_positive_int WORKCELL_LIVE_MAX_DOWNLOAD_BYTES "$max_download_bytes" 10485760
require_positive_int WORKCELL_LIVE_MAX_LOG_BYTES "$max_log_bytes" 1048576

if [ "$fixture" = false ]; then
  if [ "${WORKCELL_LIVE_AUTHORIZED:-}" != 1 ] || [ "${!gate_name:-}" != 1 ]; then
    echo "live certification is blocked: set WORKCELL_LIVE_AUTHORIZED=1 and $gate_name=1 after explicit approval" >&2
    exit 3
  fi
  if [ -z "${!credential_name:-}" ]; then
    echo "live certification is blocked: credential reference env:$credential_name is unavailable" >&2
    exit 3
  fi
  for required_name in WORKCELL_LIVE_EVIDENCE_DIR WORKCELL_LIVE_PROFILES_FILE WORKCELL_LIVE_PROFILE_ID WORKCELL_LIVE_ACCOUNT_PLAN WORKCELL_LIVE_REGION WORKCELL_LIVE_IMAGE_TEMPLATE WORKCELL_LIVE_SPEND_CEILING; do
    if [ -z "${!required_name:-}" ]; then
      echo "live certification is blocked: $required_name is required" >&2
      exit 3
    fi
  done
fi

evidence_dir="${WORKCELL_LIVE_EVIDENCE_DIR:-}"
if [ -z "$evidence_dir" ]; then evidence_dir="$(mktemp -d)/workcell-live-fixture-$PROVIDER"; fi
case "$evidence_dir" in /*) ;; *) echo "WORKCELL_LIVE_EVIDENCE_DIR must be absolute" >&2; exit 2 ;; esac
case "$evidence_dir/" in "$ROOT/"*) echo "live evidence must stay outside the WorkCell checkout" >&2; exit 2 ;; esac
if [ -L "$evidence_dir" ]; then echo "live evidence directory must not be a symlink" >&2; exit 2; fi
mkdir -p "$evidence_dir"
chmod 700 "$evidence_dir"

source_repo="${WORKCELL_LIVE_SOURCE_REPO:-}"
source_temp=""
if [ -z "$source_repo" ]; then
  source_temp="$(mktemp -d)"
  source_repo="$source_temp/source"
  trap 'if [ -n "$source_temp" ]; then rm -rf "$source_temp"; fi' EXIT
  mkdir -p "$source_repo"
  git -C "$source_repo" init -q
  git -C "$source_repo" config user.name workcell-certification
  git -C "$source_repo" config user.email workcell-certification@example.invalid
  printf 'immutable workcell certification fixture\n' > "$source_repo/README.md"
  git -C "$source_repo" add README.md
  git -C "$source_repo" commit -qm 'fixture: immutable certification source'
fi
if [ -n "$(git -C "$source_repo" status --porcelain)" ]; then
  echo "live certification source repository must be clean" >&2
  exit 3
fi

definition="$evidence_dir/workcell.json"
profiles="$evidence_dir/profiles.json"
profile_id="${WORKCELL_LIVE_PROFILE_ID:-certification}"
timeout_ms=$((max_runtime_seconds * 1000))

jq -n --argjson timeout "$timeout_ms" --argjson logs "$max_log_bytes" --argjson upload "$max_upload_bytes" '{
  schema:"workcell-definition/v2alpha1",
  name:"live-certification-fixture",
  workload:{kind:"linux-process",image:{reference:"alpine:3.20",digest:"",signature_key:""},command:["sh","-lc","printf workcell-certification\\n"],working_directory:"/workspace"},
  workspace:{source:"clean-git-commit",materialization:"portable-clone",mount_path:"/workspace",scan:{max_files:1000,max_bytes:$upload,max_depth:32}},
  environment:{allow:[],set:{}},secrets:[],
  requirements:{compute:{cpus:1,memory:"256m",pids:64},execution:{timeout_ms:$timeout,max_output_bytes:$logs},network:{mode:"none"},filesystem:{read_only_root:true,writable:["/workspace"],tmpfs:["/tmp"]}},
  artifacts:{export:[]},verification:{version:1,commands:[]},cleanup:{keep_failed:false},receipt:{path:".workcell/runs"}
}' > "$definition"

if [ "$fixture" = true ]; then
  jq -n --arg provider "$PROVIDER" --arg profile "$profile_id" --argjson timeout "$timeout_ms" --argjson logs "$max_log_bytes" --argjson upload "$max_upload_bytes" --argjson download "$max_download_bytes" '{schema:"workcell-host-profiles/v1alpha1",profiles:{($profile):{backend:$provider,credential_ref:"",adapter_options:{($provider):{fixture_mode:true}},policy:{max_cpus:1,max_memory_mb:256,max_pids:64,max_timeout_ms:$timeout,max_output_bytes:$logs,max_workspace_upload_bytes:$upload,max_artifact_download_bytes:$download}}}}' > "$profiles"
else
  profiles="$WORKCELL_LIVE_PROFILES_FILE"
fi

started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
adapter_version="$(jq -r '.adapter_version' "$manifest")"
source_commit="$(git -C "$source_repo" rev-parse HEAD)"
workcell_version="$($KUJO run "$ROOT/main.kujo" -- --version | awk '{print $2}')"

set +e
inspect_output="$($KUJO run "$ROOT/main.kujo" -- inspect --file "$definition" --repo "$source_repo" --profiles "$profiles" --profile "$profile_id" --manifest "$manifest" --summary 2>&1)"
inspect_code=$?
set -e
printf '%s\n' "$inspect_output" > "$evidence_dir/inspect.json"
if [ "$inspect_code" -ne 0 ]; then
  jq -n --arg provider "$PROVIDER" --arg mode "$([ "$fixture" = true ] && echo fixture || echo live)" --arg started "$started" --arg error "inspect failed" '{schema_version:"workcell-live-certification/v1",status:"blocked",provider:$provider,mode:$mode,started_at:$started,error:$error,resources_remaining:"unknown"}' > "$evidence_dir/report.json"
  exit "$inspect_code"
fi

set +e
run_output="$($KUJO run "$ROOT/main.kujo" -- run --file "$definition" --repo "$source_repo" --output "$evidence_dir/runs" --profiles "$profiles" --profile "$profile_id" --manifest "$manifest" --summary 2>&1)"
run_code=$?
set -e
printf '%s\n' "$run_output" > "$evidence_dir/run-summary.json"
receipt_path="$(printf '%s' "$run_output" | jq -r '.receipt_path // empty' 2>/dev/null || true)"
if [ -z "$receipt_path" ] || [ ! -f "$receipt_path" ]; then
  jq -n --arg provider "$PROVIDER" --arg mode "$([ "$fixture" = true ] && echo fixture || echo live)" --arg started "$started" --argjson exit_code "$run_code" '{schema_version:"workcell-live-certification/v1",status:"recovery-required",provider:$provider,mode:$mode,started_at:$started,run_exit_code:$exit_code,resources_remaining:"unknown"}' > "$evidence_dir/report.json"
  exit "$run_code"
fi
run_dir="$(dirname "$receipt_path")"
"$KUJO" run "$ROOT/main.kujo" -- verify --run "$run_dir" --json > "$evidence_dir/verify.json"

cleanup_status="$(jq -r '.cleanup.status // "unknown"' "$receipt_path")"
profile_fingerprint="$(jq -r '.run.profile_fingerprint // "unknown"' "$receipt_path")"
resources_remaining="$(jq -r '(.cleanup.remaining // []) | length' "$receipt_path")"
status=passed
if [ "$run_code" -ne 0 ] || [ "$cleanup_status" != complete ] || [ "$resources_remaining" -ne 0 ] || ! jq -e '.ok == true' "$evidence_dir/verify.json" >/dev/null; then status=failed; fi

jq -n \
  --arg status "$status" --arg provider "$PROVIDER" --arg mode "$([ "$fixture" = true ] && echo fixture || echo live)" \
  --arg started "$started" --arg completed "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg workcell "$workcell_version" \
  --arg runtime_commit "$(cat "$ROOT/RUNTIME_VERSION")" --arg adapter_version "$adapter_version" \
  --arg account_plan "${WORKCELL_LIVE_ACCOUNT_PLAN:-offline-fixture}" --arg region "${WORKCELL_LIVE_REGION:-offline-fixture}" \
  --arg image_template "${WORKCELL_LIVE_IMAGE_TEMPLATE:-offline-fixture}" --arg profile_fingerprint "$profile_fingerprint" \
  --arg source_commit "$source_commit" --arg cleanup_status "$cleanup_status" --argjson resources_remaining "$resources_remaining" \
  --arg receipt_path "$receipt_path" \
  --argjson runtime_seconds "$max_runtime_seconds" --argjson concurrency "$max_concurrency" --argjson upload "$max_upload_bytes" \
  --argjson download "$max_download_bytes" --argjson logs "$max_log_bytes" --arg spend "${WORKCELL_LIVE_SPEND_CEILING:-not-applicable-fixture}" \
  '{schema_version:"workcell-live-certification/v1",status:$status,provider:$provider,mode:$mode,started_at:$started,completed_at:$completed,versions:{workcell:$workcell,runtime_commit:$runtime_commit,adapter:$adapter_version},scope:{account_plan:$account_plan,region:$region,image_template:$image_template,profile_fingerprint:$profile_fingerprint,source_commit:$source_commit},bounds:{max_runtime_seconds:$runtime_seconds,max_concurrency:$concurrency,max_upload_bytes:$upload,max_download_bytes:$download,max_log_bytes:$logs,spend_ceiling:$spend},evidence:{inspect:"inspect.json",run_summary:"run-summary.json",verify:"verify.json",receipt:$receipt_path},cleanup:{status:$cleanup_status,resources_remaining:$resources_remaining},security_probes:{status:"not-run",dns:"not-observed",ipv4:"not-observed",ipv6:"not-observed",metadata:"not-observed",private_link_local:"not-observed",redirects:"not-observed",provider_exceptions:"not-observed",secret_canary:"not-observed"}}' > "$evidence_dir/report.json"

if [ "$status" != passed ]; then exit 1; fi
printf '%s\n' "$evidence_dir/report.json"
