# Spec Delta

## ADDED Requirements

### Requirement: Secondary NixOS WSL role

Korolev's NixOS-WSL environment SHALL be secondary to native Windows. It SHALL support repository Nix work, remote Mac builds, shell/Git/CLI tools, rootless Podman with Compose, read-only SCCH access, and Windows `open` interoperability. NixOS SHALL own its system and packages; chezmoi SHALL own its user files. It SHALL NOT require Linux browser automation or a WSL tailnet identity separate from Windows Korolev.

#### Scenario: Work on the configuration repository

- **WHEN** the user opens a fresh WSL shell in the configuration checkout
- **THEN** Nix can build the Korolev system and run the flake checks
- **AND** shell, Git, CLI configuration and `nixd` are available from the declared user environment
- **AND** a fresh Darwin derivation can build on the Mac using the Nix daemon's dedicated root-owned key through Windows-owned tailnet connectivity

#### Scenario: Run retained containers and access the share

- **WHEN** the activated WSL user invokes Podman and `docker compose` and reads a reachable directory below `/mnt/s`
- **THEN** containers run rootlessly with the declared official Compose provider and without a public API socket
- **AND** the SCCH share remains a read-only on-demand mount authenticated by the Windows session

#### Scenario: Inspect the reduced host

- **WHEN** the secondary WSL configuration and rendered user files are inspected
- **THEN** no Linux GCM, GnuPG, `pass`, credential pinentry/agent, or `GPG_TTY` declaration remains for HTTPS credentials
- **AND** no managed-browser ABI library set, enabled `nix-ld`, or dedicated JetBrains Mono system-font declaration remains
- **AND** neither activation nor chezmoi deletes mutable GPG, browser, OMP, container, or Windows credential state

### Requirement: Windows GCM for WSL HTTPS Git

WSL Git SHALL invoke the Git Credential Manager installed with Git for Windows for HTTPS authentication. Credentials SHALL remain in Windows Credential Manager, not the Linux home, repository, Nix store, or plaintext Git credential files. The declared WSL helper SHALL use the verified installed Windows executable; activation SHALL NOT enroll, copy, or fabricate credentials. Windows Git configuration SHALL own GCM provider and proxy settings.

#### Scenario: Authenticate and reuse a credential

- **WHEN** the owner authenticates to an approved HTTPS Git remote through Windows GCM from WSL
- **THEN** an authenticated Git operation succeeds through the declared Windows helper
- **AND** after a WSL restart the same operation succeeds with `GIT_TERMINAL_PROMPT=0` without GPG unlocking or re-entering the credential

#### Scenario: Apply over an old Linux credential configuration

- **WHEN** the user applies the reviewed chezmoi WSL configuration
- **THEN** the effective declared helper chain resets inherited helpers and selects only the verified Windows GCM executable
- **AND** the Linux GPG credential-store and provider snippets are absent
- **AND** Git identities, HTTPS protocol preference, SSH authentication and the separately mutable GitHub CLI login are preserved

#### Scenario: Missing credential or changed helper installation

- **WHEN** Windows GCM lacks the required credential or the declared executable no longer exists
- **THEN** unauthenticated non-interactive Git fails visibly
- **AND** no Linux helper or plaintext store is substituted
- **AND** the operator must authenticate interactively or reconcile the verified installed helper path before accepting the configuration

#### Scenario: Retain repository-local authority

- **WHEN** activation or chezmoi applies the user configuration
- **THEN** it does not rewrite repository-local Git configuration
- **AND** the documented credential smoke identifies local helper overrides that would bypass the declared Windows GCM helper

## MODIFIED Requirements

### Requirement: Declarative WSL Windows interoperability

The WSL host SHALL register Windows executable interoperability through the supported NixOS-WSL module. User-initiated browser launch, Windows `open` dispatch, and Windows GCM for HTTPS Git SHALL work without an OMP fallback or a manual kernel-entry script. Activation SHALL register the handler without launching a Windows application.

#### Scenario: Restore a missing Windows executable handler

- **WHEN** the host activates its declared configuration with no existing Windows executable handler
- **THEN** the standard `/init` interoperability handler is registered
- **AND** subsequent user-initiated Windows commands and local browser launch work
- **AND** activation itself launches no Windows application

#### Scenario: Dispatch a path and URI from the secondary environment

- **WHEN** the user invokes `open` for an existing Linux path or an absolute URI
- **THEN** the existing cross-platform open-command behavior dispatches the target to native Windows
- **AND** no Linux browser automation runtime is required

#### Scenario: Invoke Windows credentials from Linux Git

- **WHEN** Linux Git requests an HTTPS credential through the declared Windows GCM helper
- **THEN** the registered interop handler executes the verified Windows helper as the signed-in Windows user
- **AND** credentials are stored and reused by Windows rather than a Linux credential service

## REMOVED Requirements

### Requirement: Managed browser compatibility on WSL

**Reason**: Browser automation is owned by the verified native Windows workstation; the secondary WSL role has no remaining managed Linux browser or other declared foreign-loader workload.

**Migration**: Remove the WSL browser ABI library set, enabled `nix-ld`, associated ABI check and Linux browser smoke. Use native Windows OMP for browser tasks; retain user browser downloads/profiles/state untouched.

### Requirement: On-demand authenticated browser relay

**Reason**: Native Windows OMP no longer needs WSL to relay into a Windows browser profile.

**Migration**: Remove WSL relay installation and smoke guidance. Use the browser workflow accepted by `make-korolev-windows-native`; preserve native browser functionality and existing user profiles/extensions without creating a WSL relay fallback.

### Requirement: Monospace font for Linux rendering

**Reason**: The removed managed browser was the only declared renderer; repository inspection found no retained VHS package/tape or other consumer requiring this Linux font.

**Migration**: Remove the WSL JetBrains Mono declaration, font module import and font check. Tern uses separately owned Windows fonts; any future project renderer declares its fonts in its own environment.
