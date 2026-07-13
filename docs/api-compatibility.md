# Workcell API compatibility policy

Workcell exposes versioned JSON contracts for definitions, CLI metadata, receipts, run manifests, runtime inventory, cleanup results, and optional integration evidence. Consumers should select fields by name and tolerate additive fields.

## Contract identifiers

| Contract | Identifier | Producer | Compatibility rule |
| --- | --- | --- | --- |
| Definition | `workcell-definition/v1` | `validate --schema` | Unknown input fields are rejected; new fields require safe defaults and an additive schema update. |
| CLI metadata | `workcell-cli/v1` | `help --json` | Commands, options, and exit-code meanings are additive within v1. |
| Receipt | `workcell-receipt/v1` | `receipt.json` | Existing fields remain stable; new evidence fields such as `network_policy` are additive. |
| Integrity manifest | `workcell-manifest/v1` | `manifest.json` | Relative paths, byte counts, and SHA-256 entries are verified by `workcell verify`. |
| Runtime inventory | `workcell-runtime-inventory/v1` | `clean --dry-run --json` | Backend-neutral inventory fields are canonical; `docker` remains a compatibility alias. |
| Cleanup result | `workcell-clean/v1` | `clean --json` | `runtime_backend` and `runtime` are canonical; legacy aliases remain during the v1 compatibility period. |
| Integration evidence | `workcell-integration/v1` | `receipt.integrations[]` and `integrations/*.json` | Adapter reports are isolated, bounded, and additive to the primary result. |
| OCI smoke evidence | `workcell-oci-evidence/v1` | `tests/oci_smoke.sh` stdout | Deployment validation records the selected OCI backend and observed rootless status. |
| Egress evidence | `workcell-egress-evidence/v1` | `tests/egress_integration.sh` stdout | Deployment validation records an allowed internal destination, a blocked external DNS destination, the selected enforcement profile, and receipt/manifest hashes. |
| Local release report | `workcell-report/v1` | `tests/release_report.sh` | Suite and deployment-gate status is additive; skipped deployment gates are explicit. |

## Exit-code stability

`0` means success. `2` means usage or definition validation, `3` source/workspace preparation, `4` Docker or image preparation, `5` container startup, `6` timeout, `7` workload failure, `8` verification or artifact failure, `9` cleanup failure, and `10` internal failure. A future major contract version is required to repurpose an existing code.

## Deprecation and release rules

- Add fields before removing fields.
- Keep deprecated fields for at least one documented compatibility period and retain their meaning while present.
- Update `help --json`, `validate --schema`, this document, fixtures, and contract tests in the same change.
- Do not infer backend or result state from human-readable output.
- Consumers must ignore unknown JSON fields and should pin the contract identifier they support.
- A breaking change requires a new schema identifier, migration notes, and a release-note entry.

The definition schema is intentionally stricter for input than the result schemas are for output: misspelled policy input must fail closed, while result consumers must remain forward-compatible with additive evidence.
