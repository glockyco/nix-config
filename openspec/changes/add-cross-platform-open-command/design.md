## Context

See `proposal.md` for motivation and `specs/cross-platform-open-command/spec.md` for behavior.

Korolev uses zsh through Home Manager. `start` is absent because it is a `cmd.exe` built-in, not an executable. `wslview` is also absent. The pinned Nixpkgs removed `wslu` after upstream discontinued and archived the project. WSL provides `wslpath` through its interoperation binary, and `explorer.exe` resolves from the mounted Windows system directory.

Native macOS and Windows commands are outside this change. The Windows workstation baseline has its own configuration and acceptance lifecycle.

## Goals / Non-Goals

**Goals:**

- Give the Korolev user one memorable `open` command.
- Pass every target as data, without a command interpreter or reconstructed command line.
- Depend only on the supported WSL interoperation boundary.
- Keep Nix activation free of Windows writes and graphical launches.

**Non-Goals:**

- Replace macOS `/usr/bin/open`.
- Add a native PowerShell command or apply the Windows workstation baseline.
- Support multiple targets.
- Provide a generic Linux desktop opener outside WSL.
- Add WSLg, a browser preference, a file-association policy, or a background service.
- Restore `wslu`, package another opener, or add an executable fallback.

## Decisions

### 1. Korolev owns one Nix-built `open` command

The current NixOS/WSL Home Manager owner installs a `writeShellApplication` named `open`. No shared home module or macOS module exports that name.

A shared cross-platform script was rejected because it would override mature platform commands and add branches that Korolev does not need.

### 2. The command translates paths and executes `explorer.exe` directly

The command applies this order:

1. Reject more than one target.
1. Use `.` when the target is omitted.
1. If the target exists, call `wslpath -aw -- <target>`.
1. Otherwise, accept only a syntactically absolute URI.
1. Resolve and execute `explorer.exe` with the resulting value as one argument.

Existing-path detection precedes URI detection so a valid Linux filename containing a colon remains a path. The wrapper checks both `wslpath` and `explorer.exe` and identifies the missing boundary. It does not search for another opener.

A live dispatch showed that `explorer.exe` returns status 1 after handing valid file, directory, and URI requests to the Windows shell. Explorer has no documented success exit code. The wrapper therefore validates inputs and interoperation commands itself, preserves shell execution failures 126 and 127, and otherwise treats the dispatch as accepted.

`cmd.exe /c start` was rejected because `start` is a shell built-in and safe transport requires Windows command-line quoting. Calling `Start-Process` through inline PowerShell was rejected because it adds a second quoting boundary. `wslview` was rejected because its upstream project is discontinued. `xdg-open` was rejected because it selects a Linux desktop rather than the host Windows desktop.

### 3. Static checks prove transport; a live smoke proves graphical dispatch

A behavior check runs the command with disposable `wslpath` and `explorer.exe` doubles. It covers the default target, an existing path with spaces and metacharacters, an absolute URI, excess arguments, an invalid target, and each unavailable interoperation command. Assertions inspect the argument vector, status, and error.

Static checks cannot prove which Windows application appears. Final acceptance therefore exercises the actual Windows desktop from Korolev.

## Risks / Trade-offs

- `explorer.exe` can accept a request before the target application becomes visible. -> Treat process completion as dispatch only and require visual confirmation.
- Registered URI handlers can launch arbitrary installed applications. -> Require an explicit absolute URI and pass it directly as data.
- WSL interoperation can be disabled independently of the Nix generation. -> Fail with the missing boundary and provide no fallback.
- A future shared module could export another `open`. -> Keep a package-set assertion that Korolev contains the command and macOS does not inherit it.

## Migration Plan

1. Add and behavior-check the Nix-managed command in the current WSL user owner.
1. Activate Korolev and verify a directory, file, and URI against the Windows desktop.
1. Run repository and OpenSpec gates.
1. Roll back with the previous NixOS generation if acceptance fails.
