## MODIFIED Requirements

### Requirement: Native agent environment

OMP SHALL operate in a local Windows checkout using native Windows tools. OMP SHALL be the official standalone Windows binary installed through the official installer in binary mode and updated explicitly through `omp update`. The personal plugin SHALL be installed in user scope using the plugin-manager install command defined by `publish-plugin-through-omp-plugin-manager` (`omp plugin marketplace add glockyco/omp-agent-setup`, then `omp plugin install --scope user personal@glockyco`) and upgraded with `omp plugin marketplace update glockyco` followed by `omp plugin upgrade --scope user personal@glockyco` and a fresh session. It SHALL not load from a manual source checkout, explicit wrapper flags, or a copied Nix-store wrapper. Required workflow dependencies SHALL resolve natively. Each installation SHALL keep its own writable authentication and session state.

WSL may be installed on the desktop and SHALL NOT be treated as a defect. A required native tool SHALL NOT be satisfied by a WSL launcher: in particular the desktop's `bash.exe` resolves to WSL, so a native shell requirement SHALL be met by PowerShell or Git Bash instead. A NixOS-WSL host on this machine is a separate configuration with its own agent installation and is outside this capability.

#### Scenario: Complete native repository work

- **WHEN** the operator starts the official agent in a disposable Windows checkout
- **THEN** the agent completes a harmless repository task using Windows tools
- **AND** the plugin-manager personal policy extension loads and completes a commit preview without creating a commit
- **AND** required shell, Git, OpenSpec, and research-helper functions pass their applicable smoke checks, with OpenSpec workflows exposed as `/personal:opsx-*`
- **AND** language-server diagnostics remain out of scope for the native desktop agent, which SHALL NOT resolve a server through a WSL launcher; a separate WSL host may serve its own agent instead

#### Scenario: Inspect local runtime ownership

- **WHEN** the operator checks the agent's executable, plugin-manager installation, and state paths
- **THEN** no executable or interpreter used by the native Windows agent resolves through WSL or a Nix store path
- **AND** provider authentication was established locally rather than copied from another machine

#### Scenario: Update the native installation

- **WHEN** the operator explicitly updates the desktop's OMP and published personal plugin through their upstream commands
- **THEN** a fresh native session verifies observed executable/plugin versions and personal behavior
- **AND** native writable authentication and saved conversations remain in place
