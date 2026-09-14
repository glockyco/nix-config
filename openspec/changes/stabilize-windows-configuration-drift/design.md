## Context

See `proposal.md` for motivation. The Windows renderer currently requires a `version` on every application and emits `useLatest: false`. Zed's and Brave's vendor updaters have already moved them beyond the repository pins. The 2026-09-14 live test found installed Zed `1.19.2` against pin `1.18.0`, and installed Brave `153.1.95.101` against pin `152.1.94.119`.

WinGet's catalog offered Zed `1.19.2` and Brave `152.1.94.121`. A temporary configuration with `useLatest: true` and no `version` reported both installed applications in the desired state. This proves that the resource accepts an installed version newer than its catalog and does not request a downgrade in this case.

The dark-appearance test found all stable declared values in the desired state. Only `CurrentTheme` differed. Windows stored `C:\Users\jglock\AppData\Local\Microsoft\Windows\Themes\Custom.theme`, whose content selected dark application and system modes plus the declared Bloom wallpaper.

## Goals / Non-Goals

**Goals:**

- Give every managed application one explicit and reviewable version policy.
- Let Zed and Brave update promptly through their existing vendor channels.
- Keep WinGet able to install or repair those applications without downgrading newer versions.
- Make the dark-appearance resource converge after Windows creates `Custom.theme`.

**Non-Goals:**

- Add a scheduler or another application updater.
- Change update ownership for Zen, Fork, PowerToys, ReNeo, Windows Terminal, AltSnap, or the terminal font.
- Suppress package or appearance drift without validating the intended state.
- Change the selected dark modes, transparency, or wallpaper.

## Decisions

### Declare a version policy instead of inferring one

Each application gains `versionPolicy`, with exactly two accepted values:

- `exact`: requires `version`; renders that `version` and `useLatest: false`.
- `self-updating`: forbids `version`; renders `useLatest: true`.

Zed and Brave use `self-updating`. Every other application keeps `exact` and its current version. The explicit discriminator makes invalid combinations reviewable and prevents a missing version from silently selecting mutable behavior.

The renderer includes `version` in package properties and metadata only for `exact`. It includes `versionPolicy` in metadata for both classes so the pure check can compare the declaration and rendered document.

Alternative: retain stale informational versions beside `useLatest: true`. Rejected because the WinGet resource defines `version` as a specific target, and two version selectors make ownership unclear.

Alternative: omit both `version` and `useLatest`. Rejected because the resource default is `useLatest: false`, which does not express the required latest-available floor.

### Keep vendor updates outside WinGet scheduling

`useLatest: true` defines desired state only when the operator runs the Windows configuration. It adds no timer and does not compete with in-application prompts. Zed and Brave remain responsible for routine updates. WinGet installs an absent application and repairs one older than its catalog release.

A live test remains necessary because the pure check can prove the rendered policy but cannot compare installed and catalog versions. Acceptance requires a newer vendor-channel installation to pass `winget configure test` without mutation.

### Validate stable appearance values

Remove `CurrentTheme` from the dark-appearance test and set script. Keep these owned values:

- `AppsUseLightTheme = 0`
- `SystemUsesLightTheme = 0`
- `EnableTransparency = 0`
- Bloom wallpaper `img19.jpg`

The active theme path is generated Windows state. Writing `dark.theme` and then setting the wallpaper causes Windows to materialize `Custom.theme`, so the old resource cannot converge. The four retained values state the actual user-visible policy and distinguish a genuine light or wallpaper drift from the generated file-path difference.

### Reconcile the deferred check redesign

`derive-windows-check-from-declaration` currently assumes every application has a version and rejects `useLatest: true`. Update its proposal, design, delta specification, and tasks before implementation. Its future declaration and fixtures must accept both valid policies and reject missing discriminators, conflicting selectors, and policy-specific missing fields.

### Unblock the keymap acceptance only after a clean test

Build both changes in one reviewed repository state. Before apply, require Zed, Brave, and dark appearance to report desired while `zed keymap` reports drift. Apply the complete Windows document as the standard user. The post-apply test must report every resource desired before either change records acceptance.

## Risks / Trade-offs

Zed and Brave builds become time-dependent when WinGet performs an installation. This is deliberate: their signed vendor channels already update independently, and rollback of these applications is not a supported repository property.

A compromised vendor update remains within the trust boundary already accepted for in-application updates. This change adds no updater or source.

A future WinGet resource could change its treatment of installed versions newer than the catalog. The live pre-apply test detects that change before mutation.

Removing `CurrentTheme` ownership permits Windows to select any theme file that produces the declared dark modes, transparency, and wallpaper. Cursor, sound, and icon theme choices were never declared and remain user-owned.
