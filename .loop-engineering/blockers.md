# External Blockers

blockers:
  - id: kujo-formatter-semantic-safety
    command: "kujo format --write"
    evidence: "Resolved by Kujo commits ff31153 and ff662a3 with syntax-preserving protection, cached regexes, and regression tests; all Workcell .kujo files pass format --check."
    status: resolved
    next_action: "Add AST-aware wrapping when the Kujo formatter has syntax-tree support."
  - id: kujo-process-stream-cancellation
    command: "spawn_process"
    evidence: "Resolved by Kujo commits 73f3e7c and 0f77781: bounded channel/file stream sinks, chunk-boundary-safe redaction, cancellation hooks, and regression coverage; Workcell integrates stream logs and cancellation receipts in c3aa847."
    status: resolved
    next_action: "Exercise the contract on rootless Linux and VM-backed deployments."
  - id: kujo-linter-reachability
    command: "kujo lint"
    evidence: "Resolved by Kujo commit 7ef6eb8 with token-aware reachability; all Workcell source modules pass lint --json with zero findings."
    status: resolved
    next_action: "Evolve the pass to AST/control-flow analysis for branch-sensitive reachability."
  - id: docker-rootless-host
    command: "workcell doctor --json"
    evidence: "Current Colima daemon reports seccomp/AppArmor but is not rootless; doctor reports this as a warning."
    status: host-owned
    next_action: "Use a rootless Docker/VM/microVM deployment for multi-tenant untrusted workloads."

Resolved evidence:

- Docker CLI and daemon: `workcell doctor --json` reported 9 passed, 0 blocked, 1 warning (non-rootless daemon) on the clean pushed worktree.
- Docker integration: `KUJO=../kujo/target/release/kujo ./tests/docker_integration.sh` passed, including the verification example and `clean --dry-run` inventory contract.
