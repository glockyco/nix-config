## ADDED Requirements

### Requirement: Container runtime on the WSL host

The WSL host SHALL provide a rootless container runtime that accepts Docker commands. The runtime SHALL run inside the WSL distribution. The workstation SHALL NOT require a Windows container product, and SHALL NOT require nested virtualization.

#### Scenario: Run a container

- **WHEN** the user runs a container image on the WSL host after activation
- **THEN** the container starts and exits with its own status
- **AND** the runtime requires no root privileges and no separate virtual machine

#### Scenario: Use the Docker command name

- **WHEN** a project command invokes the Docker command name
- **THEN** the declared runtime serves that command

#### Scenario: Preserve the boundary

- **WHEN** the host configuration is reviewed
- **THEN** it declares no Windows container product
- **AND** it declares no listening container service that another host can reach
