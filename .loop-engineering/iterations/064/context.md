# Iteration 064 context

Objective: close the next reproducible CLI API-boundary defect after iteration 063.

The prior boundary guard validated the current token type, but value-option lookahead still called `starts_with(tokens[i + 1], "--")` before validating the next token. On the previous committed source, `main(["--file", null])` reproduced `[KUJOVM001] [vm] Runtime Error: starts_with() requires string and prefix string arguments` and exited 4.

Repository-side external blockers remain hosted CI billing and deployment-owned rootless, egress, and image-governance evidence.
