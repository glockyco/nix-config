## ADDED Requirements

### Requirement: Darwin gates run from the Linux host

The Linux host SHALL be able to build every `aarch64-darwin` check of the repository through the declared Darwin remote builder. The result SHALL be the same derivation that the Darwin host builds locally. A gate that reads the Darwin store, such as the build-plan inspection, SHALL run on the Darwin host through the tailnet SSH endpoint.

#### Scenario: Run all checks from one host

- **WHEN** the operator runs `nix flake check --all-systems` on the Linux host while the Darwin host is connected
- **THEN** every `x86_64-linux` check builds locally, every `aarch64-darwin` check builds on the Darwin host, and the command exits 0

#### Scenario: Compare with the Darwin host's own gate

- **WHEN** the same revision is checked on the Darwin host with `nix flake check`
- **THEN** each `aarch64-darwin` check resolves to the same derivation path as the one built from the Linux host

#### Scenario: Inspect build plans from the Linux host

- **WHEN** the operator runs the documented build-plan inspection command from the Linux host
- **THEN** the inspection executes on the Darwin host over the tailnet SSH endpoint and reports its result to the Linux host
- **AND** the SSH client's exit status equals the remote command's exit status

#### Scenario: A remote gate fails

- **WHEN** a gate on the Darwin host exits nonzero
- **THEN** the Linux caller receives that nonzero status without a parsing wrapper or success fallback
