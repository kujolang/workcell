# Context

- Objective: continue the review backlog with the next concrete utility API robustness gap.
- Finding: `lines_of`, `process_ok`, `process_error`, `redact`, `env_secret_values`, `env_secret_stream_values`, and `first_line` crashed on null or invalid inputs.
- Scope: fail-closed utility input handling, regression coverage, documentation, and full local/Docker verification.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
