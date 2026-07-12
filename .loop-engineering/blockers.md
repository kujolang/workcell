# External Blockers

blockers:
  - id: kujo-formatter-semantic-safety
    command: "kujo format --write"
    evidence: "Previously observed rewriting valid Workcell operators, path separators in strings, and CLI flags; documented in docs/next-hardening-backlog.md."
    status: external-blocked
    next_action: "Fix formatter AST round-trip semantics in the Kujo repository before formatting Workcell modules."
  - id: kujo-process-stream-cancellation
    command: "spawn_process"
    evidence: "Current Kujo API returns bounded completion output and timeout metadata but exposes no Workcell-consumable stream callback or parent-signal hook."
    status: external-blocked
    next_action: "Coordinate a Kujo process API contract for streaming redaction and cancellation receipts."
  - id: kujo-linter-reachability
    command: "kujo lint"
    evidence: "Current linter exits successfully but emits widespread unreachable-code warnings for valid imported/exported modules."
    status: external-blocked
    next_action: "Improve module-aware reachability analysis or establish a reviewed warning baseline in Kujo."
  - id: docker-rootless-host
    command: "workcell doctor --json"
    evidence: "Current Colima daemon reports seccomp/AppArmor but is not rootless; doctor reports this as a warning."
    status: host-owned
    next_action: "Use a rootless Docker/VM/microVM deployment for multi-tenant untrusted workloads."

Resolved evidence:

- Docker CLI and daemon: `workcell doctor --json` reported 8 passed, 0 blocked, 2 warnings (non-rootless daemon and dirty review worktree).
- Docker integration: `KUJO=../kujo/target/release/kujo ./tests/docker_integration.sh` passed, including the verification example and `clean --dry-run` inventory contract.
