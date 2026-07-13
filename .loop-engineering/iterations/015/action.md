# Action

- Added `tests/egress_deployment_contract.sh` for operator-supplied default or pre-created custom networks.
- Made the contract runner fail closed on missing networks, unsupported probe schemes, and URL credentials.
- Recorded allowed/denied destinations, selected egress policy, `network_mutation: false`, and receipt/manifest hashes in a versioned evidence contract.
- Added shell/schema regression wiring and documented safe use for host-firewall and transparent-proxy deployments.
