# Spec Delta

## MODIFIED Requirements

### Requirement: Declarative WSL host configuration

The repository SHALL define the WSL host as one NixOS configuration for `x86_64-linux`. That configuration SHALL own the Linux system scope, including `/etc/wsl.conf`, the default user, systemd, the Nix settings, the system package set and users.users.<name>.packages. Chezmoi SHALL own Linux user files independently of system activation; Home Manager SHALL not be present. The host SHALL NOT require a distribution package manager, a separate Nix installer, or an imperative user-profile entry.

#### Scenario: Build the WSL host

- **WHEN** the WSL host configuration is built from the locked repository
- **THEN** its system closure resolves from the pinned nixpkgs
- **AND** the build requires no source-built compiler toolchain
- **AND** the closure contains chezmoi, OpenSpec, Plannotator and the curated WSL language servers without Roslyn

#### Scenario: Own the WSL runtime settings

- **WHEN** the WSL host is running
- **THEN** `/etc/wsl.conf` matches the declared configuration
- **AND** systemd is process 1
- **AND** the declared default user owns the interactive session

#### Scenario: Report no failed system units

- **WHEN** the WSL host completes activation
- **THEN** `systemctl is-system-running` reports a running system
- **AND** no unit is in a failed state

### Requirement: Declared host defaults

Each host SHALL derive its name from its host directory and SHALL declare its interactive user, time zone, locale, and applicable user-visible paths through shared TOML facts consumed and validated by typed options in `hosts/<name>/host.nix`. Each host SHALL select its roles through explicit imports in `hosts/<name>/default.nix`. A platform baseline SHALL read typed host options and SHALL NOT supply another machine's identity or paths. The WSL host SHALL declare the login shell and time and measurement formats for its interactive session.

#### Scenario: Inspect the interactive session

- **WHEN** the declared user starts a new interactive session
- **THEN** the session runs the system-declared login shell with portable chezmoi configuration
- **AND** the prompt, shared history, and completion behavior of the system/chezmoi ownership split are active

#### Scenario: Report local time and formats

- **WHEN** a host reports the date, time, and a measured quantity
- **THEN** it uses its declared time zone and locale
- **AND** the WSL host uses 24-hour time and metric measurement

#### Scenario: Inspect machine identity

- **WHEN** a host configuration evaluates
- **THEN** its host name comes from the typed directory-keyed registry, and its display name, when applicable, comes from host options
- **AND** no platform module supplies another machine's name

#### Scenario: Resolve a user-visible path

- **WHEN** a module needs the repository checkout or screenshot directory
- **THEN** both Nix and chezmoi derive the path from the same shared fact validated by the typed host declaration
- **AND** it does not embed an interactive user name

#### Scenario: Select a host role

- **WHEN** a host selects an optional machine role
- **THEN** its `default.nix` explicitly imports that role
- **AND** the platform baseline does not import the role

### Requirement: Repository-specific Git identity

The WSL host SHALL declare `johann.glock@scch.at` as the global Git email. It SHALL declare `11704293+glockyco@users.noreply.github.com` for every Git worktree below `~/src/github.com/` through a conditional Git include. The global email SHALL remain effective below `~/src/gitlab.scch.at/` and outside the GitHub tree unless a repository-local email overrides it. A repository-local `user.email` SHALL override both declared identities. Chezmoi SHALL render the user Git configuration from shared identity/path data; neither system activation nor chezmoi SHALL write repository-local Git configuration.

#### Scenario: Bootstrap with a work email

- **WHEN** the WSL host declares `johann.glock@scch.at` as the global Git email
- **AND** the user inspects the effective email in a GitHub worktree
- **THEN** Git reports `11704293+glockyco@users.noreply.github.com`
- **AND** the global Git email remains `johann.glock@scch.at`

#### Scenario: Commit in a personal repository

- **WHEN** the user commits in a Git worktree below `~/src/github.com/`
- **THEN** Git uses `11704293+glockyco@users.noreply.github.com`
- **AND** the result does not depend on the repository owner

#### Scenario: Commit outside a personal repository tree

- **WHEN** the user commits in a Git worktree below `~/src/gitlab.scch.at/`
- **THEN** Git uses `johann.glock@scch.at`

#### Scenario: Use a repository-local override

- **WHEN** a repository below either declared host tree has a repository-local `user.email`
- **THEN** Git uses the repository-local email

#### Scenario: Inspect a fresh checkout

- **WHEN** the user clones a repository below `~/src/github.com/` after activation
- **THEN** Git reports the GitHub no-reply address without repository-local Git configuration
