## Why

Official OMP updates replace local fixes. A personal source updater can retain those fixes on macbook-pro and korolev without publishing custom releases.

## What Changes

- Add `omp-dev-update`: prepare the latest stable upstream release with a pinned Git patch series, check it, then select it atomically.
- Keep `omp` as the immutable workstation wrapper, with the existing personal plugin and language tools. Run a host-local, verified source checkout through the upstream development launcher.
- Keep the previous generation for `omp-dev-update --rollback`. Failed updates leave the active generation unchanged.
- **BREAKING**: replace official executable update routing on both hosts. Reject `omp update` with instructions to use `omp-dev-update`; do not silently install an unpatched release.
- Keep updates outside activation. Do not add a scheduler, release channel, global Bun links, or a fallback executable.
- Obtain the patch series from the existing personal GitHub fork. Publishing its currently local branch requires separate, explicit permission.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `personal-omp-workstation`: replace platform-owned executable installation, update, and recovery contracts with explicit host-local source generations while preserving immutable integration and mutable application state.

## Impact

- `packages/personal-omp.nix`, `modules/home/omp.nix`, host runtime declarations, and their checks in `flake.nix`.
- A packaged updater and its behavioral tests, using the repository's Python command conventions.
- Concise changes to README commands, recovery instructions, WSL bootstrap instructions, and repository guidance that currently prohibits source patching and custom updates.
- Both `aarch64-darwin` (macbook-pro) and `x86_64-linux` (korolev). Each machine prepares its own native components; neither depends on the borrowed Air or the other host.
- Existing local patch commits in `glockyco/oh-my-pi`, not copied source or patch files in this repository. No publication occurs as part of normal updates.
