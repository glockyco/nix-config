## Purpose

Ensure the managed Mac user session can run Nix-backed repository checks from GUI applications without depending on interactive shell initialization.

## ADDED Requirements

### Requirement: Darwin saves a persistent Nix lookup path

The Darwin host SHALL save a persistent user-domain `PATH` that includes the installed Nix executable directory and the standard macOS command directories. It SHALL NOT alter Git hooks or install project tools globally. An application-specific `PATH` can override the saved value.

#### Scenario: Activation saves the PATH

- **WHEN** the Darwin host activation completes without a reboot
- **THEN** the persistent user-domain `PATH` contains the stable host Nix executable directory and standard macOS command directories

#### Scenario: Fork runs a repository hook with an explicit PATH

- **WHEN** Fork starts with that `PATH` passed explicitly to `open -a Fork`
- **THEN** a Git hook that calls `nix develop` resolves the installed host Nix executable
- **AND** the hook still obtains project tools from its repository development shell

#### Scenario: Inspect the generated activation

- **WHEN** the Darwin host evaluates its activation script
- **THEN** it configures the persistent user-domain `PATH` with the stable host Nix executable directory and the standard macOS command directories
- **AND** no mutable checkout or Nix store generation path is needed to find `nix`
