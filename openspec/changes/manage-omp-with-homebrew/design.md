## Context

Darwin and NixOS/WSL currently receive OMP, Herdr, and OpenSpec from one locked `llm-agents` input. The Nix-managed wrapper embeds the OMP store path and personal plugin store path. Homebrew already owns mutable vendor applications on Darwin. The official oh-my-pi installer supports prebuilt Linux binaries at a caller-selected directory.

The Windows layer runs development tools inside NixOS/WSL. Its Zed agent server invokes `wsl.exe --distribution NixOS --cd ~ -- omp acp`; it does not need a native Windows OMP installation.

See `proposal.md` for motivation and the delta specifications for observable behavior.

## Goals / Non-Goals

**Goals:**

- Keep one `omp` command and one wrapper implementation across supported hosts.
- Remove the Nix OMP package and version pin from both host closures.
- Preserve immutable plugin loading, curated language servers, Herdr reconciliation, and runtime state.
- Let explicit platform-native commands update OMP without a repository change.
- Keep the Windows Zed integration on the wrapped NixOS/WSL command.

**Non-Goals:**

- Automatic OMP upgrades during Nix activation.
- An OMP-specific updater, Nix fallback, compatibility alias, or mutable plugin installation.
- A duplicate native Windows OMP executable.
- Changes to OMP authentication, preferences, sessions, history, caches, or databases.

## Decisions

### Use official prebuilt distribution paths on both hosts

Declare `can1357/tap/omp` through the existing Darwin Homebrew module. Keep `homebrew.onActivation.upgrade = false`, so activation installs a missing formula but an explicit `brew upgrade omp` updates it.

In NixOS/WSL, use the official installer in `--binary` mode with `PI_INSTALL_DIR` set to one dedicated user-local directory. The bootstrap runbook owns the initial install and repeatable update command. Nix activation does not download or replace the binary.

Source installation through Bun was rejected because OMP publishes host binaries and the change exists partly to avoid large source builds. Linuxbrew was rejected because it would add a package manager only for OMP. A repository-owned downloader was rejected because it would duplicate the official installer.

### Parameterize the wrapper by runtime executable path

Make the wrapper accept a runtime executable path instead of an OMP package object. Darwin passes `/opt/homebrew/bin/omp`. NixOS/WSL passes a fixed path below the interactive user's home directory. The wrapper continues to embed the plugin store path and add only curated language servers to `PATH`.

The WSL path must not be `~/.local/bin/omp`, because the Nix-managed wrapper also provides the public `omp` command. A dedicated directory prevents path-order dependence and recursion. On Darwin, nix-homebrew prepends its prefix during system shell initialization, so the user shell must put the Home Manager profile first again. The wrapper still invokes Homebrew through its explicit absolute path.

A separate wrapper per host was rejected because it would duplicate plugin flags, language-server composition, and verification behavior. A generic `PATH` lookup was rejected because it could recurse into the wrapper or select an unintended installation.

### Keep one executable owner per host

Remove OMP package installation and references to `upstreamOmp` on both hosts. Keep `llm-agents` because it still provides Herdr and OpenSpec. Do not retain a fallback, alias, version shim, or native Windows installation.

The Windows Zed configuration continues to invoke `omp acp` inside NixOS/WSL. This gives the Windows editor the same wrapper, plugin, policy, tools, and mutable OMP state as terminal sessions in WSL.

A fallback was rejected because it would hide an incomplete platform installation and make the active OMP version depend on path or failure conditions.

### Verify explicitly instead of during Nix activation

Install `verify-personal-omp` beside the wrapper. The command checks that the expected platform executable exists and starts with the immutable plugin and LSP configuration. It reports the observed version. Operators run it after an OMP update and after Nix activation.

Nix activation continues to reconcile Herdr but does not invoke OMP. This lets a fresh WSL image activate before its user-local binary exists and keeps Nix activation independent of mutable executable state. A conditional activation check was rejected because absence would only produce a warning and create two verification modes.

Package-shape checks use an explicit stub executable and do not require Homebrew or mutable user state inside a Nix sandbox. An exact OMP version assertion was rejected because the platform installer owns version selection after this cutover.

### Keep OMP updates explicit

The operations documentation provides one update command and one previous-release recovery command per host. Neither `darwin-switch` nor `nixos-rebuild` updates OMP. After an OMP update, deterministic verification and the real wrapped-session smoke remain the acceptance path.

An activation-time update was rejected because it would mix mutable executable changes with Nix generation activation and weaken failure isolation.

### Separate Nix rollback from OMP recovery

Nix rollback restores the wrapper, plugin, Herdr, OpenSpec, and language servers. It does not change the platform-owned OMP binary. Failed OMP releases are recovered through Homebrew on Darwin or the official installer with an explicit release tag in WSL.

## Risks / Trade-offs

- [An OMP release can be incompatible with the pinned plugin.] → Run deterministic verification and the real wrapped-session smoke after updates; recover the previous release through the owning installer.
- [A missing platform binary makes the wrapper unusable.] → Declare the Darwin formula, document the WSL prerequisite, and fail verification with the expected path and install command.
- [Nix rollback no longer restores any OMP executable.] → State the ownership boundary in verification and operations documentation.
- [The upstream Homebrew tap or installer endpoint can be unavailable.] → Existing binaries continue to run; bootstrap fails instead of selecting a hidden Nix fallback.
- [A mutable executable weakens full-generation reproducibility.] → Keep all personal behavior in the immutable wrapper and plugin, and make the accepted trade-off explicit.

## Migration Plan

1. Add the official tap and formula to the Darwin Homebrew declaration.
1. Select and document the dedicated WSL user-local OMP directory.
1. Make the shared wrapper and verifier accept an explicit runtime executable path.
1. Pass the Homebrew path on Darwin and the dedicated user-local path on NixOS/WSL.
1. Remove all OMP package installation, `upstreamOmp` passthrough values, and obsolete version assertions.
1. Preserve the Windows Zed `wsl.exe` route to the wrapped WSL `omp acp` command.
1. Update deterministic checks, accepted specifications, architecture, and operations documentation.
1. Run formatting, strict OpenSpec validation, flake checks, Darwin build-plan checks, and both host builds.
1. After review and merge, install the platform binary, activate each host, run deterministic verification, and run the real wrapped-session smoke.

Roll back the code change with the previous Nix generation. If only an OMP release fails, recover the previous release through the owning platform installer and rerun verification.
