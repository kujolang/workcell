# Retained preservation observations

## Retained workspace observation

`src/evidence/retained_workspace.kujo` exposes the read-only
`observe_retained_workspace(workspace)` API for an installed trusted-host adapter.
It checks the Workcell owner marker, supported local Git materialization, source
availability and common Git directory, and reports current HEAD. Callers bind
these observation bytes to their expected evidence identity; changed HEAD is a
changed observation, not permission to replay. Missing ownership or workspace
fails closed. No process is resumed, preservation extended, or effect admitted.
Existing preservation-outcome/v1 documents, including `$ref` evidence, are not
rewritten by this API. Dispatch owns reference authorization and control policy.
