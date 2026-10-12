## MODIFIED Requirements

### Requirement: A development shell on every supported system

Every declared Nix system SHALL retain a pinned development shell. Native Windows SHALL have a documented pinned native development environment rather than a fictitious Windows Nix flake system. Every supported host SHALL install its commit hook through its own environment. Shared repository tools SHALL be usable there; platform-only tools SHALL stay on the hosts that can execute their workflows.

#### Scenario: Clone on a supported host

- **WHEN** a maintainer enters the repository on any supported host
- **THEN** the declared development environment for that platform resolves
- **AND** the commit hook is installed in that working tree

#### Scenario: A supported system gains no shell

- **WHEN** the repository declares a supported Nix system without a development shell, or native Windows support without its bootstrap
- **THEN** a repository check fails

#### Scenario: Host-specific tool outside its host

- **WHEN** a maintainer enters the development shell on a host that cannot complete a host-specific tool's workflow
- **THEN** that tool is absent from that environment rather than present and unusable
