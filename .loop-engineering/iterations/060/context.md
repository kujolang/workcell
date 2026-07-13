# Iteration 060 context

Objective: close the next evidence-backed local lifecycle and security gaps after iteration 059.

Review found four concrete defects. Workspace cleanup trusted a symlinked `.owner` marker, including during empty-orphan recovery. Runtime removal treated expected Docker/Podman missing-container responses as cleanup failures. A null output request silently selected the default output root. Container startup failures were returned with result stage `failed`, so the CLI mapped the documented startup code 5 to internal-error code 10. Scope is limited to Workcell source, fake-runtime/workspace regressions, documentation, and release evidence. Hosted CI billing and production rootless/egress/image-governance controls remain external.
