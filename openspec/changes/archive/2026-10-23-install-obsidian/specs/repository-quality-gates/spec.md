# Spec Delta

## MODIFIED Requirements

### Requirement: One declaration owns each host fact

Each host-specific fact SHALL have one declaration: name is the host directory key; facts shared with user configuration live in home/.chezmoidata/\*.toml and remaining system facts in hosts/<name>/host.nix. Nix SHALL validate them through config.host and config.fleet.hosts; chezmoi SHALL read the same shared TOML. Every generated file and check SHALL derive values from that owner. A check SHALL NOT repeat a machine name, user name, durable path, application, or resource value. The temporary Air integration SHALL remain role-owned until its removal under issue #17; it SHALL NOT gain a durable host endpoint declaration.

#### Scenario: Change a screenshot directory

- **WHEN** a host changes its declared screenshot directory
- **THEN** the system default and chezmoi directory preparation use the new path
- **AND** neither consumer needs an edit

#### Scenario: Change an application record

- **WHEN** a maintainer changes a declared Homebrew application's cask, application path, Dock position, or login start
- **THEN** the generated Homebrew cask set, Dock layout, and login agents change together
- **AND** no second application list exists

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
