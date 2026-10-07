## ADDED Requirements

### Requirement: Read-only SCCH share

The WSL host SHALL expose the SCCH share `\\scch.at\SCCH`, which Windows maps as `S:`, read-only at `/mnt/s`. The host SHALL mount the share on first access through the Windows file bridge, authenticated by the signed-in Windows session. The configuration SHALL declare no credential for the share. A path below `S:\` SHALL appear at the same relative path below `/mnt/s`. An unreachable share SHALL neither fail activation nor leave the system degraded. Each access while the share is unreachable SHALL fail with an error, and the first access after the share becomes reachable SHALL mount it.

#### Scenario: Read a directory on the share

- **WHEN** the interactive user lists a directory below `/mnt/s` while the Windows session can reach `S:`
- **THEN** the host mounts the share and lists the same entries as the corresponding directory below `S:\`
- **AND** the entries belong to the interactive user

#### Scenario: Attempt a write

- **WHEN** a Linux process creates, modifies, or deletes a file below `/mnt/s`
- **THEN** the operation fails because the mount is read-only
- **AND** the share is unchanged

#### Scenario: Access the share while it is unreachable

- **WHEN** a process accesses `/mnt/s` repeatedly while the share is unreachable
- **THEN** every access fails with an error instead of showing an empty directory
- **AND** the first access after the share becomes reachable mounts it

#### Scenario: Activate without the share

- **WHEN** the host activates or starts while the share is unreachable
- **THEN** no mount is attempted before first access
- **AND** `systemctl is-system-running` reports a running system

#### Scenario: Inspect the configuration

- **WHEN** the WSL host configuration is evaluated
- **THEN** it declares the share's UNC path, the read-only option, and an automount for `/mnt/s`
- **AND** it declares no password, token, or keytab for the share
