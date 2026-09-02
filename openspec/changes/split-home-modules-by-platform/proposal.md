## Why

`modules/home/` holds 26 user-scope modules, and nix-darwin is their only consumer. 14 of those modules depend on macOS interfaces such as `launchd`, LaunchServices, `~/Library`, and `darwin-rebuild`. The directory declares no platform boundary, so a second host cannot select the portable modules alone.

This change creates that boundary. It is the prerequisite for any Linux user-scope configuration, and it changes no built output.

## What Changes

- Group `modules/home/` into a portable set and a `darwin/` subdirectory.
- Move the Git identity from the portable Git module to host scope.
- Replace the hard-coded editor in the GitHub CLI module with a host-supplied variable.
- Extend the `moduleImports` check to nested module directories.
- Record the portable and Darwin-only classification in `README.md`.

The built Darwin system SHALL keep an identical store path. That equality is the acceptance gate.

## Capabilities

### New Capabilities

None. This change relocates files and adds no observable behavior.

### Modified Capabilities

None. No accepted requirement describes the module layout or the module-import check.

## Impact

The change affects `modules/home/`, `modules/darwin/home-manager.nix`, `hosts/macbook-pro/default.nix`, the `moduleImports` check in `flake.nix`, and `README.md`.

It does not change the OMP package, the personal plugin, the active Nix generation, the WSL profile entry, or any user-visible command.
