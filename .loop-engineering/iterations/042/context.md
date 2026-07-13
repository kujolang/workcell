# Context

- Objective: continue the review backlog with the next concrete artifact-export API robustness gap.
- Finding: `export_declared_with_policy` called `len` on a null `export` policy, crashing the Kujo VM before returning a structured validation result.
- Scope: validate exported artifact policy shapes and limit values before traversal/copy/redaction, add regressions, update evidence, and rerun the full local/Docker/OCI gates.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
