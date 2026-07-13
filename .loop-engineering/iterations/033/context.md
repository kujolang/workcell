# Context

- Objective: continue the review backlog with the next concrete workspace and doctor API robustness gap.
- Finding: repository inspection, symlink scanning, workspace creation, and doctor report APIs crashed on null or invalid inputs.
- Scope: fail-closed boundary validation, regression coverage, documentation, and full local/Docker verification.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
