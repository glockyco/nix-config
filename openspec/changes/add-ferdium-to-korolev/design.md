## Context

See `proposal.md` for motivation. Korolev imports portable Home Manager modules from `modules/home/`. The Darwin host adds `modules/home/darwin/`, but no Linux-specific user-module boundary exists. Ferdium is already a Homebrew cask on the Mac and must not enter that host through the portable package list.

The pinned Nixpkgs exposes Ferdium `7.1.2` for `x86_64-linux` and `aarch64-linux`. Its derivation repackages the signed upstream Debian artifact and provides a wrapped executable plus desktop resources. A local `x86_64-linux` build succeeded. Korolev currently exposes `WAYLAND_DISPLAY=wayland-0` and `DISPLAY=:0`, so WSLg is the existing graphical transport.

## Goals / Non-Goals

**Goals:**

- Give Korolev one declarative, user-scoped Ferdium installation.
- Preserve platform isolation and Nix generation rollback.
- Preserve Ferdium's writable user profile across activation and rollback.
- Prove the package and desktop entry before activation, then prove a real WSLg launch.

**Non-Goals:**

- Manage Ferdium on the Mac or Windows.
- Pin a Ferdium release independently from Nixpkgs.
- Add an updater, timer, service, desktop environment, or display server.
- Configure services, credentials, recipes, startup, or Ferdium preferences.
- Start Ferdium during NixOS or Home Manager activation.

## Decisions

### 1. Add a Linux-specific Home Manager module boundary

Create `modules/home/nixos/default.nix` and `modules/home/nixos/ferdium.nix`. The NixOS Home Manager integration imports both `../home` and `../home/nixos`. The Darwin integration continues to import `../home` and `../home/darwin`.

This mirrors the established Darwin boundary. It keeps Linux graphical packages out of the portable module list and provides one clear location for future Linux-only user applications.

**Alternative:** Add `pkgs.ferdium` to `modules/home/packages.nix`. Rejected because both hosts import that module, so the Mac would gain a second Ferdium installation beside Homebrew.

**Alternative:** Put the package directly in `hosts/korolev/default.nix`. Rejected because the host file owns identity values. Platform-specific user programs belong beside the existing Home Manager modules.

### 2. Install the unmodified Nixpkgs package

`modules/home/nixos/ferdium.nix` adds only `pkgs.ferdium` to `home.packages`. It does not override the package, copy its desktop file, add command wrappers, or declare mutable application settings.

The package already wraps the upstream application with its runtime libraries and WSLg-compatible display support. A repository-local package would duplicate Nixpkgs maintenance without changing the required behavior.

### 3. Updates follow the Nixpkgs input

Ferdium does not self-update in this design. Its executable and resources live in the immutable Nix store. The central dependency automation can propose a newer Nixpkgs lock, but review and Korolev activation remain required. This is the existing repository update contract and preserves generation rollback.

The application continues to own mutable state under the user's home directory. Nix owns no service definitions, account sessions, cache, or profile files. Rolling the system back changes the executable selection and leaves application state unchanged.

**Alternative:** Install an AppImage or upstream Debian package in a writable user directory. Rejected because it creates a second package manager, bypasses the lock, and makes rollback unable to restore the selected executable.

**Alternative:** Add a timer that checks Ferdium releases. Rejected because the repository already has one Nix dependency-update owner and prohibits a second updater.

### 4. Verification uses the real package and WSLg surface

Before activation, evaluate the two host configurations and build Korolev's Home Manager activation package. Inspect the result for the Ferdium executable and desktop entry. Confirm that the Darwin home package set does not gain the Nixpkgs Ferdium derivation.

After activation, resolve `ferdium` from a fresh Korolev login shell and compare its reported version with `pkgs.ferdium.version`. Launch Ferdium through WSLg and confirm that a usable window opens. Close it, start a new Korolev session, and confirm that no Ferdium process starts automatically. Do not authenticate a service for this acceptance test.

## Risks / Trade-offs

- **A Nixpkgs update can lag an upstream Ferdium release.** The lag preserves review and rollback. An urgent update uses the existing manual Nix input update procedure.
- **A newer executable can migrate the mutable profile.** Retain the previous NixOS generation and back up important application state before an update. Executable rollback does not reverse a profile migration.
- **WSLg behavior depends on the Windows host integration.** The live launch gate detects missing display, audio, or Electron runtime support before acceptance.
- **The package adds a large Electron closure.** The package built successfully, and Nix shares common runtime paths with other applications when hashes match.

## Migration Plan

1. Add the Linux-specific Home Manager module boundary and the Ferdium package declaration.
1. Evaluate both hosts and build Korolev's Home Manager activation package.
1. Run the repository release gates and commit the reviewed change.
1. Activate Korolev from the committed revision.
1. Verify the executable, desktop entry, WSLg launch, version, and absence of automatic startup.

Rollback uses the previous NixOS generation. The user profile remains in place. Remove it only through a separate explicit user action.
