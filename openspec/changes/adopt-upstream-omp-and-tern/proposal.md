# Proposal

## Why

The owner has verified that the maintained clickable-link patches are unnecessary in Tern. Upstream OMP and its plugin manager can therefore replace the workstation's patched source generations, wrapper, verifier, and Herdr integration while preserving personal behavior and user-owned state.

## What Changes

- **BREAKING**: Install upstream standalone OMP through the official installer on macbook-pro and Korolev's WSL environment; update with `omp update`. Remove `packages/personal-omp/`, `packages/omp-dev-update/`, patch pins, `modules/home/omp.nix`, the repository `omp-update` skill, all Herdr delivery/integration/restart machinery, obsolete outputs/checks, and the unarchived `restart-sessions-and-prune-omp-generations` change.
- **BREAKING**: Replace the runtime Nix-pinned personal plugin with the user-scope install and upgrade commands defined by prerequisite change `publish-plugin-through-omp-plugin-manager` in `omp-agent-setup` (expected `personal@glockyco` and `omp plugin upgrade`). Retain only build-time plugin input uses needed by OpenSpec checks.
- Move OpenSpec, Plannotator, and language servers into ordinary Home Manager `home.packages`; keep the full Mac matrix and omit Roslyn on WSL. Home Manager removal belongs to the next change.
- Make Tern the primary terminal on the Mac while keeping Ghostty and the Herdr package available as secondary tools; retain Tern's bundle CLI path and Dock declaration. Remove the unused OMP agent-server setting from both Mac and rendered Windows Zed settings without changing unrelated editor settings.
- Update the personal desktop's manual native-agent procedure to official OMP plus its plugin manager. Native Korolev OMP provisioning remains in `make-korolev-windows-native`.
- Rewrite current OMP ownership/update/recovery guidance in AGENTS.md, README, and operations docs; remove the source-update/recovery runbook rather than retaining a compatibility path. Preserve real-session, Plannotator, and language-server acceptance with upstream OMP in Tern.
- Stage the live migration before deleting the wrapper: install and prove upstream OMP and the published plugin independently on both hosts, retain previous Nix/source generations, then activate the clean cutover and prove default-command resolution in new sessions. The current wrapped WSL conversation must survive until the replacement is demonstrated.

## Capabilities

### New Capabilities

None; upstream installation and Tern delivery extend the existing workstation capability.

### Modified Capabilities

- `personal-omp-workstation`: official standalone command and plugin-manager ownership, ordinary packages, platform matrix, Tern, live acceptance, removal of source-generation and Herdr contracts; minimally remove OMP module wording from the shared module requirement.
- `omp-update-guidance`: concise official-update guidance and observable acceptance replace repository skill, patch repair, and Herdr requirements.
- `omp-visual-feedback`: ordinary Plannotator package and plugin-manager adapter in upstream Tern sessions.
- `plannotator-maintenance`: retain commit-pinned vendor delivery and ordered acceptance without wrapper dependencies.
- `darwin-dependency-builds`: language servers are ordinary host packages; fixed-output Mac artifacts remain required.
- `native-windows-remote-work`: the desktop's native agent uses the official installer, `omp update`, and the plugin manager.
- `wsl-host`: activation, installer prerequisites, ordinary package closure/cache, mutable state, and Tern release proof; adapt the old source-updater browser scenario to official updates and minimally remove retired closure clauses.
- `repository-quality-gates`: retain OpenSpec consistency and adapter checks independently of runtime plugin installation; minimally remove wrapper-specific behavior checks.
- `dependency-update-automation`: official OMP/plugin update ownership, explicit live operations, and honest recovery boundary.

## Impact

Affected implementation areas are the two OMP package directories, portable/Darwin Home Manager modules, shared Zed settings and its Windows renderer caller, Mac application declarations, flake inputs/overlay/check wiring, browser ABI check, and current repository guidance. `llm-agents` stays for OpenSpec, `plannotator-packages` stays for vendor pinning, and `personal-omp-plugin` stays only for `lib.openspecCheck`/required generator tooling, not runtime delivery. No live install, activation, authentication, implementation edit, or commit is performed while authoring this plan. Archive order is plugin publication → this change → chezmoi migration → native Windows Korolev → secondary WSL.
