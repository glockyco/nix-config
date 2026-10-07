# Proposal

## Why

Korolev's work is moving to native Windows: the current Nix-rendered Windows layer, WSL Git bridge, Windows Terminal profile, and WSL-hosted tailnet identity no longer describe the owner's chosen workstation. A native package/configuration boundary lets the standard Windows account work in a local checkout without Nix while retaining NixOS-WSL for secondary work and the Mac builder.

## What Changes

- **BREAKING:** Capture the existing Windows output once into hand-maintained `windows/configuration.winget`, `windows/apply-zen-policies.ps1`, and `windows/apply-kbdneo.ps1`; move user files to the preceding change's `home/` chezmoi source, then delete both Windows Nix packages, their Python checker, output/check wiring, and obsolete review output.
- Keep WinGet Configuration responsible for Windows apps/settings and chezmoi responsible for user files. Windows `chezmoi apply` runs `winget configure` through a content-hashed `run_onchange_` script; Administrator operations remain explicit, never a privileged chezmoi apply.
- Replace Windows Terminal management with manually installed, self-updating Tern at a stable per-user path; replace Fork's `wslgit` bridge with per-user native Git/GCM. Add chezmoi and the native tools/LSPs needed for Markdown, Python, TypeScript/Svelte and Typst. LaTeX compilation and TexLab live on the Mac; neither Nix LSP nor C#/Unity tooling is installed on native Korolev.
- Make Git and Zen self-updating; remove only Git from the Intune-managed exclusion list using the recorded HKLM-only update evidence. Fold in and delete the unarchived `treat-zen-as-self-updating` change.
- Install upstream standalone OMP and use `omp update`; install the personal plugin through the command chosen by `publish-plugin-through-omp-plugin-manager`; install Plannotator through its minimal Windows installer so the plugin remains the personal integration owner.
- **BREAKING:** Transfer the single `korolev`/`tag:korolev` node from WSL to Tailscale for Windows, make it reachable like the desktop (all-port tailnet grants), and remove WSL Tailscale. Add explicitly approved Windows OpenSSH Server capability, separate Mac/desktop source keys, pinned identity, and effective tailnet-address-scoped firewall enforcement; do not expose WSL services.
- Port meaningful Windows invariants to native PowerShell tests and `winget configure validate` in Windows CI. Add platform-specific lefthook jobs and a native pinned tooling bootstrap; staging Nix without a usable Nix environment fails rather than silently skipping.
- Rewrite the provisioning runbook and README for Windows-first work, secondary WSL, node/key lifecycle, live-session acceptance, and recovery; replace AGENTS.md's blanket Korolev no-inbound rule with the Windows/WSL split.

## Capabilities

### New Capabilities

None; add native workstation, configuration ownership and service requirements to the existing Windows/fleet capabilities.

### Modified Capabilities

- `windows-workstation-layer`: hand-maintained Windows source, native package policy, chezmoi user ownership, native runtime/tooling, explicit machine exceptions and Windows-native validation.
- `fleet-tailnet`: Windows owns Korolev's one reachable identity; policy/tests and builder transport reflect that change.
- `wsl-host`: modify only `WSL host network isolation`, preserving private builder credentials and service isolation without a WSL tailnet node.
- `native-windows-remote-work`: modify only `Authenticated terminal access from each source` and `Tailnet-only access and existing fleet isolation` to include Windows Korolev and the new reachability decision.
- `repository-quality-gates`: modify only the four owned formatting, hook installation, development-environment and host-native-gate requirements for native Windows.

## Impact

Assumes changes 0, 1 and 2 are archived: no Home Manager, OMP wrapper/updater/Herdr, or Zed OMP agent-server setting remains; `.chezmoiroot = home`, shared TOML facts, and platform-neutral pinned SSH templates exist. Targets `windows/`, `home/`, both Windows package directories and callers, `treefmt.nix`, `lefthook.yml`, `.github/workflows/check.yml`, policy/check declarations, `hosts/korolev/`, WSL network role, README, AGENTS.md and `docs/operations/wsl-omp-bootstrap.md`. Windows remains Intune-managed and standard-user; installing services or accepting UAC requires the owner's separate Administrator credentials. Provider enrollment/login and policy push/merge require explicit owner participation/authorization. Windows configuration has no atomic generation rollback. `reduce-wsl-host-to-secondary` follows only after this change's native Tern session and remote reachability/builder gates pass.
