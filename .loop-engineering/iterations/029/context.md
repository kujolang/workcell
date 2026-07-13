# Context

- Objective: continue the review backlog with the next concrete receipt API robustness gap.
- Finding: `add_state`, `add_error`, and `finish_receipt` crashed on incomplete receipt objects; `new_receipt` crashed when its definition path was empty and `sha256_file` received an invalid path.
- Scope: fail-closed receipt mutation/construction validation, regression coverage, documentation, and full local/Docker verification.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
