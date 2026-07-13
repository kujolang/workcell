# Iteration 058 context

Objective: restore reliable container identification in runtime inventory while preserving the v1 compatibility contract.

The Docker CLI ignores formatted output when `ps -q` is combined with `--format`. The previous inventory query therefore returned IDs only, leaving `clean --dry-run --json` without names for incident response. The fix must remain backend-neutral, preserve the legacy `containers` ID list, add structured detail records, and include a live regression test. Hosted CI billing and deployment-owned rootless/egress controls remain external boundaries.
