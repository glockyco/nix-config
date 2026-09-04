## Why

OMP releases frequently, while the current Nix input can lag behind a release or require a large uncached source build. The workstation needs prompt OMP updates without a repository commit for each release.

## What Changes

- **BREAKING**: Transfer ownership of the OMP executable from the locked Nix package to platform-native mutable installation paths.
- Install OMP from the official `can1357/tap/omp` Homebrew formula on Darwin.
- Install the official prebuilt OMP release at a fixed user-local path in NixOS/WSL.
- Keep the default `omp` command as a Nix-managed wrapper that loads the immutable personal plugin and curated language servers.
- Make the wrapper invoke the platform-owned executable instead of a Nix-store OMP executable.
- Remove the Nix-provided OMP package from installation and verification paths on both hosts.
- Keep Herdr, OpenSpec, the personal plugin, and mutable OMP runtime state under their current owners.
- Accept that Nix generation rollback does not change the platform-managed OMP version.
- Keep the Windows workstation's oh-my-pi agent in NixOS/WSL because Windows development runs inside WSL.
- Keep Zed's Windows agent-server command routed through `wsl.exe` to the wrapped WSL `omp acp` command.
- Do not install a second native Windows OMP executable, Nix fallback, alias, or compatibility path.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `personal-omp-workstation`: Change executable ownership, wrapper resolution, verification, and rollback behavior on Darwin and NixOS/WSL.
- `dependency-update-automation`: Remove OMP releases from Nix-input update ownership and document both platform-native update paths.

## Impact

Affected areas include the Darwin Homebrew module, the personal OMP wrapper, Home Manager and NixOS wiring, WSL bootstrap, package-shape checks, dependency documentation, architecture documentation, and the two modified specifications. The change removes OMP version updates from `flake.lock`; `llm-agents` remains required for Herdr and OpenSpec.
