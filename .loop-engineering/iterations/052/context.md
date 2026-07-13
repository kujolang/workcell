# Context

- Objective: continue the review backlog with the next concrete manifest filesystem failure.
- Finding: integrity-manifest collection called `list_dir` and `file_size` without exception handling; a permission-denied declared run directory crashed the Kujo VM.
- Scope: harden manifest collection and verification filesystem operations, add a permission-denied regression, and preserve offline and deployment manifest evidence.
- External boundary: hosted CI remains unavailable because GitHub Actions billing/spending-limit eligibility has not been restored.
