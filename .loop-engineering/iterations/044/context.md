# Context

- Objective: continue the review backlog with the next concrete artifact-policy boundary gap.
- Finding: top-level artifact limits accepted a string and allowed-extension entries accepted null; export execution then attempted incompatible comparisons/conversions and crashed the Kujo VM.
- Scope: validate top-level numeric limits and extension entries before artifact traversal, add regressions, update evidence, and rerun the full local/Docker/OCI gates.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
