## Why

OMP's managed Linux Chromium cannot start on `korolev` because the declared `nix-ld` library set lacks the browser's desktop runtime libraries. The browser relay starts, but no compatible Windows browser carries its extension, which prevents authenticated web verification from this workstation.

## What Changes

- Extend the WSL host's declarative `nix-ld` library set with the libraries required by OMP's managed Chromium.
- Keep OMP responsible for its downloaded Chromium, profiles, cache, relay extension, and browser configuration.
- Add a pinned, user-scope Brave installation to the rendered Windows application set for the browser relay only.
- Keep Zen as the declared interactive browser, and prevent Brave from starting automatically.
- Document the one-time manual relay-extension installation because an unpacked extension is browser-owned mutable state.
- Verify the managed headless browser against a real page and the relay against a dedicated authenticated Brave tab.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `personal-omp-workstation`: add declarative WSL support for OMP's managed Chromium and an explicit browser-relay runtime boundary.
- `windows-workstation-layer`: add a pinned browser-relay application without changing the default browser or the existing privilege boundary.

## Impact

The change affects `modules/nixos/programs.nix`, the Windows application declaration and validation, the WSL bootstrap runbook, the architecture decision log, and accepted workstation behavior.

It does not package Chromium through Nix, patch the OMP wrapper, install a distribution package, load the extension during activation, replace Zen, or start Brave at sign-in. The additional Linux libraries and Brave package remain removable through their owning NixOS and WinGet configurations.
