# Context

- Objective: continue the review backlog with the next concrete utility path and text API robustness gap.
- Finding: `ensure_dir`, path helpers, `read_text`, `load_json`, `save_json`, and `contains_text` crashed on null or invalid inputs.
- Scope: fail-closed utility input handling, regression coverage, documentation, and full local/Docker verification.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
