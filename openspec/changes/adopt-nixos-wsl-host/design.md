## Context

See `proposal.md` for motivation and `specs/personal-omp-workstation/spec.md` for the contract.

### Observed machine facts

A direct audit of `korolev` on 2026-09-02 produced these facts. They are durable constraints, and they explain several decisions below.

| Property                      | Observed value                                                                               |
| ----------------------------- | -------------------------------------------------------------------------------------------- |
| Hardware and operating system | Dell Pro Max 14 MC14250, Windows 11 Enterprise, build 26100                                  |
| Directory membership          | AD domain `SCCH` and Azure AD, tenant `Software Competence Center Hagenberg GmbH`            |
| Device management             | Intune, `enrollment.manage.microsoft.com`                                                    |
| Interactive account           | `JGlock`, standard user, medium integrity, not in `Administrators`                           |
| Privileged account            | The operator holds durable credentials for the local `Administrator` account                 |
| Security agents               | Defender Antivirus, Defender for Endpoint, Purview data loss prevention, SCCH Sentinel Agent |
| WSL restriction policy        | none present; verified with an elevated registry read                                        |
| Application control           | AppLocker not enforced; user-mode code integrity not enforced                                |
| Host resources                | 31.5 GB memory, 16 logical processors, 825 GB free on `C:`                                   |

Windows also carries Microsoft 365, Teams, Outlook, OneDrive, Edge, FortiClient VPN, Exclaimer, and the Dell, Intel, NVIDIA, and Realtek driver stacks. Intune and Group Policy own that software.

An elevated read of the Intune application policy resolved the ownership of every remaining application. Intune deploys or manages updates for `7-Zip`, `Adobe Acrobat Reader`, `draw.io Diagrams`, `Docker Desktop`, `Git for Windows`, `Google Chrome`, `IrfanView`, `Microsoft Visual C++ Redistributable`, `Microsoft Visual Studio Code`, `Mozilla Firefox`, `Notepad++`, `Oracle Java 8`, `Oracle JDK`, `Oracle VirtualBox`, `PuTTY`, and `WinSCP`.

Intune manages no policy for Zed, Zen, or Fork. The elevated policy tree also holds no entry for WSL, Windows Terminal, or the Windows developer settings.

### Verification spike results

| Spike                                                                   | Result                                                                                                     |
| ----------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Import a distribution as the standard user                              | Import, execution, and removal all succeeded                                                               |
| Build and run a NixOS-WSL distribution                                  | systemd is process 1, `nixos-rebuild` present, `/mnt/c` reachable, `/etc/wsl.conf` generated               |
| Build NixOS-WSL against the pinned `0.2605` nixpkgs                     | System closure built in 77 seconds                                                                         |
| Realize that closure                                                    | 42 derivations built, 593 fetched, 906 MiB downloaded                                                      |
| Build the portable user modules for `x86_64-linux`                      | Home Manager generation built                                                                              |
| Install a package with the Windows package manager for the current user | Completed without elevation                                                                                |
| Resolve names and reach substituters through the corporate VPN          | Internal and external names resolved, both substituters returned HTTP 200, GitHub authentication succeeded |
| WSLg availability                                                       | X display, Wayland socket, and `/dev/dxg` all present                                                      |

## Goals / Non-Goals

**Goals:**

- Make the WSL machine a host of this repository.
- Give the WSL machine a complete declarative user scope.
- Remove the hand-written activation, replacement, and rollback implementation.
- Remove the distribution package manager and the separate Nix installer from the procedure.
- Keep provisioning possible for a standard Windows user.
- Declare the host defaults that macOS supplies by default.

**Non-Goals:**

- Manage Windows applications, Windows policy, or Intune-owned software.
- Declare the Windows-side configuration. A later change owns that layer.
- Change the Darwin host behavior.
- Add a network service, a secret, or an inbound path to the WSL host.
- Select a permanent editor for the WSL host.
- Match the macOS temperature setting. glibc has no locale category for it.

## Decisions

### 1. Use NixOS-WSL rather than standalone Home Manager on Ubuntu

Define the WSL machine as `nixosConfigurations.korolev`. Both supported hosts then share one model: a system configuration that imports Home Manager as a module.

The audit removed every reason to prefer the Ubuntu fallback. No WSL policy restricts the machine, application control is not enforced, and import needs no elevation. NixOS-WSL also removes the `apt-get` prerequisites and the separate Nix installer, which are the two steps a standard user should not have to depend on.

**Alternative:** Standalone Home Manager on the current Ubuntu distribution. Rejected because it recovers the user scope but leaves the Linux system scope imperative, and because the reason to hedge no longer exists.

**Alternative:** Keep the user-profile entry and add a Home Manager configuration beside it. Rejected because two activation mechanisms would own overlapping paths.

### 2. Let the `nixos-wsl` input follow the pinned nixpkgs

Set `inputs.nixos-wsl.inputs.nixpkgs.follows = "nixpkgs"`.

Two facts decide this. First, 7 of the 9 current inputs already follow the pinned nixpkgs, so following is this repository's convention. Second, a measured build shows the cost: following rebuilds only `nixos-wsl-utils` and its Rust crates, and the complete system closure still built in 77 seconds. Without `follows`, the lock would carry a second nixpkgs at release 26.11 while the repository pins 26.05.

The `llm-agents` input keeps its documented exception, because that input ships prebuilt outputs from a cache keyed to its own nixpkgs. State that difference next to both inputs.

**Alternative:** Let `nixos-wsl` keep its own nixpkgs. Rejected because a second nixpkgs in one lock buys nothing here and costs closure size and review effort.

### 3. Declare Nix settings in system scope

Declare the Numtide substituter and its trusted public key in the host's `nix.settings`.

The accepted evidence for the previous implementation records a repeated warning that Nix ignores a client-specified `trusted-public-keys` setting for an untrusted user. That warning exists because the root flake advertises the cache through `nixConfig`. A system setting removes the cause instead of tolerating the symptom.

Keep the root flake `nixConfig` for the Darwin host and for a first evaluation on a foreign machine.

### 4. Make the Git identity declarative and conditional

Declare `johann.glock@scch.at` as the global Git email on the WSL host. Declare the GitHub no-reply address for personal repository trees with a conditional Git include.

The previous implementation wrote repository-local configuration during activation. A conditional include covers every present and future checkout under the named trees, and it needs no mutation.

The include condition names a directory tree, so the layout decides the identity. `programs.git.settings.ghq.root` sets `~/src`, and ghq creates `~/src/<host>/<owner>/<repo>`. The condition matches that layout. A clone placed directly under `~/src` does not match, and it reports the work email. The runbook therefore clones through the ghq layout.

**Alternative:** Keep repository-local configuration for each checkout. Rejected because activation then mutates a repository, and a new clone silently gets the wrong identity.

### 5. Delete the bootstrap application instead of keeping it

Delete `packages/bootstrap-omp-on-wsl.nix`, `packages/bootstrap-omp-on-wsl-tests.nix`, `packages/personal-omp-wsl.nix`, and the `wslOmpEnvironment` and `bootstrapOmpOnWslCommand` checks.

Those 535 lines implement ordered activation, generation replacement, failure rollback, and preflight refusal. NixOS provides all four. The reconciliation and verification programs stay in `packages/personal-omp.nix`, where both hosts already consume them.

Keep no alias and no compatibility path. The repository rule is a clean cutover.

### 6. Cut over side by side

Import the NixOS distribution while `Ubuntu-26.04` stays registered. Prove the new host. Make it the default Windows Terminal profile. Remove the Ubuntu distribution only after the real-session smoke passes.

This matches the existing rule to keep the previous generation until all applicable gates pass. The current Ubuntu installation also builds the first tarball, because the Darwin host cannot cross-build an `x86_64-linux` system.

The image carries no configuration reference. The tarball builder writes the reviewed system closure, and the operator then clones this repository and runs `nixos-rebuild switch --flake .#korolev` from that clone, as the Darwin host rebuilds from its own checkout. Do not edit `/etc/nixos` by hand, and do not seed it.

One repository holds one lock. A seeded `/etc/nixos` needs its own `flake.nix` and `flake.lock`, and that lock is stale as soon as the clone moves ahead of it. A seed without a lock is worse, because the first rebuild resolves an unpinned reference and can activate a revision that no review covered.

Recovery does not need a seed. The tarball is itself the recovery artifact, the previous generation stays selectable after every activation, and `Ubuntu-26.04` stays registered until the smoke passes.

The clone resolves against the published revision. A revision must therefore reach the remote before the first rebuild inside the distribution. The tarball is unaffected, because the builder writes the closure that the local tree evaluates. A clone of an older remote would build and activate cleanly, and it would silently drop every change that the remote does not carry.

**Alternative:** Seed `/etc/nixos` with a flake and its lock. Rejected because it adds a second lock that is stale on arrival, and because that lock can pin only a revision that already reached the remote.

**Alternative:** Copy this repository into the image. Rejected because it puts repository history in a system image, needs an ownership fixup, and replaces a resolved reference with a snapshot that has no update path of its own.

### 7. Enable `nix-ld`

Enable `programs.nix-ld` on the WSL host. Project work uses prebuilt executables from .NET, Unity, and game loader toolchains. `nix-ld` is the supported NixOS answer for those binaries, and it replaces the escape hatch that the distribution package manager provided.

### 8. Leave the host without a network service or a secret

Declare no SSH server and no other inbound service. Add no age recipient for this host, and declare no secret.

The operator confirmed that no other machine drives `korolev`. The machine also runs endpoint data loss prevention and two endpoint detection agents, so personal decryption material does not belong on it. `.sops.yaml` keeps one recipient.

### 9. Accept two Nix distributions across the two hosts

The Darwin host keeps Determinate Nix, because the `determinate` input exists to coordinate `/etc/nix/nix.conf` ownership with nix-darwin. The WSL host uses the Nix that its system closure provides. NixOS has no such coordination problem.

This asymmetry is deliberate. Each host uses the idiomatic option for its platform.

### 10. Mask the console unit and require a clean unit state

A reference NixOS-WSL system reports `degraded`, because `getty@tty1.service` and `user@1000.service` fail. The two failures have different causes. WSL provides no `tty1`, so the console unit is a configuration matter, and this host disables it.

`user@1000.service` fails only while another distribution with the same user ID runs. WSL places no distribution in its own cgroup namespace, so every running distribution targets `/user.slice/user-1000.slice/user@1000.service`, and the second one to start cannot attach. A measurement on the imported host confirmed this. The Ubuntu distribution holds an active `user@1000.service` and owns that path, and the imported host reports `Failed to spawn executor: Device or resource busy`. An interactive session does not change the result, and neither does a restart of the unit.

The condition therefore belongs to the side-by-side window, not to the host. Require the clean unit state after the Ubuntu distribution is removed, because a permanent `degraded` state hides real failures.

**Alternative:** Give the WSL user a unique user ID. Rejected because it carries a permanent non-default identity to work around a condition that ends with the cutover.

### 11. Install the editor on Windows and keep it out of the Linux host

Zed for Windows runs a lightweight remote server under `wsl.exe` and keeps language servers, tasks, and terminals on the Linux side. The user interface therefore runs natively on Windows, while every language server still runs where the code and the Nix toolchains are.

That property removes the three earlier objections at once. The editor needs no SSH server, so the network isolation decision holds. The editor needs no WSLg, so the display path is irrelevant. The language servers stay in the Linux closure.

Installing from the Windows package manager also preserves an existing decision. `modules/darwin/homebrew.nix` selects the Zed cask so that the vendor updater sets the release cadence, and `modules/home/zed.nix` sets `package = null` for the same reason. A nixpkgs package on the WSL host would reverse that decision for one host only.

Exclude `zed` and the Zed part of `catppuccin` from the WSL host. Declare the Zed settings once in Nix, and let each host apply them with its own mechanism: Home Manager on Darwin, and a file resource in the Windows layer.

**Alternative:** Install the nixpkgs `zed-editor` and run it under WSLg. Rejected because it contradicts the vendor-cadence decision, adds a display dependency, and gains nothing over native WSL remoting.

### 12. Keep the Windows layer out of this change

The audit reduced the Windows layer to Windows Terminal settings, the Zed settings, and a small set of per-user packages. A measured test with the corporate VPN connected showed that the default network mode resolves internal and external names correctly, so `networkingMode=mirrored` is not required and `%USERPROFILE%\.wslconfig` is optional rather than load-bearing.

`manage-windows-layer` owns that layer, including the shared expression that holds the Zed settings. This change only excludes the editor from the WSL host, because the consumer of a shared expression is the right owner of its extraction.

### 13. Provide containers with a rootless runtime inside the distribution

Declare a rootless container runtime with Docker command compatibility in the WSL system scope.

The Darwin host runs Colima, which exists because macOS needs a Linux virtual machine to run containers. WSL 2 already provides that virtual machine, so the same approach would nest one machine inside another. A runtime declared in the NixOS host needs no extra machine, no separate profile file, and no start command before use.

This decision also keeps the Intune rule from decision 12. Intune manages updates for Docker Desktop, so a Windows container product would collide with central management as soon as it appeared.

**Alternative:** Docker Desktop for Windows with WSL integration. Rejected because Intune manages it, it creates its own distributions, and it moves container state outside the declared host.

**Alternative:** Port the Colima profile to the WSL host. Rejected because the nested virtual machine has no purpose here.

The container runtime is system scope on a host that this change already creates, so it belongs here rather than in a separate change. The added surface is one module and one acceptance gate.

### 14. Review the host defaults that macOS supplies

`modules/home/` carries only what Nix declares. macOS supplies the login shell, the time zone, the number and date formats, and a URL opener. NixOS does not inherit those macOS choices, so a Linux host needs an explicit review of those defaults.

The portable module set builds on `x86_64-linux`. That result says nothing about a default that no module declares. An audit of `korolev` found these defaults. The login shell is `bash`, and Home Manager configures only zsh. `time.timeZone` is null, and the host declares no time or measurement category, so `en_US.UTF-8` renders 12-hour time and US measurement. No package opens a URL.

Declare the login shell, the time zone, and the two locale categories in this change. Declare `de_AT.UTF-8` for `LC_TIME` and `LC_MEASUREMENT`, which gives 24-hour time and metric measurement. NixOS derives the built locale set from the declared categories, so the categories need no second list. `i18n.supportedLocales` is deprecated and hidden, and this host leaves it unset.

Temperature has no locale category in glibc, so temperature is application-dependent on this host. The Darwin host sets Celsius through a macOS interface, and the WSL host cannot match that value. The Darwin host also forces 24-hour time over an `en_US` base, which uses the `%m/%d/%Y` date order. `de_AT.UTF-8` uses `%Y-%m-%d`, so the declared locale changes the date order as well as the clock.

### 15. Keep Git out of the WSL system scope

`modules/darwin/system.nix` installs Git in system scope, and its comment states that root needs Git during `darwin-rebuild switch`. Do not copy that decision to this host.

Three measurements contradict the stated reason. `nix flake metadata` succeeds with Git absent from `PATH`, because Determinate Nix resolves a local flake through libgit2. `nixos-rebuild-ng` contains no reference to Git. `darwin-rebuild` also contains none.

The portable module set supplies Git for the interactive user. Record this result so that a later reader does not add a system package for a reason that no longer holds.

## Risks / Trade-offs

- **A module classified as portable holds a hidden macOS assumption.** Mitigation: build the complete portable set for `x86_64-linux` as a flake check, not only the four modules that the spike covered.
- **The imported distribution loses OMP-owned state.** Mitigation: the new host is a separate distribution, so the Ubuntu state stays untouched until removal. Authenticate providers again on the new host rather than copying any database.
- **`nixos-wsl` stops supporting the pinned stable nixpkgs after an update.** Mitigation: the host build is a flake check, so the failure appears in review rather than during activation.
- **The Windows Terminal profile identifier changes with the distribution name.** Mitigation: prove the new profile and set it as default before removing the Ubuntu distribution.
- **A future Intune policy restricts WSL.** Mitigation: none available. Record it as an accepted external dependency, because Windows owns that policy.
- **The reduced Windows layer looks like an omission.** Mitigation: the later change states the IT-owned inventory as an explicit non-goal with its evidence.
- **The host declares no URL opener and no clipboard command.** No declared package provides `wslview`, and no variable names a browser. Mitigation: none in this change. `gh` may print a URL instead of opening one, so record the real behavior in section 6 and add a package only after a command fails.
- **The portable set declares no SSH client configuration.** `modules/home/ssh.nix` is Darwin-only, so this host loses connection multiplexing. Mitigation: none in this change. The system closure provides the OpenSSH client, so the loss is connection reuse only.

## Migration Plan

1. Complete `split-home-modules-by-platform`.
1. Add the `nixos-wsl` input with `follows`, and add `hosts/korolev/` and `modules/nixos/`.
1. Declare the host defaults: the login shell, the time zone, and the locale categories.
1. Add host checks for the system closure and the portable user set.
1. Build the tarball inside the current Ubuntu distribution and import it beside that distribution.
1. Activate, reconcile Herdr, and run local verification.
1. Authenticate the providers again, then run the real-session smoke.
1. Set the NixOS profile as the Windows Terminal default.
1. Delete the three packages, the two checks, and the obsolete runbook sections.
1. Record the release evidence, then remove the Ubuntu distribution.

Rollback before the Ubuntu distribution is removed is a distribution switch, because the Ubuntu environment stays intact. Rollback after that removal uses the previous NixOS generation.
