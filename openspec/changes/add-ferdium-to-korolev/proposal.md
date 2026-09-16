## Why

Korolev has WSLg but does not declare Ferdium, so the user cannot reproduce the communication workspace through the NixOS configuration. An imperative or self-updating install would bypass Nix generation review and rollback.

## What Changes

- Install the pinned Nixpkgs Ferdium package in Korolev's Home Manager profile.
- Add a Linux-specific Home Manager module boundary so Ferdium does not enter the Darwin profile or Windows configuration.
- Keep Ferdium's profile, service configuration, account sessions, and cache writable under the user's home directory.
- Keep executable updates under Nix ownership. The existing reviewed Nixpkgs input update flow advances Ferdium; Ferdium does not replace its Nix store executable.
- Do not enable startup, sign in to services, or manage Ferdium's mutable settings during activation.
- Verify the package, desktop entry, WSLg launch, version, mutable-state boundary, and NixOS rollback path.

## Capabilities

### New Capabilities

- `wsl-user-applications`: Declares graphical user applications that Korolev installs through Home Manager and launches through WSLg, including package-update and mutable-state ownership.

### Modified Capabilities

None.

## Impact

The change adds a Linux-specific Home Manager module under `modules/home/nixos/`, updates Korolev's Home Manager imports, and uses focused evaluation checks for platform isolation and Ferdium presence. Korolev's user profile gains Ferdium and its desktop entry. The Mac keeps its Homebrew-managed Ferdium installation unchanged. The Windows configuration remains unchanged.
