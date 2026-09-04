#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"

DEFINITION_SCHEMA="$($KUJO run "$ROOT/main.kujo" -- validate --schema)"
CLI_SCHEMA="$($KUJO run "$ROOT/main.kujo" -- help --json)"
printf '%s' "$DEFINITION_SCHEMA" | jq -e '.schema_version == "workcell-definition/v1" and .unknown_fields == "rejected" and (.fields.runtime.fields | index("require_digest") != null) and (.fields.integrations.opt_in == true)' >/dev/null
printf '%s' "$DEFINITION_SCHEMA" | jq -e '(.fields.network.fields | index("egress") != null) and ((.fields.network.egress.policy_enum | index("deny-by-default")) != null)' >/dev/null
printf '%s' "$CLI_SCHEMA" | jq -e '.schema_version == "workcell-cli/v1" and (.global_options | index("--help") != null) and (.global_options | index("--version") != null) and ([.commands[] | select(.name == "verify")] | length) == 1 and .exit_codes["8"] != null' >/dev/null
printf '%s' "$CLI_SCHEMA" | jq -e '([.commands[] | select(.name == "run" and (.options | index("--summary") != null))] | length) == 1' >/dev/null
printf '%s' "$CLI_SCHEMA" | jq -e '([.commands[] | select(.name == "inspect" and (.options | index("--summary") != null))] | length) == 1' >/dev/null
grep -Fq 'workcell-receipt/v1' "$ROOT/src/receipts/receipt.kujo"
grep -Fq 'workcell-runtime-inventory/v1' "$ROOT/src/runtime/docker.kujo"
grep -Fq 'workcell-clean/v1' "$ROOT/src/cli/cli.kujo"
grep -Fq 'workcell-oci-evidence/v1' "$ROOT/tests/oci_smoke.sh"
grep -Fq 'workcell-oci-evidence/v1' "$ROOT/docs/api-compatibility.md"
grep -Fq 'workcell-egress-deployment-evidence/v1' "$ROOT/tests/egress_deployment_contract.sh"
grep -Fq 'workcell-egress-deployment-evidence/v1' "$ROOT/docs/api-compatibility.md"
grep -Fq 'workcell-load-evidence/v1' "$ROOT/tests/load_integration.sh"
grep -Fq 'workcell-load-evidence/v1' "$ROOT/docs/api-compatibility.md"
grep -Fq 'workcell-run-summary/v1' "$ROOT/docs/api-compatibility.md"
grep -Fq 'workcell-inspect-summary/v1' "$ROOT/docs/api-compatibility.md"
jq -e '.properties.schema_version.const == "workcell-backend-conformance/v1" and .additionalProperties == false' "$ROOT/schemas/workcell-backend-conformance-v1.schema.json" >/dev/null
jq -e '.properties.schema_version.const == "workcell-live-certification/v1"' "$ROOT/schemas/workcell-live-certification-v1.schema.json" >/dev/null
grep -Fq 'docs/api-compatibility.md' "$ROOT/README.md"

echo "Schema compatibility contract passed"
