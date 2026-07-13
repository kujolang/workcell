# Context

- Objective: continue the review backlog with the next concrete artifact boundary failure.
- Finding: artifact export recursively called `list_dir` and `file_size` without exception handling; a permission-denied declared artifact directory crashed the Kujo VM instead of returning a structured export failure.
- Scope: harden recursive artifact scanning, redaction traversal, and output-directory preparation, add a permission-denied regression, and preserve the existing artifact security contracts.
- External boundary: hosted CI remains unavailable because GitHub Actions billing/spending-limit eligibility has not been restored.
