# Proposal

## Why

After upstream OMP, chezmoi, and a verified native Windows workstation have landed, Korolev no longer needs WSL to be its primary interactive environment. Keep the Linux capabilities Windows does not replace—Nix repository work, remote Darwin builds, rootless containers, and read-only SCCH access—without maintaining a second browser or credential stack.

## What Changes

- Make NixOS-WSL a secondary environment, with NixOS owning system/packages and chezmoi owning user files; retain shell, Git, ordinary CLI tools, `nixd` as a user package, Podman with official Compose, SCCH automount, and Windows `open` interoperability.
- **BREAKING:** Remove WSL managed-browser support, its browser ABI check and `nix-ld` library set; remove `nix-ld` entirely because the other declared consumers (.NET, Unity, and game loaders) are Mac-only by owner decision.
- **BREAKING:** Remove the WSL-to-Windows browser-relay requirement and its WSL operations procedure. Browser automation belongs to the already accepted native Windows environment; do not remove native browser functionality or user profiles.
- **BREAKING:** Remove the Linux JetBrains Mono declaration/check/requirement: the only repository rendering rationale is managed Chromium and hypothetical VHS recordings, with no remaining declared VHS consumer. Windows/Tern fonts remain separately owned.
- Replace Linux GCM/GnuPG/`pass`, the GPG agent/pinentry setup, `GPG_TTY`, and Linux credential-store/provider snippets with a chezmoi-owned WSL Git helper invoking the GCM installed with per-user Git for Windows. Keep credentials in Windows Credential Manager and Windows-owned GCM configuration.
- Delete the superseded unarchived `manage-wsl-git-credentials` change; preserve `mount-scch-share-on-wsl-host` unchanged.
- Trim README, AGENTS.md, and operations guidance to describe native Windows as primary and WSL as secondary, preserving NixOS activation/recovery, builder, SCCH, container, and interop procedures.

## Capabilities

### New Capabilities

None. The secondary-role and Windows-GCM requirements fit the existing `wsl-host` capability; the superseded credential capability was never archived.

### Modified Capabilities

- `wsl-host`: Add the secondary-role and Windows-GCM contracts; extend supported Windows interoperability to HTTPS Git; remove managed-browser compatibility, WSL browser relay, and the unused Linux monospace-font requirement.

## Impact

Implementation targets are the WSL role, Korolev host configuration, chezmoi Git/shell templates and shared host data created by change 2, WSL check registrations in `flake-modules/checks.nix`, `checks/omp-browser-runtime-check.nix`, and existing documentation. `packages/wsl-open` and the SCCH and container declarations/checks remain supported rather than being rewritten.

This is change 4: apply/archive only after `adopt-upstream-omp-and-tern`, `replace-home-manager-with-chezmoi`, and `make-korolev-windows-native` are archived, with a real native Tern session and a WSL-daemon-to-Mac remote build verified in change 3. It does not change tailnet identity/routing, package ownership established by earlier changes, other capability requirements, or mutable browser/GPG/container state. Live credential enrollment, activations, VPN/provider interactions, and publication require their documented owner-assisted boundaries.
