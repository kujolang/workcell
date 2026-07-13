# Context

- Objective: continue the review backlog with the next concrete filesystem boundary failure.
- Finding: workspace symlink scanning called `list_dir` and `file_size` without exception handling; a permission-denied directory crashed the Kujo VM instead of returning a structured scan failure.
- Scope: convert scan failures into stable API errors, add a permission-denied regression, and rerun the local and deployment evidence gates.
- External boundary: hosted CI remains unavailable because GitHub Actions billing/spending-limit eligibility has not been restored.
