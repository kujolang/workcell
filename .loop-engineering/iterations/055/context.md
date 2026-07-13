# Context

- Objective: continue the review backlog with the next concrete artifact-export integrity failures.
- Findings: the public artifact exporter accepted duplicate declarations and ancestor/descendant overlaps; an order where a redacted child was followed by its parent could overwrite redacted output with source content.
- Scope: reject duplicate and overlapping declarations before any copy, add regressions, and rerun the offline and Docker evidence gates.
- External boundary: hosted CI remains unavailable because GitHub Actions billing/spending-limit eligibility has not been restored.
