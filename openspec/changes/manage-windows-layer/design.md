## Context

See `proposal.md` for motivation and `specs/windows-workstation-layer/spec.md` for the contract.

### Verified platform facts

An audit of `korolev` on 2026-09-02 established these facts.

| Fact                | Value                                                                                        |
| ------------------- | -------------------------------------------------------------------------------------------- |
| Device management   | Azure AD joined, AD domain `SCCH`, Intune enrolled                                           |
| Interactive account | `JGlock`, standard user, medium integrity, not in `Administrators`                           |
| Privileged account  | The operator holds durable credentials for the separate local `Administrator` account        |
| DSC                 | `Microsoft.DSC` 3.2.3, installed per user without elevation                                  |
| WinGet              | 1.29.290, sources `msstore`, `winget`, `winget-font`                                         |
| Per-user install    | Verified: a package installed into the interactive user's profile with no elevation prompt   |
| Policy collision    | The elevated policy tree holds no entry for WSL, Windows Terminal, or the developer settings |

### Verified DSC resource set

| Source                     | Resources                                                                                                                                                                                                                                       |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Built in                   | `Microsoft.Windows/Registry`, `/Service`, `/FirewallRuleList`, `/OptionalFeatureList`, `/FeatureOnDemandList`, `/UpdateList`, `/RebootPending`, `Microsoft.DSC/{Group,Include,Assertion}`, `Microsoft.DSC.Transitional/WindowsPowerShellScript` |
| WinGet                     | `Microsoft.WinGet/{Package,Source,AdminSettings,UserSettingsFile}`                                                                                                                                                                              |
| Windows PowerShell adapter | `PSDesiredStateConfiguration/{File,Script,Registry,Archive}`; discovered, but its local execution requires unavailable WS-Management                                                                                                            |

The native Windows PowerShell script resource supports get, set, and test operations. Its get operation hangs under DSC 3.2.3 on the accepted machine, while test and set complete. These resources therefore declare only test and set scripts. They run in the selected security context without the Windows PowerShell adapter or WS-Management.

### Centrally managed applications

Intune deploys or manages updates for `7-Zip`, `Adobe Acrobat Reader`, `draw.io Diagrams`, `Docker Desktop`, `Git for Windows`, `Google Chrome`, `IrfanView`, `Microsoft Visual C++ Redistributable`, `Microsoft Visual Studio Code`, `Mozilla Firefox`, `Notepad++`, `Oracle Java 8`, `Oracle JDK`, `Oracle VirtualBox`, `PuTTY`, and `WinSCP`. Intune wins on the next synchronization, so this layer declares none of them.

## Goals / Non-Goals

**Goals:**

- Give the Windows host one declarative source rendered into a WinGet document and narrow Administrator scripts with the same review path as the Nix hosts.
- Keep every operation in user scope except the official Zen package, Zen policy file, and native Neo keyboard driver.
- Declare each cross-platform setting once, and let each host renderer apply it.
- Make an unpinned or centrally managed application a validation failure.

**Non-Goals:**

- Reproduce the Nix guarantee set on Windows. DSC converges; it does not provide an atomic generation or a rollback.
- Manage Windows updates, drivers, security agents, or any Intune-owned application.
- Apply the document from Nix activation.
- Select the LaTeX previewer. `evaluate-pdf-toolset` owns that decision.

## Decisions

### 1. Use DSC v3 with WinGet Configuration

Express the Windows layer as one Nix declaration that renders a WinGet Configuration document, a Zen policy script, and a native Neo driver script. Apply the document as the interactive user. The official Zen installer performs its own elevation. Apply both scripts from a 64-bit Administrator PowerShell session; restart Windows after the keyboard driver changes.

The live WinGet 1.29.290 CLI recognized `metadata.winget.securityContext: elevated` and displayed its shield but ran a token probe with `admin=False`. The separate Administrator account could not process a second configuration document because DSC 3.2.3 was installed only for the interactive user, and the Administrator account had no Microsoft Store logon session from which to install it. The two companion scripts need no DSC package, refuse a non-administrator token, and own only fixed machine paths for Zen policy and the keyboard layout driver. No interactive-user resource runs from the Administrator profile.

**Alternative:** A hand-written idempotent PowerShell script for the complete layer. Rejected because it reimplements convergence, which is the same category of work that `adopt-nixos-wsl-host` deletes on the Linux side. The companion scripts are limited to the Zen policy path and native keyboard driver registration that the standard-user document cannot own.

**Alternative:** Ansible against Windows. Rejected because it adds a second configuration-management system and a transport for no capability that DSC lacks.

**Alternative:** Chocolatey or Scoop manifests. Rejected because both are manifests over imperative installers with weaker state semantics than DSC.

**Alternative:** Wait for native Nix on Windows. Rejected because official Nix does not support Windows, and the June 2026 native build is a third-party milestone implementation.

### 2. Nix renders and Windows applies

Nix produces the document, the Zen policy and native Neo scripts, and review files. A human applies the document and scripts from Windows. Nix activation never writes across the boundary.

This repository already builds host-specific artifacts for another operating system to consume: `packages/neo-keyboard-layouts.nix` builds a macOS bundle, `modules/home/default-apps.nix` builds an application bundle, and `modules/home/container-runtime.nix` renders YAML with `pkgs.formats.yaml`. Rendering a document for Windows is the same pattern.

A cross-boundary write from Linux activation would race with Windows and would have no rollback on either side.

### 3. Keep explicit machine-scope exceptions for Zen and kbdneo

Elevation on this machine means running as a different account, because the operator's interactive account is a standard user. An elevated process therefore resolves `HKCU`, `%USERPROFILE%`, and `%LOCALAPPDATA%` to the `Administrator` profile. Every user-setting resource must remain unelevated for that reason.

The official Zen WinGet manifest declares machine scope, and the live apply installed it under `C:\Program Files\Zen Browser`. Zen reads Windows enterprise policy from its installation's `distribution\policies.json`, which the standard user cannot write. Mark the Zen package as the only elevated document resource; its official installer requests the administrator credential. Render the policy file into one Administrator script and apply that script separately. Both operations use fixed machine paths and read no administrator-profile environment value.

The native `kbdneo` layout must copy checksum-pinned DLLs into `System32` and `SysWOW64` and register `HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\b0000407`. A second Administrator script owns only those paths, verifies every downloaded payload, and requires a full Windows restart. The interactive-user document then selects input tip `0407:b0000407`. ReNeo stays per user and runs in extension mode to supply the Neo layers that the native driver does not implement.

All other applications are registered to the interactive user and keep their mutable files in that user's profile. Windows Terminal is a per-user AppX registration whose immutable payload resides in the protected `WindowsApps` package store. PowerToys keeps its payload in `%LOCALAPPDATA%` but also creates a hidden machine-wide MSI registration. Neither exception elevates the document resource or creates machine-wide mutable state. Validation rejects every additional elevated document resource, every document-owned machine registry value, and every Windows feature. This keeps the exceptions narrow and reviewable if Intune or Group Policy later claims either path.

**Alternative:** Replace Zen with Vivaldi. Rejected because the operator selected Zen and accepted its narrow privilege exception.

**Alternative:** Use a community portable Zen wrapper. Rejected because it adds an unsupported packaging and update dependency.

### 4. Declare only applications that the device policy does not manage

Validation compares the declared application identifiers against the recorded centrally managed set. A collision fails the check.

Keep the recorded set in the repository as reviewed data, because the Intune policy is readable only with elevation and can change.

### 5. Express Windows settings as named registry values

Use `Microsoft.Windows/Registry` and name every key. This mirrors how `modules/darwin/defaults.nix` names exact preference keys, and it keeps the declaration auditable.

**Alternative:** The community `Microsoft.Windows.Developer` PowerShell resource. Rejected because it needs a gallery module and hides which keys it writes.

Select the built-in Windows dark appearance, the dark Bloom wallpaper, and transparency. Preserve the current standard blue accent by leaving the custom accent-palette binary data untouched. The appearance resource names and tests the exact per-user registry values, applies the wallpaper through `SystemParametersInfo`, and broadcasts the supported setting-change notification.

Declare the disabled state explicitly. `modules/darwin/defaults.nix` records the reason directly: *"Explicitly disable this key: omitting it leaves a previous `true` value."* The same hazard applies to a bundled utility, so the document enables only Command Palette and disables every other module. PowerToys still installs the other utilities because it is one monolithic package. Its settings parser rejects the entire root document when the enabled map contains an unknown module key, so validation requires the exact module-key set from pinned version 0.101.2362.0.

### 6. Separate enforced configuration files from converged ones

Use `Microsoft.DSC.Transitional/WindowsPowerShellScript` to converge the interactive-user files. Declare test and set operations; omit the affected get operation. The resource does not need the Windows PowerShell adapter, and every instance runs without elevation. One Administrator script enforces the complete Zen policy file because the Administrator profile cannot run the per-user DSC processor. The other installs the native Neo driver before the document selects it. PowerToys holds its settings file open, so its set operation stops the user's PowerToys processes, recovers an empty or invalid file, writes the declared values, and restarts PowerToys.

Write every JSON file as UTF-8 without a byte-order mark. PowerToys 0.101 rejects a root settings file with a byte-order mark and silently falls back to its enabled-by-default modules; Zed also reports the mark as an invalid first character.

This distinction already exists on Darwin. `modules/home/darwin/karabiner.nix` copies rather than symlinks because the application rewrites its file, and `modules/home/darwin/zed.nix` keeps `mutableUserSettings = true` so that declared values reapply while interface state survives.

| Class              | Files                                                |
| ------------------ | ---------------------------------------------------- |
| Enforced content   | Zen policies and the pinned Zed and Zen themes       |
| Converged by merge | Windows Terminal, Zed, ReNeo, and PowerToys settings |

Use Catppuccin Mocha with Mauve accents for Zed, Windows Terminal, and Zen. The Zed resource verifies and installs the official theme file from pinned commit `b54cb81708d06912d50e6bb9fd2fd2103b9dda25`. The Terminal resource merges the official Catppuccin Mocha scheme by name and preserves every unrelated built-in or user scheme. The Zen resource installs the three official profile assets from pinned commit `c855685442c6040c4dda9c8d3ddc7b708de1cbaa` and converges the required userstyle preference in each profile's `user.js`. This keeps the profile setting in user scope and preserves unrelated preferences.

**Alternative:** Use the adapted `PSDesiredStateConfiguration/File` and `/Script` resources. Rejected after the live dry run failed because the adapter tried to connect through unavailable WS-Management. Enabling that machine service would need administration and violate the user-scope boundary.

**Alternative:** Enforce every file. Rejected because it would revert generated profile identifiers and interface state on every apply, and would fight the application forever.

**Alternative:** `Microsoft.DSC.Transitional/RunCommandOnSet`. Rejected because a run-only command provides no test operation.

### 7. Application selection

The operator confirmed each role. The rejected options are recorded so that the choice is not repeated.

| Role                          | Selected                                | Rejected, and why                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| ----------------------------- | --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Editor                        | Zed, from the Windows package manager   | The nixpkgs package would reverse the recorded decision that Zed follows its vendor updater. Zed on Windows runs its remote server under `wsl.exe`, so language servers stay in the Linux closure and no SSH server is needed. The Windows settings select `nixd` from `PATH` and disable `nil`; the NixOS system closure provides `nixd` outside repository development shells. Zed propagates extensions with `wsl.exe --exec cp`; the WSL module therefore exposes the NixOS `cp` binary at `/bin/cp`, which is on that non-login invocation's fixed PATH. |
| Browser                       | Zen                                     | —                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| Git client                    | Fork                                    | Windows Git over `\\wsl.localhost` took 723 ms median for `git status` on this repository, against 4.3 ms inside WSL. The pinned `wslgit` bridge lowers the median to 409 ms by running Git in NixOS. The remaining per-command WSL process cost is accepted to retain Fork against the real worktree.                                                                                                                                                                                                                                                        |
| Launcher and window switching | PowerToys, with Command Palette enabled | Flow Launcher needs a community plugin for window switching, and its plugin manager installs outside the declarative layer. PowerToys provides launching, window switching, and a calculator in the pinned package.                                                                                                                                                                                                                                                                                                                                           |
| Mouse window move and resize  | AltSnap                                 | PowerToys Grab And Move handles modifier-dragging but does not activate edge snapping. AltSnap owns both modifier-dragging and 50/50 edge or corner snapping, while Grab And Move and FancyZones remain disabled to avoid overlapping owners.                                                                                                                                                                                                                                                                                                                 |
| Neo2 keyboard layout          | Native `kbdneo` plus ReNeo              | The native driver covers sign-in, UAC, and elevated windows. ReNeo installs per user in extension mode and supplies the higher Neo layers that `kbdneo` omits.                                                                                                                                                                                                                                                                                                                                                                                                |
| Terminal                      | Windows Terminal                        | Ghostty publishes no Windows build. WezTerm's package-manager release is from February 2024 and its WSL integration is manual. Alacritty offers no tabs and no WSL profile concept.                                                                                                                                                                                                                                                                                                                                                                           |
| Terminal font                 | JetBrainsMono Nerd Font                 | Same face as the Darwin host. Install four faces from the checksum-pinned upstream archive because the only WinGet package self-elevates. Windows exposes the archive's embedded family name as `JetBrainsMonoNL NF`; Terminal and Zed must use that name.                                                                                                                                                                                                                                                                                                    |

### 8. Declare no taskbar pinned-application list

Windows provides no supported per-user mechanism. The pinned list is an opaque serialized value, and the supported route is a policy-applied layout file that applies at first sign-in.

The Darwin configuration also makes this a small loss. `modules/darwin/defaults.nix` records that the Dock list is *"credentials, chat, terminal, browser, editor, documents, version control, tasks"* and then states that *"nothing here is launched from the Dock."* The launcher performs the launching on both hosts. The operator also removed five of those nine applications from this host.

Keep the taskbar visible. The live auto-hide check behaved inconsistently, and the operator chose not to debug that opaque binary state. Visibility still lives inside a binary value rather than a discrete value, so express it with a script resource that sets and tests only that flag.

### 9. Declare no file associations

Windows protects the per-extension default handler with a hash, so no supported interface sets it for an existing profile. The provisioning-time import applies only to profiles created later, and the operator rejected that mechanism as disproportionate.

The operator performs a manual one-time pass. The Darwin list holds 153 extensions because `duti` made each binding free; on Windows each binding costs a confirmation, so the useful set is far smaller.

**Alternative:** Reproduce the protection hash with a third-party tool. Rejected because the interface is unsupported and has broken across Windows updates.

### 10. Keep Night Light manual

Windows stores Night Light state, schedule, strength, and timestamps in opaque `CloudStore` binary payloads. No supported per-user API exposes those values. Rewriting the payload would couple the repository to an undocumented format that Windows mutates, so the document must not own it.

The operator enabled Night Light, selected sunset-to-sunrise scheduling, and kept 50% strength through Settings. Record that one-time state in the runbook.

### 11. Share cross-platform settings through one expression

Add `modules/shared/` for platform-free data that more than one renderer consumes. The Zed settings and the Zen policies belong there. Home Manager consumes them on Darwin, and the Windows renderer consumes the same values.

Without this, the same settings would exist twice, which is the outcome this change exists to avoid.

## Risks / Trade-offs

- **DSC converges and offers no rollback.** → State the weaker guarantee in the runbook. Preview with the dry-run operation before the first apply, and confirm with the test operation afterwards.
- **An Intune policy later claims a declared application.** → Validation compares against recorded data, so the collision appears in review. Keep the recorded set reviewable and dated.
- **A converged configuration file drifts silently.** → The test operation reports the declared values, so a scheduled manual check finds drift.
- **The native driver does not implement every higher Neo layer.** → Keep ReNeo in extension mode for ordinary windows. Verify the native base layout separately in UAC or another elevated surface after the required restart.
- **The Windows Terminal profile identifier changes with the distribution name.** → `adopt-nixos-wsl-host` establishes the name first. Prove the profile before the old distribution is removed.
- **Fork remains slower than on Darwin.** → Measured and accepted. Zed's Git panel and a terminal Git client both run inside WSL at native speed for routine work.

## Migration Plan

1. Complete `adopt-nixos-wsl-host`, which fixes the NixOS distribution name.
1. Add `modules/shared/` and move the Zed settings and Zen policies into it, keeping Darwin values identical.
1. Add `modules/windows/` and render the document and its referenced files.
1. Add the repository validation for document structure, version pins, and managed-application collisions.
1. Preview the document on `korolev` with the dry-run operation.
1. Apply it, then confirm with the test operation.
1. Verify each role by use: editor with a WSL project, browser, Git client, launcher and window switching, mouse move and resize, Neo2 layout, terminal profile.
1. Record the manual file-association pass and the applied document revision in the runbook.

Rollback is a document revision plus a reapply. The layer starts no service and holds no state that another system depends on.

## Open Questions

- The exact command that the Zed agent-server setting uses for `omp acp` on Windows. The Darwin value is an absolute store path, and the Windows value must reach `omp` inside WSL. The setting exists either way, so the answer changes one value rather than the approach.
