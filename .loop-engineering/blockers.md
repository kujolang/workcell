# External Blockers

blockers:
  - id: remote-ssh-unavailable
    command: "git push origin HEAD"
    evidence: "[main 2fe162c] Loop engineering: Build and verify the Kujo-native Workcell Docker-backed local execution MVP from the attached specification.
 1 file changed, 1 insertion(+)
fatal: 'origin' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists."
    status: external-blocked
    next_action: "Restore SSH/Git remote access."
  - id: remote-not-configured
    command: "git push"
    evidence: "fatal: No configured push destination. Configure a remote repository before pushing."
    status: external-blocked
    next_action: "Configure the repository's intended remote, then push the committed main branch."
  - id: docker-unavailable
    command: "KUJO=../kujo/target/release/kujo ./tests/docker_integration.sh"
    evidence: "SKIP Docker integration tests: Docker CLI/daemon unavailable"
    status: external-blocked
    next_action: "Run the integration suite after Docker CLI and daemon availability are restored."
  - id: remote-ssh-unavailable
    command: "git push origin HEAD"
    evidence: "[main c2a5105] Loop engineering: Build and verify the Kujo-native Workcell Docker-backed local execution MVP from the attached specification.
 1 file changed, 1 insertion(+)
fatal: 'origin' does not appear to be a git repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists."
    status: external-blocked
    next_action: "Restore SSH/Git remote access."
