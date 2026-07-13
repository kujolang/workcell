# Context

- Objective: continue the review backlog with the next concrete exported-API robustness gap.
- Findings: direct calls to `labels_for`, `definition_summary`, `verify_daemon_security`, `run_verification_checks`, `run_integrations`, `build_image`, `ensure_image`, and `new_receipt` crashed on incomplete inputs; `run_container` crashed when given an incomplete policy.
- Scope: fail-closed exported API boundaries, regression coverage, documentation, and full local/Docker verification.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
