# Iteration 058 action

- Reproduced the Docker CLI behavior with a labeled active container and observed that `ps -aq --format` omitted names.
- Split inventory into a compatibility-preserving ID query and a correctly formatted detail query.
- Added additive `container_details[]` records with `id` and `name` fields.
- Added Docker integration assertions proving active labeled containers appear in structured dry-run inventory and remain preserved.
- Formatted the Kujo source and ran the offline, release, Docker, OCI, egress, and load gates.
