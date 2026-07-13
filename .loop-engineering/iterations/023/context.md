# Context

- Objective: close the remaining malformed-evidence correctness gap found while reviewing iteration 022.
- Finding: a malformed `Passed:` metric was converted to zero but could still leave a suite marked successful when its exit code was zero.
- Scope: preserve safe report rendering while marking malformed metrics unsuccessful, extend the report contract, and rerun local gates.
- External boundary: hosted CI billing and deployment-owned production controls remain unchanged.
