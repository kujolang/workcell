# Context

- Objective: continue the review backlog with the next concrete container-runtime boundary gap.
- Finding: exported runtime helpers accepted null or unknown backends; invalid cleanup silently defaulted to Docker, while malformed log and image calls reached the process layer.
- Scope: reject invalid backend/resource inputs before runtime invocation, add regressions, update evidence, and rerun the full local/Docker/OCI gates.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
