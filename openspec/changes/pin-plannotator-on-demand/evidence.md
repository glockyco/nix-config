# Maintenance verification evidence

## Scope

This change implements explicit Plannotator updates and CI output reuse. It does not complete the separate visual-feedback release's native browser, activation, network, or rollback gates. PR #29 retains its original candidate.

## Explicit package selection

- The declared and locked `plannotator-packages` revision is `b1c9a31450a814e50cddc3ab683b05c1dff7bb01`. Its vendor inputs remain independent of workstation Nixpkgs.
- Normalized existing input graphs were unchanged when the new input was added. Other tools retain their previous selections.
- Both host configurations were evaluated and asserted equal to their flake package's Plannotator selection. Both remain version `0.27.12` and preserve the previously built outputs:
  - Linux: `/nix/store/a7vjjwsnwwmqjy4zl2rj5a7vlwl63czl-plannotator-0.27.12`.
  - Darwin: `/nix/store/7li8lm8h96v92h17iygzn09yknpixn2a-plannotator-0.27.12`.
- The actual central command, `nix flake update`, passed in a disposable checkout of staged tree `02506bdd2801b203c651648dbef997a8c5b883f6`. Six other root inputs advanced: `catppuccin`, `home-manager`, `karabiner-complex-modifications`, `llm-agents`, `nix-index-database`, and `nixpkgs`.
- The complete normalized Plannotator input graph stayed unchanged. Evaluation after the update returned the same version, Linux output, and derivation: `/nix/store/y4n3xp8ffq47jjm3h7p6sfmvnhiy9x5f-plannotator-0.27.12.drv`.
- The documented explicit procedure was exercised only in that disposable checkout. Changing the declared vendor revision to `30e001e67438ab6ba024fa8d4f2e9be0ba7548af`, then running `nix flake update plannotator-packages`, advanced its lock and vendor Nixpkgs selection. Its actual package derivation remained unchanged. A vendor revision change alone does not imply a changed package derivation.
- A subsequent disposable patch-header change produced derivation `c73gfj8j8pqbxn0nyy4jkwa2a7y2qh95-plannotator-0.27.12.drv` and output `/nix/store/4amxli9pxmpapm76r5kh4bvj16rm9nrz-plannotator-0.27.12`. `nix build --dry-run --no-link` required that new derivation despite the original output being available. The changed package was not built or selected on a host.
- The exact workflow key-selection script ran against the real checkout and the changed disposable checkout. It produced distinct `plannotator-v1-x86_64-linux-` keys ending in the respective derivation basenames.
- The disposable checkout and all local glob-smoke data were removed. The production source selection and downstream patch stayed unchanged.

## Cache scope and provenance

- Restore and save use [`cache-nix-action` v7](https://github.com/nix-community/cache-nix-action/releases/tag/v7), pinned to `7df957e333c1e5da7721f60227dbba6d06080569`. The action supports Determinate Nix and requires Nix 2.24 or newer plus SQLite 3.37 or newer. Native runtime compatibility remains a CI gate.
- The action prepends `/nix` to configured paths. Effective patterns are `/nix`, `!/nix`, `/nix/store`, and `/nix/var/nix/db`.
- A throwaway `@actions/glob` 0.5.0 smoke used the toolkit's `implicitDescendants: false` setting against a fixture store. It returned exactly the store and database directories. A real tar archive contained those directories and their fixtures, but excluded the installer receipt and profiles.
- The pinned action's [archive exclusions](https://github.com/nix-community/cache-nix-action/blob/7df957e333c1e5da7721f60227dbba6d06080569/src/utils/action.ts) retain only `db.sqlite` in the database directory. Installer metadata can contain a GitHub token and is outside the included roots.
- The repository's workflow permission API reported `default_workflow_permissions: read` and `can_approve_pull_request_reviews: false`. The workflow adds no token permissions, secrets, cross-ref promotion, or host cache trust.
- Only cache restore/save steps tolerate failure. Package builds, the Darwin guard, and the existing native checks remain required. Save uses `success()` and excludes primary-key hits. Runtime miss and failed-check behavior still require CI evidence.
- The package output link stays live during CI-only garbage collection. The configured 2 GiB target is not a hard cap when live roots exceed it. Actual compressed size and retention remain CI gates.

## Pending native evidence

Ordered Linux formatting and all applicable flake checks passed, including the Korolev system build. The first formatting command corrected list spacing and exited nonzero; the subsequent ordered run passed. Actionlint 1.7.12 and strict OpenSpec validation also passed.

Mac SSH timed out before the verification snapshot could be transferred. New Darwin execution, cold and warm native CI runs, actual cache publication and restore, compressed sizes, timings, and unavailable-cache execution remain unverified at this checkpoint. No host activation or workstation garbage collection occurred.
