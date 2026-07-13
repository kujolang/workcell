# Context

- Objective: continue the review backlog with the next concrete correctness and enterprise usability gap.
- Finding: the CLI parser did not recognize global `--help`/`--version`, silently ignored options intended for another command, and accepted extra positional arguments without error.
- Scope: strict command boundaries, machine-readable CLI metadata, regression coverage, and documentation.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
