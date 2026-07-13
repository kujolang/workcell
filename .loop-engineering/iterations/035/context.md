# Context

- Objective: continue the review backlog with the next concrete coordinator API robustness gap.
- Finding: the high-level `run_workcell` API crashed when `requested_output` was null after definition and repository validation succeeded.
- Scope: fail-closed coordinator input handling, regression coverage, documentation, and full local/Docker verification.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
