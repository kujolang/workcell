# Context

- Objective: continue the review backlog with the next concrete workspace change-report API robustness gap.
- Finding: `changed_files_from_details` dereferenced malformed file entries; a null entry crashed the Kujo VM before the caller could receive a structured failure.
- Scope: validate change-detail entries and change-report output metadata, add regressions, update evidence, and rerun the full local/Docker/OCI gates.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
