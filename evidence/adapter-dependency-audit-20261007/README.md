# Official adapter dependency audit — 2026-10-07

The original audit recorded by Agent City bd994e4 reported six high and one
critical finding. Compatible transitive lockfile updates preserve the pinned
provider SDK versions:

- shell-quote 1.10.0 → 1.12.0
- @grpc/grpc-js 1.14.4 → 1.14.5
- brace-expansion 5.0.9 → 5.0.12

The updated `audit.json` reports four high findings and zero critical findings.
They form one chain: @daytona/sdk → fast-glob → micromatch → braces 3.0.3.
The upstream advisory lists no patched braces version; the latest Daytona SDK
also declares fast-glob. We did not introduce an incompatible override, remove
Daytona, suppress findings, or weaken the high-severity release gate.

References: https://github.com/advisories/GHSA-vfj7-8cjw-p6xm and
https://github.com/advisories/GHSA-pqg4-j6r4-53mv (checked 2026-10-07).

Installed SDK inspection locates fast-glob in Image.extractCopySources for Dockerfile
COPY sources. Workcell runtime/providers.mjs provisions from an image string and
has no direct Image-building call. This is partial reachability evidence, not a
proof of non-exploitability. Official cloud adapters remain release-blocked.
Local Docker/Podman does not use these provider SDKs.

The shell-quote regression uses dangerous token shapes without executing them,
and checks ordinary literal argument round-tripping. Provider fixture tests and
regenerated bundled dependency/wrapper integrity must pass before committing.
No live cloud account, credentials, model, or container is used by these checks.

Verification recorded: integrity regeneration/check PASS; JavaScript25/25 PASS;
Workcell release-report249 assertions PASS; Markdown links PASS. First Kujo
conformance invocation passed E2B/Vercel but failed Daytona without diagnostics.
Retained in conformance-initial.txt and CaseFile
2026-10-07-170340-adapterconformance. The test now prints failed operation/error
for future diagnosis. Failure cause is not established; do not infer host load.

The separate diagnostic rerun passed all6 checks, including Daytona's13-operation
offline conformance contract; conformance-rerun.txt preserves output. The initial
intermittent failure remains unexplained; this is not a claim of long-run reliability.
Full release remains blocked by the four high dependency findings.
