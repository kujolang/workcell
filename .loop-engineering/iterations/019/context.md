# Context

- Objective: continue the review backlog with the next concrete correctness and security gaps.
- Findings: `resolve_definition` indexed `network.mode` when a malformed definition supplied `network: null`, causing a VM runtime error instead of a validation result; recursive artifact redaction referenced an undefined `relative` value on write failure.
- Scope: fail-closed malformed-definition handling, safe artifact redaction errors, regression coverage, contract documentation, and full local runtime verification.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
