# Context

- Objective: continue the review backlog with the next concrete CLI API robustness gap.
- Finding: exported `main`/argument parsing crashed when callers supplied a non-array argument value.
- Scope: fail-closed CLI boundary handling, regression coverage, documentation, and full local/Docker verification.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
