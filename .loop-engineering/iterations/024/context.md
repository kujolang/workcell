# Context

- Objective: continue the review backlog with the next concrete robustness gap.
- Finding: the opt-in performance harness crashed when `WORKCELL_PERF_FILES` contained an oversized integer.
- Scope: fail-safe bounded performance-fixture parsing, regression execution in the standard suite, documentation, and full local verification.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
