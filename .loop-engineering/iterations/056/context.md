# Context

- Objective: continue the review backlog with manifest-verification integrity failures.
- Findings: a forged manifest could repeat an existing file entry or omit a run file while adjusting totals, and verification still returned success.
- Scope: require unique entries and exact complete-run coverage, add tamper regressions, and rerun all local/deployment evidence gates.
- External boundary: hosted CI remains unavailable because GitHub Actions billing/spending-limit eligibility has not been restored.
