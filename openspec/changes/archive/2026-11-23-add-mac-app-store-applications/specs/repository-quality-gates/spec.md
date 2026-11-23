# Spec Delta

## MODIFIED Requirements

### Requirement: One declaration owns each host fact

Each host fact SHALL have one owner: directory key for name, home/.chezmoidata/\*.toml for shared user facts, hosts/<name>/host.nix for remaining system facts. Nix SHALL validate through config.host/config.fleet.hosts. Chezmoi SHALL read the shared TOML. Generated files and checks SHALL derive from that owner. Checks SHALL NOT repeat machine names, user names, durable paths, applications or resource values.

#### Scenario: Retain temporary Air ownership

- **WHEN** the temporary Air integration remains pending removal under issue #17
- **THEN** it SHALL remain role-owned and SHALL NOT gain a durable host endpoint declaration

#### Scenario: Change a screenshot directory

- **WHEN** a host changes its declared screenshot directory
- **THEN** the system default and chezmoi directory preparation use the new path
- **AND** neither consumer needs an edit

#### Scenario: Change an application record

- **WHEN** an application's cask, App Store identity, application path, Dock position, or login start changes in the shared inventory
- **THEN** the generated Homebrew cask and App Store sets, Dock layout, and login agents use that record
- **AND** no second application list exists

#### Scenario: Declare an App Store application

- **WHEN** an application record declares a positive App Store ID and a nonempty App Store name
- **THEN** the generated Homebrew configuration includes that name and ID without requiring a cask or application path
- **AND** the Mac provides the `mas` executable

#### Scenario: Reject an invalid application identity

- **WHEN** an application lacks a cask, App Store ID and application path, has an incomplete App Store identity, or duplicates another record's App Store ID or name
- **THEN** typed host evaluation fails instead of silently dropping or overwriting the record

#### Scenario: Reject a login start without an application path

- **WHEN** an application record requests a login start but declares no application path
- **THEN** evaluation fails with a message that names the record

#### Scenario: Change a container resource

- **WHEN** a maintainer changes one declared Colima capacity or mount value
- **THEN** the generated profile and its configuration check use the new value
- **AND** no second resource literal needs an edit

#### Scenario: Keep the temporary endpoint removable

- **WHEN** the Air role is selected
- **THEN** its current SSH aliases, batch command, SMB agent, link, and checks are available
- **AND** durable host declarations and platform baselines contain no Air endpoint value
