# Hosted CI status

Updated: 2036-07-13

The repository workflow is configured to run the offline, Docker, rootless-capable Podman, egress, concurrent-load, OCI, and doctor gates on `ubuntu-latest`. The latest observed pushed commit `82df7f15a9138e8f304ef640e48155473f18dfc1` reached GitHub Actions run [29244196678](https://github.com/kujolang/workcell/actions/runs/29244196678), but the `verify` job was not started: GitHub reported that recent account payments failed or the spending limit must be increased.

This is an external billing/Actions availability failure, not a test or source failure. Until repository billing is restored, hosted matrix evidence is unavailable and Workcell must not claim that hosted CI has passed. Local evidence remains current: 181 Workcell assertions, 19 workspace assertions, 5 stress assertions, 205 release assertions with 0 failures, Docker integration, Docker egress, concurrent Docker load, and Docker OCI smoke all passed.

Release action: restore GitHub Actions billing eligibility, rerun the workflow on `main`, and retain the run URL and job logs as release evidence. The workflow already contains the required Podman and egress gates; no local code change can satisfy an account-level billing restriction.
