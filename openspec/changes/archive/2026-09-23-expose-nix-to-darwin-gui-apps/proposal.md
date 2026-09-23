## Why

Fork runs Git hooks from a macOS GUI process that cannot find `nix` on its inherited `PATH`. Login-shell configuration does not reach apps started by the user launchd session, so repository hooks fail before their pinned checks run.

## What Changes

- Configure the persistent launchd user-domain `PATH` during Mac activation with the stable host Nix executable directory. The saved setting takes effect after reboot; normal Fork launch behavior after reboot is not verified.
- Preserve standard macOS command directories. Keep per-repository development shells and Git hook checks unchanged.
- Verify the generated activation command and test command resolution with a GUI-like `PATH`.

## Capabilities

### New Capabilities

- `darwin-gui-environment`: The Mac saves a persistent user-domain `PATH` that includes Nix. An explicit-PATH Fork launch can run repository hooks without shell startup files.

### Modified Capabilities

None.

## Impact

The Darwin system declaration saves a persistent user-domain `PATH` for all Mac users. A GUI application can override that PATH; normally launched Fork has not been checked after reboot. Korolev, Windows, project development environments, and repository hooks do not change. The Mac was activated without a reboot.
