## Purpose

Ensure the managed Mac user session can run Nix-backed repository checks from GUI applications without depending on interactive shell initialization.

## ADDED Requirements

### Requirement: GUI-launched Git can find Nix

The Darwin host SHALL persistently make the installed Nix executable available to GUI processes in user launchd domains after reboot. It SHALL retain the standard macOS command directories and SHALL NOT alter Git hooks or install project tools globally.

#### Scenario: Fork runs a repository hook

- **WHEN** the host configuration is activated, the Mac reboots, and Fork starts in the new user session
- **THEN** a Git hook that calls `nix develop` resolves the installed host Nix executable
- **AND** the hook still obtains project tools from its repository development shell

#### Scenario: Inspect the generated activation

- **WHEN** the Darwin host evaluates its activation script
- **THEN** it configures the persistent user-domain `PATH` with the stable host Nix executable directory and the standard macOS command directories
- **AND** no mutable checkout or Nix store generation path is needed to find `nix`
