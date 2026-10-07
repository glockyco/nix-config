## MODIFIED Requirements

### Requirement: Declarative executable and adapter ownership

The workstation SHALL supply the unmodified vendor Plannotator package on macbook-pro and Korolev's WSL environment through the commit-pinned `plannotator-packages` input as an ordinary host package. The OMP adapter SHALL belong to the published personal plugin installed through OMP's plugin manager using the command defined by `publish-plugin-through-omp-plugin-manager`. The adapter SHALL invoke the supplied executable without installing software, selecting versions, or loading the Plannotator Pi extension. Preferences, review history, and temporary data SHALL remain outside the Nix store and tracked source files.

#### Scenario: Launch from a clean managed session

- **WHEN** the user starts the default official OMP command in Tern after the reviewed packages are activated and the personal plugin is installed
- **THEN** visual annotation commands and the pinned ordinary Plannotator executable are available through the plugin-manager installation and host PATH
- **AND** activation has not installed the plugin, opened a browser, or rewritten OMP configuration

## ADDED Requirements

### Requirement: Local annotation browser boundary

Review servers SHALL listen on loopback only and SHALL open the local browser on macOS or the Windows browser for local WSL use. The integration SHALL NOT enable tailnet publication, remote sharing, firewall access, or an activation-time service. Noninteractive and remote-session invocation SHALL fail clearly rather than publish a server automatically.

#### Scenario: Annotate from WSL through Tern

- **WHEN** a local upstream OMP session in Tern for Windows starts annotation in Korolev's WSL environment
- **THEN** the Windows browser can reach the temporary review through local WSL connectivity
- **AND** the review is not reachable from another tailnet host

#### Scenario: Annotate on macOS

- **WHEN** a local upstream OMP session in Tern starts annotation on macbook-pro
- **THEN** the local browser displays the review and feedback returns to that session
- **AND** no persistent network service is installed

## REMOVED Requirements

### Requirement: Local browser and network boundary

**Reason**: The Herdr/wrapped-session scenario describes a retired terminal/runtime.
**Migration**: Preserve the complete loopback/local-browser/remote-invocation boundary and both platform scenarios under Local annotation browser boundary, using upstream OMP in Tern.
