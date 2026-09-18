## Why

Korolev has no reliable command that opens a Linux directory, file, or URI in the Windows graphical desktop. macOS already provides `open`. Native Windows configuration is a separate workstation concern.

## What Changes

- Add a Nix-managed `open [target]` command to Korolev.
- Translate existing Linux paths and delegate graphical opening directly to the Windows shell without `wslu`, WSLg, or command-shell quoting.
- Define behavior for an omitted target, one file or directory, one absolute URI, paths with spaces, invalid targets, and unavailable WSL interoperation.
- Verify actual graphical dispatch through Korolev's Windows desktop boundary.
- Leave macOS and native Windows PowerShell unchanged.

## Capabilities

### New Capabilities

- `cross-platform-open-command`: Defines Korolev's `open` interface and its WSL-to-Windows dispatch, error, ownership, and activation boundaries.

### Modified Capabilities

None.

## Impact

- Affects the Korolev user command set, its evaluated checks, and the NixOS/WSL module that owns Windows interoperation.
- Leaves `/usr/bin/open`, the macOS closure, and the rendered Windows configuration unchanged.
- Adds no external package or updater. In particular, it does not restore the discontinued `wslu` project.
- Native Windows baseline convergence remains owned by the Windows workstation specifications.
