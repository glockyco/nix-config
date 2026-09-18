## Why

The workstations do not provide one reliable command that opens a directory, file, or URI in the graphical desktop. macOS provides `open`, but Korolev has no Windows-aware opener, and native PowerShell exposes a different command name.

## What Changes

- Provide `open [target]` as the common user command on macOS, NixOS/WSL, and native Windows PowerShell 7.
- Keep the native macOS command unchanged.
- Add a Nix-managed Korolev command that translates Linux paths and delegates graphical opening to the Windows shell without `wslu`, WSLg, or command-shell quoting.
- Add a user-scoped, auto-loading PowerShell 7 module that exposes `open` and delegates native Windows targets to `Start-Process`.
- Define common behavior for an omitted target, one file or directory, one URI, paths with spaces, invalid targets, and unavailable WSL interoperation.
- Verify each implementation through its actual graphical desktop boundary and keep Windows application launch outside Nix activation.

## Capabilities

### New Capabilities

- `cross-platform-open-command`: Defines the common `open` interface and its platform-native dispatch, error, ownership, and activation boundaries.

### Modified Capabilities

None.

## Impact

- Affects the Korolev WSL user command set, its evaluated checks, and the NixOS/WSL role or module that owns Windows integration.
- Affects the rendered Windows configuration, its user-scoped PowerShell 7 module resource, and Windows configuration checks.
- Leaves `/usr/bin/open` and the macOS closure unchanged.
- Adds no external package or updater. In particular, it does not restore the discontinued `wslu` project.
- The implementation must reconcile with the active platform-role and declaration-derived Windows-check changes before editing their shared ownership areas.
