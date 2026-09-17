## Why

Ferdium is a Windows desktop communication client, but the rendered Windows configuration does not install it. Installing Ferdium in NixOS would add a WSLg boundary and a second Electron runtime without improving the native Windows tray, notification, credential, link, or media integration.

## What Changes

- Add Ferdium to the rendered Windows application set as the user-scoped WinGet package `Ferdium.Ferdium`.
- Give Ferdium the existing `self-updating` version policy. WinGet installs the latest catalog version when Ferdium is absent or stale, while Ferdium's signed vendor updater can install newer versions without being downgraded by a later configuration run.
- Add a `communication-client` role to the required Windows application set and extend the derived configuration check for that role and policy.
- Keep Ferdium's profile, configured services, credentials, sessions, cache, update preference, and startup preference under application ownership.
- Do not add Ferdium to Korolev's NixOS or Home Manager configuration, and do not add a repository-owned updater, scheduler, startup entry, service configuration, or account authentication.
- Verify the rendered declaration, WinGet desired state, native Windows launch, vendor update setting, absence of repository-owned startup, and preservation of writable user state.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `windows-workstation-layer`: Add native Windows Ferdium installation, explicit self-updating ownership, application-state boundaries, and live acceptance requirements.

## Impact

The change affects `modules/windows/applications.nix`, the derived Windows configuration check and fixtures, the Windows apply procedure, the rendered review files, and Windows acceptance evidence. The Windows user profile gains Ferdium. The NixOS and Darwin configurations remain unchanged.
