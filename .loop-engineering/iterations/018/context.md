# Context

- Objective: continue the review backlog with the next concrete security correctness gap.
- Finding: declared artifact secret policies silently treated unreadable/binary files as clean, allowing `reject` or `redact` exports to bypass inspection.
- Scope: fail-closed artifact inspection and redaction, regression coverage for both secret actions, release-count/documentation updates, and local Docker verification.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
