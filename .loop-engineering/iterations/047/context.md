# Context

- Objective: continue the review backlog with the next concrete patch-generation API robustness gap.
- Finding: `make_patch` called `file_exists` with a null output path after performing Git collection, causing a Kujo VM crash instead of rejecting the invalid destination.
- Scope: validate patch output paths before Git work, add a regression, update evidence, and rerun the full local/Docker/OCI/load/egress gates.
- External boundary: hosted CI remains unavailable because GitHub Actions run `29241222514` was blocked by account billing/spending-limit eligibility.
