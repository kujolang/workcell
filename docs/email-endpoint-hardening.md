# Email endpoint hardening verification

Starting Workcell main: `3999f11`. This bounded follow-up preserves the trusted
host's Docker endpoint/configuration selectors for workload launch, prevents
implicit image pulls after preparation and blocks undeclared client-config
proxies from entering the container. Workload environment declarations continue
to govern explicit proxy values. Podman uses the existing endpoint handling.
No public schema or provider lifecycle contract changes.

The fake-Docker regression exercises actual subprocess launch in both Kujo
engines with default and explicit Docker configuration, checking selectors,
proxy overrides, secret exclusion and `--pull=never`. The retained real Colima
run `wc-a2a9067562f045fb8175bbf298a4c2b1` passed with verified receipt integrity
and complete cleanup. Email's expanded isolated run
`wc-3bd7167f842c4d2e8e295959319199bf` also passed on the existing local image.
These prove local Docker behavior, not remote-provider certification.

## Required-runtime acceptance

The exact `RUNTIME_VERSION` source
`692512a9070fdba713f160d795bbddb8077db7b5` built successfully in Linux with
`cargo build --locked`, one compiler job and incremental compilation disabled.
The debug executable was copied and stripped of debug symbols before testing;
it reports Kujo 1.2.1 and has SHA-256
`e6b2a711928af016efcddbd85357403067a05c2f655be7fa45eb5bd95da16939`.

The first host build failed on process creation. The first Linux build filled
the VM disk; disposable compiler caches were removed before the successful
retry. Those failed attempts remain in `.muzzle/logs/email-required-runtime*`.
An adapter test on the VM's Node 18 failed with `ERR_REQUIRE_ESM`; Node 18 is
below the package's declared minimum. Verification uses Node 24.20.0 downloaded
from nodejs.org with its published SHA-256 checked.

An unchanged dependency-integrity check took 9.995 seconds on the shared macOS
mount and 6.994 seconds on Linux-local storage during concurrent verification.
The mounted full run hit a ten-second Daytona describe deadline. No timeout or
integrity gate was weakened. The full suite passes from Linux-local
snapshot `8a01a8b0b59006d1e5ffbc89406cd2c4fb76e020`, with all 216 source files
hash-matched before execution. These two observations describe storage effects,
not a code optimization or production performance claim.

All required `AGENTS.md` validation commands pass (exit 0), including the
exact-version gate, complete test script, 249 passing release-report checks,
23 official-adapter tests (zero failed/skipped), and package integrity.
The added documentation also passes the link audit in the original checkout.
Optional live OCI/provider/matrix gates remain outside this fixture campaign;
the real Colima runs above provide the separate local Docker evidence.
Acceptance receipt: `.muzzle/reports/email-endpoint-acceptance-20260912.json`.
Preserve final output in
`.muzzle/logs/email-required-native-full-20260912.log`; the source manifest is
`.muzzle/reports/email-native-workcell-source-20260912.json`. The verification
commands are the required `AGENTS.md` gates, including the complete test script,
quality/version/link checks, release report and official-adapter tests/integrity.
No images were published, public services deployed or provider accounts used.
