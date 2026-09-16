## Context

See `proposal.md` for motivation. The Windows renderer builds WinGet package resources from `modules/windows/applications.nix`. Each application has one role, source, scope, and version policy. `self-updating` packages omit an exact version and render `useLatest: true`; the configuration accepts an installed version newer than the WinGet catalog instead of downgrading it.

WinGet currently exposes `Ferdium.Ferdium` 7.2.3 as a Nullsoft `AutoSetup` installer for x64 Windows. Ferdium's upstream defaults enable `automaticUpdates` and disable `autoLaunchOnStart`. The application stores those preferences with its other writable profile state. The existing repository renderer can install Ferdium without adding a settings resource or new package mechanism.

## Goals / Non-Goals

**Goals:**

- Install one native, user-scoped Ferdium package through the existing Windows application declaration.
- Let Ferdium's vendor updater own routine executable updates while WinGet owns installation, repair, and the latest-catalog floor.
- Preserve the existing role, privilege, and version-policy validation model.
- Preserve application-owned profile state and preferences across configuration runs.
- Prove native launch, update preference, startup preference, and configuration convergence on Windows.

**Non-Goals:**

- Install or launch Ferdium through WSLg.
- Manage Ferdium services, accounts, credentials, sessions, cache, theme, update preference, or startup preference.
- Add a repository updater, timer, service, startup entry, or scheduled apply.
- Promise executable rollback after a vendor update.
- Install Ferdium on the Mac; its existing Homebrew declaration remains unchanged.

## Decisions

### Add Ferdium to the existing application declaration

Add one entry to `modules/windows/applications.nix`:

- name: `Ferdium`
- role: `communication-client`
- id: `Ferdium.Ferdium`
- version policy: `self-updating`
- source: `winget`
- scope: `user`

Add `communication-client` to the renderer's expected role set. The existing package renderer then emits a normal `Microsoft.WinGet/Package` resource with `useLatest: true`, no exact version, and no elevation request.

Alternative: create a dedicated Ferdium resource or installer script. Rejected because the generic application declaration already represents the required package behavior and privilege boundary.

Alternative: exact-pin the current WinGet version. Rejected because Ferdium enables its vendor updater by default. An exact pin would report healthy newer installations as drift and could request a downgrade, which repeats the problem already corrected for Zed and Brave.

### Extend role-based policy validation

Add `communication-client` to `EXPECTED_ROLES` and `SELF_UPDATING_ROLES` in the derived Windows check. Update valid and rejection fixtures so the check requires exactly one communication client, requires the self-updating selector combination, rejects elevation, and rejects a centrally managed duplicate.

Do not add a Ferdium-specific exception to the generic renderer. The identifier check belongs in policy validation because the role contract requires `Ferdium.Ferdium`, as the browser-relay contract requires Brave.

### Leave writable Ferdium state application-owned

Do not add a file, registry, script, or DSC resource for Ferdium settings. On a fresh profile, the application supplies `automaticUpdates = true` and `autoLaunchOnStart = false`. On an existing profile, the application preserves the user's values.

This boundary prevents activation from handling credentials or sessions and avoids overwriting later user choices. The configuration guarantees that Ferdium is eligible to update itself; it does not continually force the update preference on.

Alternative: render Ferdium's settings file to force updates on and startup off. Rejected because the file also belongs to a mutable application profile, and convergence would overwrite user-owned state.

### Use native Windows acceptance evidence

Build a fresh reviewed Windows artifact. Before apply, run the pure configuration check and `winget configure test` as the standard user. Apply the complete document as that user, then require a clean post-apply test.

Launch Ferdium without authenticating a service. In the application UI, confirm the automatic-update preference is enabled and launch-at-sign-in is disabled for the fresh profile. Confirm the process is a native Windows executable, close it, restart or sign out as needed, and confirm it does not start automatically. Record the installed and catalog versions, executable path, package scope, UI observations, apply revision, and post-apply result in `evidence.md`.

## Risks / Trade-offs

- A vendor update can move Ferdium beyond the reviewed WinGet catalog version. This is deliberate for a self-updating application; the Windows configuration accepts the newer version and does not provide rollback.
- A future Ferdium release can change its fresh-profile update or startup defaults. The live UI acceptance check detects that change before the plan is accepted. Existing user preferences remain user-owned.
- The upstream Nullsoft manifest does not declare an installer scope. The repository declaration records user scope and requests no elevation; live installation evidence must confirm that WinGet installs the executable in the interactive user's profile.
- Removing the declaration does not uninstall Ferdium or delete its profile. Windows configuration has no generation rollback, so removal remains a separate explicit operation.
