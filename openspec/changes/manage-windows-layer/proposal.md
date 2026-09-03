## Why

The Darwin host declares its complete surface: 21 Homebrew casks, two fonts, macOS system defaults, application preferences, and application configuration files. The `korolev` Windows host declares none of that. It has no editor, no browser, no Git client, no window management, no keyboard layout, and no declared operating-system settings.

Nix cannot close that gap. Official Nix supports Linux, Darwin, FreeBSD, and OpenBSD; the first native Windows build appeared in June 2026 as a third-party milestone implementation, which is not suitable for a work machine. The Windows surface therefore needs its own declarative system.

Microsoft DSC v3 reached general availability in April 2026, and WinGet Configuration is its declarative document format. An audit of `korolev` confirmed that DSC 3.2.3 and the WinGet resources are installed and that per-user package installs complete without elevation. Zen is the one exception: its official WinGet installer supports machine scope only.

## What Changes

- Add `modules/windows/` that renders one WinGet Configuration document and a narrow Administrator script from one Nix declaration. The document owns every DSC resource and the script owns only Zen's Program Files policy file.
- Add `modules/shared/` for settings that more than one host renderer consumes.
- Declare a pinned application set: user-scope Zed, Fork, PowerToys with Command Palette and Grab And Move, ReNeo for Neo2, Windows Terminal, and JetBrainsMono Nerd Font, plus machine-scope Zen.
- Declare Windows settings with registry resources, naming every key.
- Declare the Windows Terminal, Zed, ReNeo, and PowerToys configuration files.
- Add a flake check that validates the rendered document and the narrow privilege boundary.
- Extend the operator runbook with the apply and verify procedure.

The change declares that Nix renders and Windows applies. Nix activation SHALL NOT write across the operating-system boundary.

## Capabilities

### New Capabilities

- `windows-workstation-layer`: Defines the rendered Windows configuration document, its user scope and explicit Zen privilege exception, the pinned application set, the declared Windows settings, the application configuration files, the excluded Windows surface, and the validation gates.

### Modified Capabilities

None.

## Impact

The change affects `flake.nix`, `modules/windows/`, `modules/shared/`, `modules/home/zed.nix`, `hosts/korolev/`, `README.md`, and the WSL operator runbook.

It does not change the Darwin system behavior, the WSL system or user scope, the OMP package, or the personal plugin. It installs no Windows service and grants no inbound access.

These items are explicit non-goals, each for a recorded reason:

- taskbar pinning, because Windows offers no supported per-user mechanism;
- file associations, because the operator selected a manual one-time pass;
- every application that the Intune policy manages, including Acrobat, which remains the PDF handler;
- the LaTeX previewer, which `evaluate-pdf-toolset` owns.

This change depends on `adopt-nixos-wsl-host`, because the Windows Terminal default profile identifies the NixOS distribution.
