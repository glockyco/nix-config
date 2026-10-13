## MODIFIED Requirements

### Requirement: Installed upstream host discovery

The guidance SHALL determine the target host, official command path/version, plugin-manager installation identity/version, and requested scope before mutation. It SHALL default to the current host and SHALL NOT treat a Nix check-tool pin, previous session, or another host's evidence as the current runtime. The Mac's official installation and native Korolev's Tern-managed installation SHALL be distinguished.

#### Scenario: Check tools and installed plugin differ

- **WHEN** the reviewed build-time plugin/check input differs from the user's installed plugin release
- **THEN** the agent identifies their separate ownership
- **AND** it does not activate Nix to claim that the runtime plugin was upgraded

#### Scenario: Only one host was requested

- **WHEN** the user requests an update from a supported host without requesting other hosts
- **THEN** the agent updates only that host
- **AND** remote build access does not authorize remote installation, activation, or runtime updates

### Requirement: Installed release completion evidence

An updated result SHALL identify the host, actual official executable path and version, plugin-manager identity, installed release/path, and exercised checks. It SHALL require a fresh upstream OMP session in Tern and applicable personal-policy, commit-preview, Plannotator, and language-server checks. It SHALL distinguish the fresh process from still-running old sessions and record evidence with the change/session rather than current-state manuals.

#### Scenario: A new installation passes acceptance

- **WHEN** the installed executable/plugin pass direct checks and applicable fresh-session smoke
- **THEN** the agent reports observed versions/paths, exercised checks, and available recovery prerequisites
- **AND** a successful version command or publication alone is not complete acceptance
