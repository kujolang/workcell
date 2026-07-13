# Iteration 061 context

Objective: close the next evidence-backed local cleanup portability defect after iteration 060.

Review reproduced a real bug in `src/runtime/docker.kujo`: `stop_container` matched `No such container` case-sensitively, while Docker/Podman can return lowercase or alternate missing-container wording. A fake-runtime contract failed for `no container with name or ID` and `container not found` before the fix. Scope is Workcell runtime/tests/docs/evidence; hosted CI and production host controls remain external.
