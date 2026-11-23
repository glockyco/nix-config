# Design

## Context

The shared application list feeds the typed host registry, casks, Dock entries and login agents. The registry asserts identities and unique paths, casks and positions. nix-darwin's pinned Homebrew module exposes `masApps` as a name-to-positive-ID mapping and puts its Nix `mas` package on activation's PATH. See proposal.md for motivation.

## Goals / Non-Goals

- Keep App Store identities beside the existing application facts.
- Preserve all existing path, cask, Dock and login semantics.
- Do not sign in, acquire App Store licenses or activate the system during implementation.
- Do not pin App Store versions or add another installer.

## Decisions

Add nullable `masId` and `masName` fields to the existing submodule. A name is required with an ID because Homebrew's mapping requires a readable key. Both fields default to null, so existing records remain unchanged. Require the fields together and unique IDs and names, which prevents `listToAttrs` from silently overwriting records. A record needs a cask, App Store ID or app path.

Build `homebrew.masApps` from the typed records with an ID. Expose `pkgs.mas` in system packages when those records exist, so the executable is available interactively as well as during nix-darwin activation. Do not also install a Homebrew formula for the same tool.

Login-path diagnostics must use the cask or App Store name instead of assuming every installable record has a cask. Keep the path requirement for login starts and Dock positions.

Extend the existing declaration fixtures for positive and invalid App Store identities. Extend the per-host shared-facts normalization and add desktop assertions derived from the registry for casks, App Store mappings and the `mas` package. Existing package behavior tests remain unchanged because no packaged program changes.

Add README guidance beside the shared TOML inventory link, pointing to the option declaration for fields. Explain App Store sign-in and first-acquisition limitations without copying the application's identity into prose.

## Risks / Trade-offs

- App Store authentication cannot be supplied declaratively. Sign in interactively before activation.
- macOS may refuse `mas install` for an application never obtained with the account. Obtain it in the App Store first, then rerun activation.
- Removing an App Store record does not guarantee uninstall because Homebrew Bundle does not implement App Store cleanup.

## Migration Plan

Build and validate the new generation without activation, including checking the evaluated App Store mapping. Commit on a feature branch. Run the existing interactive `darwin-switch` workflow after App Store prerequisites are met. Roll back using the README procedure if needed, noting that App Store application state is not rolled back with Nix.

## Acceptance Results

- `openspec validate add-mac-app-store-applications --strict` passed.
- `openspec validate --all --strict` passed all 22 items. Archived strict validation passed all 63 changes.
- `nix fmt -- --fail-on-change` passed.
- `nix flake check --print-build-logs` passed the native macOS checks, including the declaration fixtures, shared facts, application mapping and packaged-program tests. Linux checks were omitted as incompatible with the current host.
- `nix run .#check-darwin-build-plans` checked 67 outputs with no forbidden source builds.
- `nix build .#darwinConfigurations.macbook-pro.system` passed.
- `nix eval --json .#darwinConfigurations.macbook-pro.config.homebrew.masApps` returned `{"Keynote":361285480}`.
- No activation, App Store sign-in or app installation was run.

## Delivery

Implementation is committed as `47900a5` on `feat/keynote-app-store-inventory`. Activate from an interactive terminal with `cd ~/.config/nix-darwin && darwin-switch`, after meeting the App Store prerequisites above. Enter the password when prompted. The branch has not been pushed, and the change remains unarchived.
