# Context

- Objective: continue the review backlog with the next concrete receipt-construction API robustness gap.
- Finding: receipt construction accepted a null run identifier and non-string source/workspace/policy metadata, allowing malformed execution evidence to be created.
- Scope: validate receipt identity and metadata types, strengthen receipt mutation boundaries, add regressions, update evidence, and rerun the full local/Docker/OCI gates.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
