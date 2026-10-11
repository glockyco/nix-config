# Proposal

## Why

The owner's 2026-10-11 decision makes Korolev Windows-only: all projects run natively, so even the proposed secondary NixOS-WSL environment is unwanted. Retiring it after a lossless, owner-assisted project migration removes duplicate tooling, credentials and operational gates while keeping the private Mac fully supported by nix-darwin and chezmoi.

## What Changes

- **BREAKING**: Remove the `NixOS` Korolev host, NixOS outputs/baselines/WSL roles, `nixos-wsl`, WSL-only packages/checks, Linux user package consumers, SCCH automount, rootless Podman, WSL Git/GPG plumbing and Linux chezmoi facts/templates. Preserve Mac Nix/Colima and native Windows configuration.
- **BREAKING**: Retire `wsl-host` and the WSL `open` capability; update remaining contracts to Mac plus native Windows. Preserve native Windows Tailscale/OpenSSH and ordinary user SSH to the Mac; remove only the retired root Nix-daemon builder client and its Mac-only authorization/trust.
- Replace nix-config's Nix-based OpenSpec contract gate with direct host OpenSpec lefthook commands and the pinned reusable workflow released by omp-agent-setup's `support-native-windows`; drop `personal-omp-plugin` and its adapter-freshness wiring after this replacement works. Adapter freshness belongs to omp-agent-setup's own CI.
- Keep applicable Darwin/Linux CI checks and native Windows checks without any removed-host evaluation/build. Nix evaluation/build/activation are Mac/CI workflows; staged `.nix` files fail clearly on Windows with Mac/CI guidance, never WSL delegation or a successful skip.
- Document a per-project migration in `docs/operations/korolev-windows.md`: finish WSL sessions, owner-review and publish pending work, HTTPS native ghq-layout clones, migrate only OMP decision files into recalculated Windows banks, reproduce nonsecret model-provider configuration, publish the booking skill as an owner-approved private glockyco OMP marketplace, and record real native acceptance.
- Install native Windows Docker Desktop/Compose through nix-config as the third machine-scope exception alongside Zen and Tailscale, with owner-approved UAC and a self-updating/no-downgrade policy. Owner-confirmed 2026-10-11 Intune evidence shows update-only packages, not initial Docker installation; remove its managed-app exclusion using the Git precedent. Confirm employer licensing before installation. Retain Mac Colima.
- Reference other native replacements rather than re-plan them: employer-managed `S:\` or `\\scch.at\SCCH`; native Git Credential Manager; Windows LaTeX/PDF tools owned by `make-korolev-windows-native`. Project toolchain changes remain in their project repositories.
- After every project is accepted, retain an owner-coordinated `wsl --export NixOS <backup>.tar` before `wsl --unregister NixOS`. Leave Docker Desktop's engine-owned WSL distributions and the Windows WSL feature alone.
- Supersede and later delete the unstarted `reduce-wsl-host-to-secondary` and unarchived `manage-wsl-git-credentials` changes, without executing their obsolete retained-WSL/GPG tasks or modifying historical archives.

## Capabilities

### New Capabilities

None. Migration and Windows-only lifecycle requirements extend the existing Windows workstation capability.

### Modified Capabilities

- `wsl-host`: remove all remaining requirements and retire the capability.
- `cross-platform-open-command`: retire the WSL-only command and its requirements.
- `batch-ssh`: retain Mac/Windows user endpoints without a WSL user.
- `container-runtime`: replace the WSL runtime with repository-installed native Docker Desktop, updated by Intune; confirm licensing and owner-assisted installation before project migration; keep Mac Colima.
- `fleet-tailnet`: remove the Linux builder/transport contract; replace its old policy/SSH requirements with `Declared native fleet access policy` and `Native user SSH access to the Darwin host`, preserving Windows and Mac boundaries.
- `native-windows-remote-work`: remove WSL source/builder assumptions without changing the personal desktop's ownership.
- `omp-visual-feedback`: native Windows local reviews instead of WSL annotation and cross-host Nix delivery.
- `personal-omp-workstation`: platform-specific OMP ownership, portable user configuration and narrowly permitted decision-memory migration.
- `repository-quality-gates`: portable OpenSpec, Mac/CI Nix scope and staged-Nix rejection; replace retired scenario-bearing requirements with `Managed Nix host gates` and `Declared managed-host and native-peer facts`.
- `windows-workstation-layer`: Windows-only editor/terminal work, project migration and retained export/unregister; add Docker Desktop as a machine-scope self-updating package exception without weakening other privilege boundaries.
- `pdf-inspection-tools`: Mac and native Windows tools, not a Linux workstation.
- `python-project-tooling`: Mac Nix uv plus native Windows uv; project environments stay project-owned.
- `dependency-update-automation`: Mac-only activation and explicit native ownership/checks.
- `plannotator-maintenance`: Mac vendor Nix package plus Windows official release rather than one cross-host Nix input.
- `user-configuration`: remove WSL scenarios from the capability introduced by the prerequisite chezmoi change; retain both actual hosts.

## Impact

Apply only after `adopt-upstream-omp-and-tern`, `replace-home-manager-with-chezmoi` and `make-korolev-windows-native` are accepted and archived, and omp-agent-setup has released `support-native-windows`. Deltas target that resulting spec state, not today's partly migrated main specs. Existing predecessor WSL acceptance is completed under those predecessors while WSL remains live; this change then retires it rather than editing their plans retroactively.

Affected surfaces are `hosts/korolev/`, `modules/nixos/`, `modules/roles/nixos/wsl-workstation/`, typed fleet declarations, flake outputs/inputs/lock/checks, `packages/wsl-open/`, `packages/tailnet-builder-check/`, Mac builder-only authorization, `home/` Linux branches, `windows/dev/` hook dispatch/tests, `.github/workflows/`, README/AGENTS and operations runbooks. Live migration touches user project checkouts and selected OMP decision files only with owner coordination; no implementation, credential copying, activation, repository publication or distribution removal is authorized by this planning change.
