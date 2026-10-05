## Why

Korolev's fontconfig knows a single font, DejaVu Sans, and no monospace face. Linux programs that render text themselves therefore fall back to a proportional font: VHS draws aqua's README recordings in a headless Chromium, and OMP's managed browser renders pages and screenshots on this host. The Mac already declares JetBrains Mono for the same kind of use; the Windows side only serves Windows Terminal and is invisible to Linux programs.

## What Changes

- Declare JetBrains Mono as a system font on the WSL host, so fontconfig resolves the family `JetBrains Mono` and the generic `monospace` to it.
- Extend Korolev's evaluation checks to assert the font package.
- Do not change the Mac's fonts, Windows fonts, Windows Terminal, or OMP's browser runtime.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `wsl-host`: The host provides a declared monospace font to Linux programs that render text, such as headless browsers.

## Impact

`modules/roles/nixos/wsl-workstation/`, the Korolev checks in `flake-modules/checks.nix`. Activation adds the font to the system profile and fontconfig configuration; it starts no service and touches no browser profile or cache.
