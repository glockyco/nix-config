# Acceptance Evidence

## Static gates

- `nix fmt -- --fail-on-change` passed on 2026-09-18.
- `nix flake check --all-systems --print-build-logs` passed all 15 Linux-executed checks on 2026-09-18. This included `checks.x86_64-linux.wslOpenCommand`, both Windows configuration checks, and evaluation of the Darwin system and checks.
- `openspec validate add-cross-platform-open-command --strict` passed on 2026-09-18.
- `nix build --print-build-logs .#checks.x86_64-linux.wslOpenCommand` passed after the WSL wrapper implementation and after the Explorer status correction.
- The WSL mutation probe renamed `wslpath`, confirmed that `wslOpenCommand` failed, restored `wslpath`, and confirmed that the check passed.
- `nix build --print-build-logs .#checks.x86_64-linux.windowsConfiguration` passed. Its rejection probes covered the resource scope, exact review files, profile exclusion, module exports, PowerShell syntax, and forbidden fallback dependencies.

## Korolev live smoke

- Activated NixOS system: `/nix/store/mqs9ajwkp1dlaz5dg5px6zsrq0i3vca4-nixos-system-korolev-26.05.20260903.a5cc6f2`.
- A fresh login shell resolved `open` to `/etc/profiles/per-user/user/bin/open`.
- `open`, `open 'directory with spaces'`, `open 'file with spaces.txt'`, and `open https://example.com` returned status 0.
- Windows showed Explorer windows for the current and spaced directories, a Zed window for the file, and a Zen Browser window titled `Example Domain` for the URI.
- No Linux graphical opener was used.
- The live smoke found that Explorer returns status 1 after accepted launches. The wrapper now normalizes Explorer statuses other than shell execution failures 126 and 127. The corrected static check and live smoke passed.

Rollback remains the previous NixOS generation through `sudo nixos-rebuild switch --rollback --no-reexec`.

## Windows pre-apply evidence

- Before apply, both current-user PowerShell profile files were absent.
- Before apply, `Get-Command open` returned no command.
- The built artifact contained only the expected review files, including `OpenTarget/OpenTarget.psd1` and `OpenTarget/OpenTarget.psm1`.
- A disposable Windows probe parsed and imported the module. `Get-Command open` reported alias `open` from module `OpenTarget`. An invalid target raised a terminating error before dispatch.
- `winget configure test` over `desktop-batch` reported the `powershell open target` resource and broad unrelated state as out of date.
- The SSH process ran as `DESKTOP-DBHLRDD\User` with PowerShell 7.6.5, but `[Environment]::UserInteractive` was false. WinGet source refreshes were cancelled, and the Appx module could not load because the operation was unsupported in that process. Package results from this session are not valid acceptance evidence.
- Direct reads from the user's registry confirmed some real drift. `KeyboardDelay` was `1` instead of `0`; the short date was `dd/MM/yyyy` instead of `yyyy-MM-dd`; the date separator was `/` instead of `-`; and the declared Explorer Bags and snap-assist values were absent. Other sampled values, including `KeyboardSpeed` and metric units, matched.
- WinGet 1.29.290 has no resource-selection option for configuration apply. Therefore, no supported command can apply only the opener from the reviewed document.
- The document was not applied. The Windows profiles and live command state remain unchanged.

A standard interactive PowerShell session must retest the document before any full apply. If a full apply is later authorized, use the runbook verification and remove only `%USERPROFILE%\Documents\PowerShell\Modules\OpenTarget` to reject this module.

## macOS limitation

- The all-system flake check evaluated the Darwin system and checks successfully.
- Korolev could not authenticate to `glockyco@macbook-pro` with its interactive user credential: `Permission denied (publickey)`.
- The Mac-local build-plan command, native `/usr/bin/open` live smoke, and graphical verification were not run.

## Change boundary

- No `wslu`, `wslview`, shell alias, PowerShell profile edit, command interpreter, executable fallback, or activation-time Windows write was added.
- Commits `5b581a3`, `a38c063`, `c3e2be3`, and `bb75a9a` contain the planning, WSL implementation, README cleanup, and Windows implementation units.
