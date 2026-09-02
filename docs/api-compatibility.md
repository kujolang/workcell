# Workcell API compatibility policy

Workcell exposes versioned JSON contracts for definitions, CLI metadata, receipts, run manifests, runtime inventory, cleanup results, and optional integration evidence. Consumers should select fields by name and tolerate additive fields.

The Workcell product version and contract identifiers are independent. Workcell 1.0.0 reports product version `1.0.0` while retaining `/v1` schema identifiers for the stable first version of each machine contract. Product releases do not mechanically rename schemas or evidence formats.

## Contract identifiers

| Contract | Identifier | Producer | Compatibility rule |
| --- | --- | --- | --- |
| Definition | `workcell-definition/v1` | `validate --schema` | Unknown input fields are rejected; new fields require safe defaults and an additive schema update. |
| CLI metadata | `workcell-cli/v1` | `help --json` | Commands, options, global `--help`/`--version`, and exit-code meanings are additive within v1; unsupported command options and extra positionals fail with usage code 2. |
| Run summary | `workcell-run-summary/v1` | `run --summary` | Compact stable pointers/verdicts for agents and automation; the receipt remains authoritative evidence. |
| Receipt | `workcell-receipt/v1` | `receipt.json` | `workcell_version` is the product version and `definition_version` is the input contract version; existing fields remain stable and new evidence fields are additive. |
| Integrity manifest | `workcell-manifest/v1` | `manifest.json` | Relative paths, byte counts, and SHA-256 entries are verified by `workcell verify`. |
| Portable definition | `workcell-definition/v2alpha1` | selected definition file | Alpha semantic workload contract; provider configuration is excluded. |
| Backend protocol | `workcell-backend/v1alpha1` | adapter stdin/stdout | Alpha bounded JSONL executable protocol. Request/result envelopes are closed and operation shapes are strict; additive fields require a contract revision while alpha. |
| Portable receipt | `workcell-receipt/v2alpha1` | `receipt.json` | Alpha controls ledger, provider identity, recovery, log quality, resources, cost, and cleanup. |
| Recovery journal | `workcell-recovery/v1` | run `recovery/` directory | Ownership-bound provision intent, optional attached external resource handle, and cleanup attempts. Existing handle-bearing v1 journals remain valid. |
| Runtime inventory | `workcell-runtime-inventory/v1` | `clean --dry-run --json` | Backend-neutral inventory fields are canonical; `docker` remains a compatibility alias. `containers` retains the ID list, while additive `container_details[]` provides `{id,name}` records. |
| Cleanup result | `workcell-clean/v1` | `clean --json` | `runtime_backend` and `runtime` are canonical; legacy aliases remain during the v1 compatibility period. |
| Integration evidence | `workcell-integration/v1` | `receipt.integrations[]` and `integrations/*.json` | Adapter reports are isolated, bounded, and additive to the primary result. |
| OCI smoke evidence | `workcell-oci-evidence/v1` | `tests/oci_smoke.sh` stdout | Deployment validation records the selected OCI backend and observed rootless status. |
| Egress evidence | `workcell-egress-evidence/v1` | `tests/egress_integration.sh` stdout | Deployment validation records an allowed internal destination, a blocked external DNS destination, the selected enforcement profile, and receipt/manifest hashes. |
| Egress deployment evidence | `workcell-egress-deployment-evidence/v1` | `tests/egress_deployment_contract.sh` stdout | Operator-supplied network validation records allowed/denied destinations, the selected policy, `network_mutation: false`, and receipt/manifest hashes without creating or changing deployment infrastructure. |
| Load evidence | `workcell-load-evidence/v1` | `tests/load_integration.sh` stdout | Concurrent deployment validation records unique run IDs, unchanged source, verified artifacts/manifests, cleaned workspaces/containers, and elapsed time. |
| Local release report | `workcell-report/v1` | `tests/release_report.sh` | `workcell_version` identifies the product; suite and deployment-gate status is additive and skipped deployment gates are explicit. |
| Release provenance | `workcell-release-provenance/v1` | `scripts/build_release_artifacts.sh` | Binds the product version, tag, source commit, Kujo runtime commit, source archive, release report, and hashes. |

## Exit-code stability

`0` means success. `2` means usage or definition validation, `3` source/workspace preparation, `4` Docker or image preparation, `5` container startup, `6` timeout, `7` workload failure, `8` verification or artifact failure, `9` cleanup failure, and `10` internal failure. A future major contract version is required to repurpose an existing code.

## Deprecation and release rules

- Add fields before removing fields.
- Keep deprecated fields for at least one documented compatibility period and retain their meaning while present.
- Update `help --json`, `validate --schema`, this document, fixtures, and contract tests in the same change.
- Do not infer backend or result state from human-readable output.
- Consumers must ignore unknown JSON fields and should pin the contract identifier they support.
- A breaking change requires a new schema identifier, migration notes, and a release-note entry.
- Patch releases preserve all v1 contracts. Minor releases may add optional commands, fields, or evidence with safe defaults. Consumers should pin the Workcell release and inspect the changelog before upgrading.

The definition schema is intentionally stricter for input than the result schemas are for output: misspelled policy input must fail closed, while result consumers must remain forward-compatible with additive evidence.
