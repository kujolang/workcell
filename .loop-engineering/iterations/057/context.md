# Context

- Objective: continue the review backlog with result-schema ambiguity in declarative verification.
- Finding: verification definitions accepted duplicate check names, producing ambiguous machine-readable results even though checks were indexed separately at runtime.
- Scope: reject duplicate verification names, add a schema regression, and rerun all local/deployment evidence gates.
- External boundary: hosted CI remains unavailable because GitHub Actions billing/spending-limit eligibility has not been restored.
