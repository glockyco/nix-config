## Context

See `proposal.md` for motivation and `specs/windows-workstation-layer/spec.md` for the contract.

### Verified platform facts

An audit of `korolev` on 2026-09-02 established these facts.

| Fact                | Value                                                                                        |
| ------------------- | -------------------------------------------------------------------------------------------- |
| Device management   | Azure AD joined, AD domain `SCCH`, Intune enrolled                                           |
| Interactive account | `JGlock`, standard user, medium integrity, not in `Administrators`                           |
| Privileged account  | The operator holds durable credentials for the separate local `Administrator` account        |
| DSC                 | `Microsoft.DSC` 3.2.2, installed per user without elevation                                  |
| WinGet              | 1.29.290, sources `msstore`, `winget`, `winget-font`                                         |
| Per-user install    | Verified: a package installed into the interactive user's profile with no elevation prompt   |
| Policy collision    | The elevated policy tree holds no entry for WSL, Windows Terminal, or the developer settings |

### Verified DSC resource set

| Source                     | Resources                                                                                                                                                                                 |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Built in                   | `Microsoft.Windows/Registry`, `/Service`, `/FirewallRuleList`, `/OptionalFeatureList`, `/FeatureOnDemandList`, `/UpdateList`, `/RebootPending`, `Microsoft.DSC/{Group,Include,Assertion}` |
| WinGet                     | `Microsoft.WinGet/{Package,Source,AdminSettings,UserSettingsFile}`                                                                                                                        |
| Windows PowerShell adapter | `PSDesiredStateConfiguration/{File,Script,Registry,Archive}`                                                                                                                              |

DSC v3 provides no built-in file resource. The in-box Windows PowerShell adapter provides one, so file management needs no gallery module.

### Centrally managed applications

Intune deploys or manages updates for `7-Zip`, `Adobe Acrobat Reader`, `draw.io Diagrams`, `Docker Desktop`, `Git for Windows`, `Google Chrome`, `IrfanView`, `Microsoft Visual C++ Redistributable`, `Microsoft Visual Studio Code`, `Mozilla Firefox`, `Notepad++`, `Oracle Java 8`, `Oracle JDK`, `Oracle VirtualBox`, `PuTTY`, and `WinSCP`. Intune wins on the next synchronization, so this layer declares none of them.

## Goals / Non-Goals

**Goals:**

- Give the Windows host one declarative document with the same review path as the Nix hosts.
- Keep the document appliable by a standard user.
- Declare each cross-platform setting once, and let each host renderer apply it.
- Make an unpinned or centrally managed application a validation failure.

**Non-Goals:**

- Reproduce the Nix guarantee set on Windows. DSC converges; it does not provide an atomic generation or a rollback.
- Manage Windows updates, drivers, security agents, or any Intune-owned application.
- Apply the document from Nix activation.
- Select the LaTeX previewer. `evaluate-pdf-toolset` owns that decision.

## Decisions

### 1. Use DSC v3 with WinGet Configuration

Express the Windows layer as one WinGet Configuration document and apply it with `winget configure`.

**Alternative:** A hand-written idempotent PowerShell script. Rejected because it reimplements convergence, which is the same category of work that `adopt-nixos-wsl-host` deletes on the Linux side.

**Alternative:** Ansible against Windows. Rejected because it adds a second configuration-management system and a transport for no capability that DSC lacks.

**Alternative:** Chocolatey or Scoop manifests. Rejected because both are manifests over imperative installers with weaker state semantics than DSC.

**Alternative:** Wait for native Nix on Windows. Rejected because official Nix does not support Windows, and the June 2026 native build is a third-party milestone implementation.

### 2. Nix renders and Windows applies

Nix produces the document and the configuration files it references. A human applies it from Windows. Nix activation never writes across the boundary.

This repository already builds host-specific artifacts for another operating system to consume: `packages/neo-keyboard-layouts.nix` builds a macOS bundle, `modules/home/default-apps.nix` builds an application bundle, and `modules/home/container-runtime.nix` renders YAML with `pkgs.formats.yaml`. Rendering a document for Windows is the same pattern.

A cross-boundary write from Linux activation would race with Windows and would have no rollback on either side.

### 3. Declare user scope only, although the operator holds administrator credentials

Elevation on this machine means running as a different account, because the operator's interactive account is a standard user. An elevated process therefore resolves `HKCU`, `%USERPROFILE%`, and `%LOCALAPPDATA%` to the `Administrator` profile. Every item in this layer is user scope, so an elevated apply would write to the wrong profile.

Two further reasons hold independently. Intune and Group Policy reassert machine-scope settings on their next synchronization, so a machine-scope declaration that collides with policy is a claim with an expiry. And a user-scope document remains valid on any corporate Windows machine, which keeps the repository useful after a rebuild.

**Alternative:** Use the administrator credential to declare machine scope. Rejected for the three reasons above.

### 4. Declare only applications that the device policy does not manage

Validation compares the declared application identifiers against the recorded centrally managed set. A collision fails the check.

Keep the recorded set in the repository as reviewed data, because the Intune policy is readable only with elevation and can change.

### 5. Express Windows settings as named registry values

Use `Microsoft.Windows/Registry` and name every key. This mirrors how `modules/darwin/defaults.nix` names exact preference keys, and it keeps the declaration auditable.

**Alternative:** The community `Microsoft.Windows.Developer` PowerShell resource. Rejected because it needs a gallery module and hides which keys it writes.

Declare the disabled state explicitly. `modules/darwin/defaults.nix` records the reason directly: *"Explicitly disable this key: omitting it leaves a previous `true` value."* The same hazard applies to a bundled utility, so the document declares one enabled module and every other module as disabled.

### 6. Separate enforced configuration files from converged ones

An application that does not rewrite its configuration gets a `PSDesiredStateConfiguration/File` resource with a checksum, which enforces the complete content. An application that rewrites its configuration gets a `PSDesiredStateConfiguration/Script` resource that sets the declared values and preserves the rest.

This distinction already exists on Darwin. `modules/home/karabiner.nix` copies rather than symlinks because the application rewrites its file, and `modules/home/zed.nix` keeps `mutableUserSettings = true` so that declared values reapply while interface state survives.

| Class                | Files                                                       |
| -------------------- | ----------------------------------------------------------- |
| Enforced by checksum | AltSnap configuration                                       |
| Converged by merge   | Windows Terminal settings, Zed settings, PowerToys settings |

**Alternative:** Enforce every file. Rejected because it would revert generated profile identifiers and interface state on every apply, and would fight the application forever.

**Alternative:** `Microsoft.DSC.Transitional/RunCommandOnSet`. Rejected because the resource name states that it is transitional, and a copy command provides no test operation.

### 7. Application selection

The operator confirmed each role. The rejected options are recorded so that the choice is not repeated.

| Role                          | Selected                                | Rejected, and why                                                                                                                                                                                                              |
| ----------------------------- | --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Editor                        | Zed, from the Windows package manager   | The nixpkgs package would reverse the recorded decision that Zed follows its vendor updater. Zed on Windows runs its remote server under `wsl.exe`, so language servers stay in the Linux closure and no SSH server is needed. |
| Browser                       | Zen                                     | —                                                                                                                                                                                                                              |
| Git client                    | Fork                                    | Measured cost of the `\\wsl.localhost` path: 0.165 ms per file against 0.021 ms native, about eight times, plus a fixed connection cost near 0.6 s. Acceptable.                                                                |
| Launcher and window switching | PowerToys, with Command Palette enabled | Flow Launcher needs a community plugin for window switching, and its plugin manager installs outside the declarative layer. PowerToys provides launching, window switching, and a calculator in the pinned package.            |
| Mouse window move and resize  | AltSnap                                 | PowerToys FancyZones needs the title bar and predefined zones. komorebi and GlazeWM are keyboard-driven tiling managers, which the operator does not use. AquaSnap is proprietary and carries licence state.                   |
| Neo2 keyboard layout          | ReNeo, Neo2 variant                     | The `kbdneo` layout driver needs administrator rights and a machine-scope registration. ReNeo installs per user.                                                                                                               |
| Terminal                      | Windows Terminal                        | Ghostty publishes no Windows build. WezTerm's package-manager release is from February 2024 and its WSL integration is manual. Alacritty offers no tabs and no WSL profile concept.                                            |
| Terminal font                 | JetBrainsMono Nerd Font                 | Same face as the Darwin host.                                                                                                                                                                                                  |

### 8. Declare no taskbar pinned-application list

Windows provides no supported per-user mechanism. The pinned list is an opaque serialized value, and the supported route is a policy-applied layout file that applies at first sign-in.

The Darwin configuration also makes this a small loss. `modules/darwin/defaults.nix` records that the Dock list is *"credentials, chat, terminal, browser, editor, documents, version control, tasks"* and then states that *"nothing here is launched from the Dock."* The launcher performs the launching on both hosts. The operator also removed five of those nine applications from this host.

Declare taskbar auto-hide instead, which matches `dock.autohide = true` on Darwin. Auto-hide lives inside a binary value rather than a discrete value, so express it with a `Script` resource that reads, sets, and tests that one flag.

### 9. Declare no file associations

Windows protects the per-extension default handler with a hash, so no supported interface sets it for an existing profile. The provisioning-time import applies only to profiles created later, and the operator rejected that mechanism as disproportionate.

The operator performs a manual one-time pass. The Darwin list holds 153 extensions because `duti` made each binding free; on Windows each binding costs a confirmation, so the useful set is far smaller.

**Alternative:** Reproduce the protection hash with a third-party tool. Rejected because the interface is unsupported and has broken across Windows updates.

### 10. Share cross-platform settings through one expression

Add `modules/shared/` for platform-free data that more than one renderer consumes. The Zed settings and the Zen policies belong there. Home Manager consumes them on Darwin, and the Windows renderer consumes the same values.

Without this, the same settings would exist twice, which is the outcome this change exists to avoid.

## Risks / Trade-offs

- **DSC converges and offers no rollback.** → State the weaker guarantee in the runbook. Preview with the dry-run operation before the first apply, and confirm with the test operation afterwards.
- **An Intune policy later claims a declared application.** → Validation compares against recorded data, so the collision appears in review. Keep the recorded set reviewable and dated.
- **A converged configuration file drifts silently.** → The test operation reports the declared values, so a scheduled manual check finds drift.
- **ReNeo cannot inject into an elevated window.** → Verify during implementation. If the limitation matters, the `kbdneo` driver remains available as a separate one-time privileged step, which the operator can perform.
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
