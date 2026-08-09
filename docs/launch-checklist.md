# Workcell 1.0 Launch Checklist

Workcell 1.0 is stable for the documented local and CI Docker/Podman execution contract. This checklist does not claim universal sandboxing, hosted multi-tenant readiness, operator egress or image governance, signing-key custody, retention compliance, or enterprise certification.

## Preparation acceptance

- [ ] Product version surfaces and release artifact names agree on `1.0.0`.
- [ ] Released Kujo 1.0.0 commit `2b3e07d398016e92008d8399e79c441e012dce38` is pinned and used for every gate.
- [ ] Offline, CLI, format, lint, version, release-report, Markdown-link, and whitespace gates pass.
- [ ] Docker build, doctor, integration, concurrent-load, egress, self-proof, receipt verification, and cleanup pass.
- [ ] Podman doctor, OCI smoke, integration, concurrent-load, egress, and cleanup pass on supported Linux.
- [ ] ShipCheck passes with zero errors and no contradictory warnings.
- [ ] Hosted CI passes for the exact approved commit.
- [ ] Release artifacts reproduce, checksum verification passes, and provenance names the exact approved commit and runtime.
- [ ] Human approval names the exact commit to tag.

The commands, expected artifacts, rollback plan, tag procedure, and GitHub Release procedure are canonical in [the release process](release-process.md).

## Local preparation evidence — 2026-08-08

The released Kujo 1.0.0 commit was built in a detached worktree and verified as `kujo 1.0.0`. The Workcell CLI, version consistency, offline suite, quality gate, release report, Markdown-link audit, Docker image build, Docker doctor, Docker integration, four-run concurrent load, Docker egress enforcement, real Workcell self-proof, offline receipt verification, and ShipCheck all passed locally. ShipCheck reported 16 of 16 checks passed, zero errors, and zero warnings. Docker 29.5.2 ran through the local Colima profile with seccomp and AppArmor; its rootful state remained an explicit doctor warning rather than evidence of rootless isolation.

Podman gates are externally blocked on this host because the `podman` executable and engine are absent. `workcell doctor --backend podman --json` exited `3` with three blocked checks: CLI unavailable, engine unreachable, and security inspection unavailable. The safe resume action is to install and start rootless Podman on a supported Linux host, then run the Podman doctor, OCI smoke, integration, concurrent-load, and egress commands in [the release process](release-process.md). No Docker result is treated as Podman evidence.

## Hosted CI blocker record

The latest main-branch runs inspected during v1 preparation were [CI run 30376854891](https://github.com/kujolang/workcell/actions/runs/30376854891) and [artifact-guard run 30376854914](https://github.com/kujolang/workcell/actions/runs/30376854914). Both jobs completed as failures before a runner was assigned: `runner_name` was empty and the GitHub API returned an empty `steps` array. No repository command or workflow step started.

The account's hosted Actions billing or spending-limit state is the known external prerequisite. A repository or organization administrator must restore hosted runner allocation, then safely resume the baseline CI receipt with:

```bash
gh run rerun 30376854891 --repo kujolang/workcell
gh run rerun 30376854914 --repo kujolang/workcell
```

For the preparation branch or final approved commit, rerun its newer workflow IDs instead. The closest local evidence is the pinned-runtime gate set above and the dated [rootless Docker/Podman evidence](compatibility/rootless-docker-colima-2026-07-13.md). Local passes do not satisfy the hosted CI checkbox.

## Prohibited before approval

Do not create or push `v1.0.0`, create the GitHub Release, publish images or packages, deploy hosted runners, modify branch protection or repository policy, use live credentials, or force-push during preparation.
