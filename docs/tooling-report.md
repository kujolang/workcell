# Workcell Tooling Report

## Inspected

Kujo, PackWrite, RunLedger, ChangeBucket, ShipCheck, Fence, CaseFile, Muzzle, Agents SDK, and Dispatch were reviewed for layout, CLI, policy, receipt, artifact, lifecycle, and evidence conventions. The detailed audit is in [repository-conventions.md](repository-conventions.md).

## Used

- Kujo runtime checker and VM for every Workcell source/test module.
- RunLedger to start the engineering run and preserve the run identifier.
- Kujo loop-engineering harness to configure deterministic gates, evidence, commits, push behavior, and Strata consolidation.
- ChangeBucket, ShipCheck, Fence, and CaseFile are scheduled as final local ecosystem audits when their current CLIs are available; they are not imported into Workcell's runtime path.

## Integration gaps

The sibling tools are standalone Kujo CLIs rather than stable importable packages. Workcell therefore uses local adapters and documents future direct integration instead of duplicating or tightly coupling to their repositories. Docker was not available for this environment, so no Docker-backed receipt can be claimed.
