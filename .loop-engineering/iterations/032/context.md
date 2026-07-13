# Context

- Objective: continue the review backlog with the next concrete exported API robustness gap.
- Finding: artifact export/log APIs, integrity manifest APIs, and Docker image/container APIs crashed on null or invalid inputs.
- Scope: fail-closed boundary validation, regression coverage, documentation, and full local/Docker verification.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
