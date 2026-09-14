## Why

Zed and Brave update through their signed in-application channels, so exact WinGet pins report healthy newer installations as drift and can request downgrades. The dark-appearance resource also reports drift when Windows stores the declared dark state and wallpaper in its generated `Custom.theme`.

## What Changes

- Classify Zed and Brave as self-updating applications whose vendor channels own updates.
- Make WinGet own their presence and minimum currency through `useLatest: true`, without an exact version.
- Accept an installed vendor-channel version that is newer than WinGet's current catalog version.
- Keep exact reviewed pins for applications and artifacts that have no selected vendor update owner.
- Replace the global explicit-version invariant with validation that requires exactly one declared version policy for each application.
- Validate dark appearance from the user-visible dark-mode, transparency, and wallpaper state instead of the unstable `CurrentTheme` path.
- Remove the dark-theme write that Windows immediately replaces with `Custom.theme`.
- Update the Windows apply procedure and the deferred Windows-check design so they describe both version policies and stable appearance convergence.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `windows-workstation-layer`: distinguish exact-pinned applications from self-updating applications, forbid downgrades of healthy newer installations, and test dark appearance from stable observable state.

## Impact

The change affects `modules/windows/applications.nix`, `modules/windows/default.nix`, `modules/windows/settings.nix`, `packages/windows-configuration-check.py`, the Windows apply procedure, and the deferred `derive-windows-check-from-declaration` artifacts.

It changes no package update schedule. Zed and Brave continue to prompt or update through their existing vendor channels. WinGet remains the installation and repair path when either application is absent or older than its catalog release.

The change unblocks full-document acceptance for `prefer-standard-zed-control-shortcuts`. On 2026-09-14, WinGet `useLatest: true` accepted installed Zed `1.19.2` and Brave `153.1.95.101` as desired, although the Brave catalog offered only `152.1.94.121`.
