# Tasks

## 1. Korolev declarations

- [x] 1.1 Declare `Obsidian.Obsidian` in `windows/workstation.json` as a user-scope WinGet package with present policy, the `notes` role, `executable` `Obsidian.com` and `directory` `Programs\Obsidian`, and `Gitleaks.Gitleaks` as a user-scope WinGet `zip` package with present policy, the `secret-scanner` role and `executable` `gitleaks.exe`. Add both roles to the required-role map in `windows/Workstation.Validation.ps1`, and verify `pwsh -NoProfile -File .\windows\check-workstation.ps1 -StaticOnly` accepts the declaration.
- [x] 1.2 Declare the current-user Run value `Obsidian` with `"%LOCALAPPDATA%\Programs\Obsidian\Obsidian.exe"` as an `ExpandString`, and verify the static check accepts it.
- [x] 1.3 Write `docs/operations/obsidian.md` with the owner steps on each machine, the skipped registration and the `Obsidian.com` name for callers that resolve commands through `Bun.which`. Add the Obsidian step to the manual steps in `docs/operations/korolev-windows.md` and link the guide from the README, and verify `pwsh -NoProfile -File .\windows\dev\format.ps1 -Check` passes.
- [x] 1.4 Run `pwsh -NoProfile -File .\windows\dev\ci.ps1` and verify the declaration, mocked engine tests and chezmoi fixtures pass.

## 2. Mac declarations

- [x] 2.1 Add a boolean `startAtLogin` with default `false` to Darwin application records in `modules/fleet/host.nix`, with an assertion that names the record when a login start lacks `appPath`, and describe `appPath` as the bundle path for the Dock and the login start. Add the field's default to the shared-facts check in `flake-modules/checks.nix` and a rejection case with a valid control to `checks/host-declaration-check.nix`, and verify the Nix checks evaluate all three.
- [x] 2.2 Add a desktop-role module that derives one launchd user agent per login-start record, running `/usr/bin/open -a <appPath>` with `RunAtLoad` and `LimitLoadToSessionType = "Aqua"`, import it from `modules/roles/darwin/desktop/default.nix`, and verify the Darwin system builds in CI.
- [x] 2.3 Add the `obsidian` application record with `appPath` `/Applications/Obsidian.app`, `startAtLogin = true` and its rationale to `home/.chezmoidata/hosts.toml`, and verify `nix flake check` passes in CI on macOS and Linux.

## 3. Superseded plan

- [x] 3.1 Mark `docs/plans/2026-08-09-knowledge-management-plan.md` superseded, pointing to the notes application contract, and move its entry in `docs/plans/INDEX.md` to the superseded historical records, and verify the format check passes.

## 4. Acceptance

- [x] 4.1 Run the README's Windows checks and `openspec validate install-obsidian --strict` from the PR branch, and record that they pass. `ci.ps1` exited 0 with 120 passing Pester tests, the format check passed and the change validated.
- [x] 4.2 Run the workstation dry run and `chezmoi diff` on Korolev from the PR branch, and record that drift covers only Obsidian, gitleaks and the Run value and that `chezmoi diff` changes no file. The dry run reported drift for `package notes`, `package secret scanner` and `notes startup` only. `chezmoi diff` listed only the run scripts: the workstation script, because the declaration changed, and the three scripts that run on every apply.
- [x] 4.3 Run `chezmoi apply` on Korolev, then record a zero-exit dry run and a passing `chezmoi verify --exclude=scripts`. Apply exited 0 and installed Obsidian 1.14.4 and gitleaks, the dry run then exited 0 and verify exited 0.
- [x] 4.4 In a fresh PowerShell 7 session on Korolev, verify that `obsidian` resolves to `Obsidian.com` and `gitleaks version` prints a version. After the owner turns on Obsidian's command-line interface and skips its registration, verify that the user PATH is unchanged and `obsidian version` prints Obsidian's version. An interactive session with the profile loaded resolved `obsidian` to `%LOCALAPPDATA%\Programs\Obsidian\Obsidian.com` and printed gitleaks 8.30.1. After Skip, `obsidian.json` held `"cli":true`, the user PATH was byte-identical to the earlier snapshot and `obsidian version` printed `1.14.4 (installer 1.14.4)`.
- [x] 4.5 After the owner signs out and back in on Korolev, verify that Obsidian started without further action. Waived by the owner. The Run value is present with the declared path.
- [x] 4.6 Verify that the PR's macOS, Linux, Windows and OpenSpec CI checks pass. They passed for `751351b` and again after the rebase onto the Colima root disk fix.
- [x] 4.7 On the Mac, run `darwin-switch` in a terminal while the owner types the password. Verify that the login agent is loaded for the graphical session and a fresh zsh resolves `obsidian` to the cask's link. After the owner turns on the command-line interface and skips the registration, verify that the setting stays on and `obsidian version` prints Obsidian's version. The switch installed the cask and created `org.nixos.open-obsidian` in `gui/501`. Its run during activation exited 1 because the cask was installed afterwards, and a kickstart then opened Obsidian with exit 0. `obsidian` resolved to `/opt/homebrew/bin/obsidian`, linked to `obsidian-cli`. After Skip, `obsidian.json` held `"cli":true`, `/usr/local/bin/obsidian` did not exist and `obsidian version` printed `1.14.5 (installer 1.14.5)`.
- [x] 4.8 After the owner logs out and back in on the Mac, verify that Obsidian started. Quit Obsidian, open an SSH login and verify that Obsidian stays closed. The login test was waived by the owner. With Obsidian quit, a new SSH login left it closed.
