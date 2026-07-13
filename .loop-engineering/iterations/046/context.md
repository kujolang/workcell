# Context

- Objective: continue the review backlog with the next concrete JSON persistence API robustness gap.
- Finding: `save_json` propagated an uncaught atomic-write exception when a parent path existed as a regular file, allowing a Kujo VM crash during evidence persistence.
- Scope: fail closed on parent-directory creation and atomic-write errors, add a regression, update evidence, and rerun the full local/Docker/OCI/load/egress gates.
- External boundary: hosted CI remains unavailable because GitHub Actions run `29241222514` was blocked by account billing/spending-limit eligibility.
