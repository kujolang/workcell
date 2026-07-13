# Action

- Guarded report metric and numeric evidence-file parsing with safe fallbacks.
- Extended `tests/report_contract.sh` with oversized metric and exit-code fixtures and an unsuccessful structured report assertion.
- Updated build and hardening evidence docs.
- Targeted malformed-evidence probe reproduced a VM crash before the fix and returned `workcell-report/v1` with `ok: false` after it.
