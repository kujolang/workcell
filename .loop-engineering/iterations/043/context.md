# Context

- Objective: continue the review backlog with the next concrete manifest API robustness gap.
- Finding: `write_manifest` accepted a missing output directory and created a valid-looking empty manifest; verification likewise accepted a missing directory after the write path created it.
- Scope: require existing non-symlink manifest directories, add regressions, update evidence, and rerun the full local/Docker/OCI gates.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
