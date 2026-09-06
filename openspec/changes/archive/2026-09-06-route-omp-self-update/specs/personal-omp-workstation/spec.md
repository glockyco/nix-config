## MODIFIED Requirements

### Requirement: Default wrapped command

Except for the explicit `update` subcommand, the default `omp` command SHALL invoke the platform-owned OMP executable with the immutable personal plugin enabled. On Darwin, the wrapper SHALL invoke the OMP executable from the stable Apple Silicon Homebrew prefix. In NixOS/WSL, the wrapper SHALL invoke the official prebuilt OMP executable from one fixed user-local path. For normal sessions, the wrapper SHALL add only the curated language-server executables required by the supported matrix to its `PATH`. The update invocation SHALL additionally prioritize the owning platform's executable directory without changing the caller's environment.

#### Scenario: Resolve the default command

- **WHEN** a user resolves `omp` from a fresh login shell on a supported host
- **THEN** the resolved executable is the Nix-managed workstation wrapper
- **AND** the wrapper invokes the host's platform-owned OMP executable
- **AND** OMP discovers the packaged personal extension, skills, rule, and LSP overrides

#### Scenario: Start OMP from Windows Zed

- **WHEN** Windows Zed starts its configured OMP agent server for a NixOS/WSL workspace
- **THEN** Zed's native WSL remote server invokes the wrapped `omp acp` command with an absolute Linux working directory
- **AND** no explicit local `wsl.exe` bridge, native Windows OMP executable, or compatibility path is required

### Requirement: Explicit platform OMP updates

OMP executable updates SHALL remain explicit operations outside Nix activation. Darwin SHALL support `omp update` through the default wrapper and delegate installation to the official Homebrew formula. The update SHALL NOT replace the Homebrew executable through standalone binary installation. NixOS/WSL SHALL support `omp update` through the default wrapper to update its fixed user-local executable with the upstream binary updater. Each update path SHALL install an official prebuilt release and SHALL NOT build OMP from source. The official WSL installer SHALL remain the bootstrap and pinned recovery path.

#### Scenario: Update OMP on Darwin

- **WHEN** the operator runs `omp update` through the default Darwin wrapper
- **THEN** the upstream updater selects Homebrew ownership rather than the Nix wrapper or standalone binary replacement
- **AND** Homebrew performs the official formula upgrade without a repository change or Nix generation
- **AND** the wrapper preserves update arguments and exit status without session plugin arguments
- **AND** the Nix-managed wrapper invokes the Homebrew-owned executable afterward

#### Scenario: Update OMP in WSL

- **WHEN** the operator runs `omp update` through the default WSL wrapper
- **THEN** the upstream updater targets the configured writable executable rather than the Nix wrapper
- **AND** the update needs no repository change or Nix generation
- **AND** the wrapper preserves the original update arguments and exit status without adding session plugin arguments

#### Scenario: Preserve normal command resolution

- **WHEN** a normal OMP session on either supported platform starts after update routing is available
- **THEN** the immutable personal plugin and language tools remain enabled
- **AND** nested `omp` commands continue to resolve to the Nix wrapper
- **AND** an argument containing `update` outside the leading subcommand does not select update routing

#### Scenario: Unavailable Homebrew formula

- **WHEN** the Darwin update invocation cannot resolve the official Homebrew formula prefix
- **THEN** it fails without modifying the executable
- **AND** it does not fall back to standalone binary replacement

#### Scenario: Missing WSL executable

- **WHEN** the operator runs `omp update` without the configured standalone executable installed
- **THEN** the wrapper reports the existing actionable installation error
- **AND** it does not invoke a fallback executable or install OMP automatically
