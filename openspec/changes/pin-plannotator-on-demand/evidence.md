# Maintenance verification evidence

The entries before the final supersession section describe the earlier patched-package and cache implementation. The final section records the current on-demand-only scope and remaining acceptance boundaries.

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

## User-approved on-demand-only supersession (2026-09-08)

The user subsequently approved removal of the downstream client-lease patch and custom CI caching as disproportionate. The commit-qualified `plannotator-packages` input remains required. Both hosts must select the unmodified vendor package directly, without the local override. Other tools retain their existing input ownership.

The preceding cache implementation and verification notes describe historical work only. The original cache tasks 2.1–2.3 and cache acceptance tasks 3.2–3.3 are superseded. Cold/warm runs, cache publication, restore failure experiments, compressed sizes, and timings are cancelled acceptance requirements, not successful checks. Existing native CI checks and the Darwin build-plan guard remain required.

The independent input and complete-updater experiment remain useful evidence, but their recorded outputs contain the removed downstream patch. The final stock selection needs fresh host identity checks and a disposable complete-lock-update experiment. Earlier Linux checks do not satisfy native gates for the revised selection. Unrun Darwin gates remain open.

Closing a browser tab can leave a review pending. `/plannotator-cancel` is the supported recovery, and session navigation or shutdown also cancels the owned review. No automatic tab-close guarantee, approval mode, new timeout, or fallback replaces the patch. The separate visual-feedback change retains its browser, activation, network, and rollback gates.

This artifact revision ran no validation, build, browser, or activation command. Final package selection, documentation, native checks, and strict validation remain open in `tasks.md` until actual verification.

## Final stock-package verification (2026-09-08)

Both host compositions were evaluated and asserted equal to their unmodified vendor package and flake package output. Linux selects `/nix/store/lg5dqz4gcm3wxvmqjc2zgya34bysmb3r-plannotator-0.27.12`; Darwin selects `/nix/store/znni5qin7vc6b2krrsmnpgn6ckwgh06v-plannotator-0.27.12`. The version remains `0.27.12`. Vendor revision is `b1c9a31450a814e50cddc3ab683b05c1dff7bb01`. Stock derivations are `/nix/store/6fxb8mvxmhlp6x14ppyfnds0gjk4c9y2-plannotator-0.27.12.drv` on Linux and `/nix/store/9sxiw138yl1hsmkgq3vyyrqjy6bqdawn-plannotator-0.27.12.drv` on Darwin. The local patch and override are deleted. The original CI workflow is restored without custom cache steps.

A disposable checkout of staged tree `09d4371e6ac5655b3cafc87a841d2af7ab127651` ran `nix flake update` and `nix flake update plannotator-packages`. Six unrelated root inputs advanced. The normalized locked vendor graph, declared revision, version, and stock Linux output stayed unchanged. The disposable checkout was removed.

The stock Linux executable and wrapper built successfully. `verify-personal-omp` reported OMP 18.1.14, the existing immutable plugin, the stock executable above, and current Herdr integration v8. A fresh candidate-wrapper session in an owned Herdr pane completed document and last-response feedback through managed Linux Chromium. The model replied `Stock feedback received.` and `Last-response feedback received.` respectively. The UI exposed feedback rather than approval controls.

A third review was opened and its browser tab closed. `/plannotator-cancel` reported cancellation and removed its loopback listener. The document remained byte-for-byte unchanged. The owned pane, browser tabs, fixture data, and screenshot were removed. No adapter code, source generation, or active host configuration changed. These checks do not claim Windows-browser or Mac-native acceptance.

Obsolete cache runs were cancelled, PRs #30 and #31 were closed without merge, and their task-owned remote branches were removed. The patched PR #29 run was cancelled because its candidate is superseded; the simplified candidate will use the same release PR.

Ordered formatting and all applicable flake checks passed on both native systems for the stock selection. Linux also completed the Korolev system build. Mac verification used staged tree `d19f4130f8bce9d7ee7eee41f5eceed934566410`. Its initial SSH transport became stale after flake checks passed; a fresh connection completed the remaining commands. The Darwin guard inspected 37 outputs with no forbidden source build. The explicit system build returned `/nix/store/gjpc0anw6dr2szcy51mg72mcrshqfw24-darwin-system-26.05.c3e90c8`, and the stock executable reported `plannotator 0.27.12` on the Mac. The owned remote snapshot was removed.

Strict validation passed for both workstation changes and the companion contract. Companion documentation was published as `ee7cf80`; its executable payload and the workstation plugin pin did not change. The simplified workstation candidate was committed as `eea0044` and published to PR #29. Protected CI, activation, Windows/macOS native browser acceptance, and rollback remain separate release gates. No host was activated.
