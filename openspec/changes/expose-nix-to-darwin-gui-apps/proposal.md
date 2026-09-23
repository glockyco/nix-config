## Why

Fork runs Git hooks from a macOS GUI process that cannot find `nix` on its inherited `PATH`. Login-shell configuration does not reach apps started by the user launchd session, so repository hooks fail before their pinned checks run.

## What Changes

- Configure the persistent launchd user-domain `PATH` during Mac activation so GUI processes can find the stable host Nix executable after reboot.
- Preserve standard macOS command directories. Keep per-repository development shells and Git hook checks unchanged.
- Verify the generated activation command and test command resolution with a GUI-like `PATH`.

## Capabilities

### New Capabilities

- `darwin-gui-environment`: The Mac persistently exposes Nix to GUI-launched user processes without depending on shell startup files.

### Modified Capabilities

None.

## Impact

The Darwin system declaration sets the persistent user-domain `PATH` for all Mac users. Fork and other GUI applications started after activation and reboot inherit it. Korolev, Windows, project development environments, and repository hooks do not change. Activation and reboot remain separately reviewed host operations.
