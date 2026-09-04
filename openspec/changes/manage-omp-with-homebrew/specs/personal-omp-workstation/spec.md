## MODIFIED Requirements

### Requirement: Pinned executable and plugin inputs

The workstation SHALL resolve the personal plugin from an independently locked flake input. The personal plugin input SHALL provide a valid OMP plugin directory and SHALL remain in the `omp-agent-setup` repository rather than being copied into `nix-darwin`. The OMP executable SHALL be mutable platform-owned state: the official Homebrew formula on Darwin and the official prebuilt user-local binary in NixOS/WSL. No supported host SHALL retain a Nix-packaged OMP executable or fallback.

#### Scenario: Build the workstation package

- **WHEN** the workstation OMP wrapper is built for a supported host system
- **THEN** its personal plugin directory comes from a locked Nix store path
- **AND** the wrapper targets the platform-owned OMP executable
- **AND** the wrapper closure contains no Nix-packaged OMP executable

### Requirement: Default wrapped command

The default `omp` command SHALL invoke the platform-owned OMP executable with the immutable personal plugin enabled. On Darwin, the wrapper SHALL invoke the OMP executable from the stable Apple Silicon Homebrew prefix. In NixOS/WSL, the wrapper SHALL invoke the official prebuilt OMP executable from one fixed user-local path. The wrapper SHALL add only the curated language-server executables required by the supported matrix to its `PATH`.

#### Scenario: Resolve the default command

- **WHEN** a user resolves `omp` from a fresh login shell on a supported host
- **THEN** the resolved executable is the Nix-managed workstation wrapper
- **AND** the wrapper invokes the host's platform-owned OMP executable
- **AND** OMP discovers the packaged personal extension, skills, rule, and LSP overrides

#### Scenario: Start OMP from Windows Zed

- **WHEN** Windows Zed starts its configured OMP agent server
- **THEN** `wsl.exe` invokes the wrapped `omp acp` command inside the NixOS distribution
- **AND** no native Windows OMP executable or compatibility path is required

### Requirement: WSL host activation and rollback

The WSL host SHALL activate a new generation with the supported NixOS command. Activation SHALL reconcile Herdr through its supported integration interface and SHALL run deterministic local verification without a model call. A failed verification SHALL leave the previous generation available for selection. Activation and Nix generation rollback SHALL preserve the platform-owned OMP executable.

#### Scenario: Activate a reviewed revision

- **WHEN** the operator activates the WSL host from a reviewed repository revision
- **THEN** the host selects the wrapper, plugin, Herdr, OpenSpec, and language-server closures from the current lock
- **AND** Herdr reports its OMP integration as current
- **AND** deterministic verification exercises the user-local OMP executable without provider authentication

#### Scenario: Re-activate the same revision

- **WHEN** the operator activates the same revision again
- **THEN** the selected Nix closure, user-local OMP executable, and Herdr integration remain current
- **AND** activation creates no duplicate entry in any profile

#### Scenario: Roll back a rejected generation

- **WHEN** a generation fails local verification
- **THEN** the previous generation remains selectable
- **AND** selecting it restores the previous wrapper, plugin, Herdr, OpenSpec, and language-server paths
- **AND** the rollback changes neither the user-local OMP executable nor OMP-owned mutable state

### Requirement: Explicit WSL prerequisite boundary

The workstation SHALL provide a WSL 2 provisioning procedure for `x86_64-linux`. The procedure SHALL select Windows Terminal Stable as the native terminal host and the repository-defined NixOS distribution as its default profile. It SHALL identify Windows Terminal installation and settings, Windows feature enablement, repository access, official prebuilt OMP installation, and interactive provider authentication as manual prerequisites that the repository does not own.

#### Scenario: Start from a new Windows machine

- **WHEN** an operator follows the procedure on a machine without the personal OMP environment
- **THEN** the procedure establishes the prerequisites in dependency order
- **AND** it installs the official prebuilt OMP binary at the wrapper's fixed user-local path before verification
- **AND** Windows Terminal Stable opens the NixOS profile in the Linux user's home directory
- **AND** the procedure does not claim to manage Windows policy, Windows applications, or provider authentication

#### Scenario: Provision without administrator rights

- **WHEN** the operator holds standard Windows user rights only
- **AND** WSL 2 is already enabled
- **THEN** distribution import, user-local OMP installation, and host activation complete without elevation

#### Scenario: Use an unsupported architecture

- **WHEN** the operator attempts the procedure on a WSL architecture other than `x86_64-linux`
- **THEN** the procedure stops with an explicit unsupported-platform result before it changes the machine

### Requirement: Signed Linux binary cache

The WSL host SHALL declare Numtide's substituter and trusted public key in its system Nix configuration for the remaining `llm-agents` packages. The WSL host SHALL NOT depend on client-specified flake configuration for that substituter. The WSL OMP executable SHALL NOT depend on that cache.

#### Scenario: Install a cached OMP output

- **WHEN** the WSL host builds the personal OMP environment
- **THEN** Nix can fetch cached Herdr and OpenSpec outputs
- **AND** Nix does not compile or fetch an OMP package
- **AND** the default NixOS substituter remains configured

#### Scenario: Build as an unprivileged user

- **WHEN** an unprivileged user on the WSL host evaluates or builds a repository output
- **THEN** Nix does not report an ignored client-specified `trusted-public-keys` setting

## ADDED Requirements

### Requirement: Explicit platform OMP updates

OMP executable updates SHALL remain explicit operations outside Nix activation. Darwin SHALL use the official Homebrew upgrade operation. NixOS/WSL SHALL use the official upstream installer in binary mode with a fixed installation directory. Each update path SHALL install an official prebuilt release and SHALL NOT build OMP from source.

#### Scenario: Update OMP on Darwin

- **WHEN** the operator runs the documented Homebrew upgrade operation
- **THEN** Homebrew updates the official OMP formula without a repository change
- **AND** the Nix-managed wrapper invokes the updated executable

#### Scenario: Update OMP in WSL

- **WHEN** the operator runs the documented official installer command in binary mode
- **THEN** the installer replaces the OMP executable at the wrapper's fixed user-local target
- **AND** the update needs no repository change or Nix generation

### Requirement: Platform-aware activation verification

The local verifier SHALL exercise the platform-owned OMP executable through the immutable wrapper configuration. Verification SHALL fail clearly when the expected executable is absent. Both platforms SHALL verify the immutable personal plugin and current Herdr integration.

#### Scenario: Verify a platform installation

- **WHEN** activation runs with the expected platform-owned OMP executable installed
- **THEN** the verifier reports the executable version
- **AND** it reports the personal plugin path under `/nix/store`
- **AND** Herdr reports its OMP integration as current

#### Scenario: Reject a missing executable

- **WHEN** activation runs without the expected platform-owned OMP executable
- **THEN** verification fails with an actionable error that names the expected path and installation command

### Requirement: Platform-owned OMP rollback

A Nix generation rollback SHALL restore the prior wrapper, personal plugin, Herdr, OpenSpec, and language-server paths. It SHALL preserve the currently installed platform-owned OMP version. OMP version recovery SHALL use the owning platform installer rather than a Nix generation.

#### Scenario: Roll back a Nix generation

- **WHEN** the operator restores a prior Nix generation on either supported host
- **THEN** the prior immutable wrapper and plugin become active
- **AND** the platform-owned OMP installation remains unchanged
- **AND** OMP-owned mutable state remains unchanged

#### Scenario: Recover an OMP release

- **WHEN** a platform-owned OMP update fails deterministic verification or the real-session smoke
- **THEN** the recovery procedure uses Homebrew on Darwin or the official binary installer with an explicit release on WSL
- **AND** it does not present Nix generation rollback as an OMP version rollback
