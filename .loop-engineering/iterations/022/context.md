# Context

- Objective: continue the review backlog with the next concrete robustness gap.
- Finding: the release-report renderer crashed when evidence files contained oversized numeric metrics or exit codes.
- Scope: fail-safe report parsing, malformed-evidence regression coverage, documentation, and full local verification.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
