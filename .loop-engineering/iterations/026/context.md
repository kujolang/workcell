# Context

- Objective: continue the review backlog with the next concrete exported-API correctness gap.
- Finding: `build_policy({})` crashed with `Missing map key: "workspace"`; `inspect_policy` and `spawn_options` had the same incomplete-definition precondition.
- Scope: fail-closed validation at exported policy boundaries, regression coverage, documentation, and full local/OCI verification.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
