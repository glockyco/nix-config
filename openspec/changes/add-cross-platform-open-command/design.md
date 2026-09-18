## Context

See `proposal.md` for motivation and `specs/cross-platform-open-command/spec.md` for behavior.

Korolev uses zsh through Home Manager. `start` is absent because it is a `cmd.exe` built-in, not an executable. `wslview` is also absent. The pinned Nixpkgs removed `wslu` after upstream discontinued and archived the project. WSL provides `/sbin/wslpath` through its `/init` interoperation binary, and `explorer.exe` resolves from the mounted Windows system directory.

The Windows desktop uses PowerShell 7.6.5. Its current-user profile files do not exist, and `open` does not resolve. A disposable live probe showed that PowerShell auto-loads an `OpenTarget` module and its exported `open` alias from a user module directory. The probe preserved paths with spaces and removed all temporary files.

The repository renders Windows configuration artifacts but never applies them from Nix. The Windows document already supports user-scoped script resources. The active platform-role and declaration-derived Windows-check changes are deferred and do not block this behavior change. Implementation must use the repository ownership that exists when apply starts and must not duplicate a moved owner.

## Goals / Non-Goals

**Goals:**

- Give the user one memorable command with the same basic contract in all three interactive environments.
- Pass every target as data, without a command interpreter or reconstructed command line.
- Keep WSL dispatch dependent only on the supported WSL interoperation boundary.
- Make native PowerShell discovery composable without taking ownership of a profile.
- Keep activation and configuration application free of graphical launches.

**Non-Goals:**

- Replace macOS `/usr/bin/open` or normalize its platform-specific options.
- Support multiple targets through the portable interface.
- Provide a generic Linux desktop opener outside WSL.
- Add WSLg, a browser preference, a file-association policy, or a background service.
- Restore `wslu`, package another opener, or add an executable fallback.

## Decisions

### 1. `open` is the portable user interface, not one portable executable

macOS keeps `/usr/bin/open`. Korolev installs a Nix-built command named `open` only in its NixOS/WSL user environment. Native Windows installs an `open` alias through a PowerShell module. Each implementation owns its platform boundary while the spec owns their shared zero-or-one-target contract.

A shared cross-platform script was rejected. It would need platform branches, would override the mature macOS command, and would violate the planned separation of platform roles.

Different command names were rejected. `explorer.exe`, `Start-Process`, and `open` expose the same user intent but retain unnecessary shell-specific knowledge.

### 2. The WSL command translates local paths and executes `explorer.exe` directly

A small `writeShellApplication` command will apply this order:

1. Reject more than one target.
1. Use `.` when the target is omitted.
1. If the target exists, call `wslpath -aw -- <target>`.
1. Otherwise, accept only a syntactically absolute URI.
1. Resolve and execute `explorer.exe` with the resulting value as one argument.

Existing-path detection precedes URI detection so that a valid Linux filename containing a colon remains a path. The wrapper will check both `wslpath` and `explorer.exe` and name the missing boundary. It will not search for another opener.

A live WSL dispatch showed that `explorer.exe` returns status 1 after handing each valid file, directory, and URI request to the Windows shell. Explorer has no documented success exit code. The wrapper therefore validates the target and both interoperation commands itself, preserves shell-level execution failures 126 and 127, and otherwise reports that the dispatch request completed.

`cmd.exe /c start` was rejected because `start` is a shell built-in and safe transport requires Windows command-line quoting. A target containing shell metacharacters can otherwise become code.

Calling `Start-Process` through an inline PowerShell command was rejected for WSL. It adds a second quoting boundary without improving Windows shell dispatch.

`wslview` was rejected because its upstream project is discontinued and the pinned package set removed it. `xdg-open` was rejected because it selects the Linux desktop boundary rather than the host Windows desktop.

### 3. Native PowerShell uses an auto-loading module

The Windows configuration will install `OpenTarget.psm1` and `OpenTarget.psd1` in the current user's PowerShell 7 module path. The module will export an approved `Open-Target` function and an `open` alias. Its manifest will declare both exports so normal PowerShell command discovery auto-loads the module.

`Open-Target` will use `Test-Path -LiteralPath` before URI parsing. It will pass an existing path or absolute URI to `Start-Process -FilePath` without invoking a command interpreter. Invalid input will raise a terminating error before dispatch.

A profile function was rejected. It would require the Windows configuration to own or patch a general-purpose startup file. The module provides native discovery, isolates ownership to one directory, and leaves both current-user profile files untouched.

A `.cmd` wrapper was rejected because `%*` reconstructs a command line and weakens argument handling. A new native executable was rejected as unnecessary compiled code and maintenance.

### 4. One user-scoped Windows resource owns the module directory

The rendered Windows document will contain one non-elevated resource for the two exact module files. It will resolve the PowerShell 7 user module directory rather than assume that the Documents known folder is not redirected. Its test phase will compare exact content and confirm that no profile path is part of the resource. Its set phase will create only the module directory and files.

The resource will not import the module or invoke `open` during apply. A fresh PowerShell 7 process provides the discovery proof after apply.

Merging the function into another application settings resource was rejected. The command is a shell capability with an independent lifecycle and rollback boundary.

### 5. Static checks prove transport; live smokes prove graphical dispatch

A behavior check will run the WSL command with disposable `wslpath` and `explorer.exe` doubles. It will cover the default target, an existing path with spaces and metacharacters, an absolute URI, excess arguments, an invalid target, and each unavailable interoperation command. Assertions will inspect the captured argument vector, status, and error.

The Windows configuration check will verify the declared user scope, exact module files, manifest exports, absence of profile writes, and absence of `cmd.exe`, `wslu`, and WSL launchers. PowerShell will parse and import the rendered module during repository validation where the current check architecture supports it. The Windows live smoke will prove auto-loading and actual file, directory, and URI dispatch in a fresh PowerShell 7 process.

Static tests cannot prove which graphical application appears. Final acceptance therefore uses the actual macOS and Windows desktops. The operator will observe the opened target and close it after each smoke.

## Risks / Trade-offs

- A future PowerShell package could introduce another `open` command. -> Check `Get-Command open` after apply and require the `OpenTarget` module as its source.
- `explorer.exe` can accept a request and exit before the target application becomes visible. -> Treat process success as dispatch only and require visual confirmation for live acceptance.
- Registered URI handlers can launch arbitrary installed applications. -> Require an explicit absolute URI and pass it directly as data; do not evaluate it through a shell.
- WSL interoperation can be disabled independently of the Nix generation. -> Fail with the missing boundary and provide no hidden fallback.
- Deferred refactors can move the NixOS role or Windows renderer before implementation. -> Re-resolve current owners at apply time and update one owner only; do not restore obsolete paths.

## Migration Plan

1. Add and behavior-check the Nix-managed WSL command in the current WSL user owner. Activate Korolev, then verify a directory, file, and URI against the Windows desktop.
1. Render the PowerShell module and its user-scoped Windows resource. Build and inspect the complete Windows artifact before application.
1. Apply the rendered Windows configuration from a standard PowerShell session. Start a fresh PowerShell 7 process and verify command provenance and graphical dispatch.
1. Confirm macOS still resolves and exercises `/usr/bin/open`. Run all repository and OpenSpec gates before release.
1. Roll back Korolev with the previous NixOS generation. Roll back Windows by removing only the configuration-owned `OpenTarget` module directory or by restoring its retained prior version; Windows has no Nix generation rollback. The native macOS command needs no rollback.
