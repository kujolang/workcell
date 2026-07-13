# Context

- Objective: continue the review backlog with the next concrete workspace cleanup failure.
- Finding: stale-workspace cleanup called `list_dir` directly on an unowned orphan directory; a permission-denied orphan crashed the Kujo VM instead of being preserved and reported.
- Scope: harden temporary-root and orphan-directory listing, add a permission-denied cleanup regression, and rerun lifecycle/deployment evidence.
- External boundary: hosted CI remains unavailable because GitHub Actions billing/spending-limit eligibility has not been restored.
