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
