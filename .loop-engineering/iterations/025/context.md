# Context

- Objective: continue the review backlog with the next concrete validation/security gap.
- Finding: direct `validate_definition` calls crashed when numeric resource or workspace-scan sections were present but missing required numeric keys.
- Scope: fail-closed partial-section validation, regression coverage, documentation, and full local verification.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
