# Hosted CI status

Updated: 2036-07-13

The repository workflow is configured to run the offline, Docker, rootless-capable Podman, egress, concurrent-load, OCI, and doctor gates on `ubuntu-latest`. The latest pushed commit `536d88b5f6180e2d7c1805983bf468413668e0d5` reached GitHub Actions run [29241222514](https://github.com/kujolang/workcell/actions/runs/29241222514), but the `verify` job was not started: GitHub reported that recent account payments failed or the spending limit must be increased.

This is an external billing/Actions availability failure, not a test or source failure. Until repository billing is restored, hosted matrix evidence is unavailable and Workcell must not claim that hosted CI has passed. Local evidence remains current: 180 Workcell assertions, 18 workspace assertions, 5 stress assertions, 203 release assertions with 0 failures, Docker integration, Docker egress, concurrent Docker load, and Docker OCI smoke all passed.

Release action: restore GitHub Actions billing eligibility, rerun the workflow on `main`, and retain the run URL and job logs as release evidence. The workflow already contains the required Podman and egress gates; no local code change can satisfy an account-level billing restriction.
