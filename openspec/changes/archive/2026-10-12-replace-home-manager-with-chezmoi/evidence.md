# Implementation evidence

## Scope and verification boundary

Implementation is confined to the dedicated `feat/replace-home-manager-with-chezmoi` worktree. Its retained pre-cutover baseline is `73dc0132246ff531a9bbe5f8559213df4d3518f7`. No host activation, real-HOME chezmoi apply, production decryption, provider login, sudo, publication, merge, or OMP/plugin/configuration change was performed. Host-state capture, generation retention, production secret equality, live consumer/application checks and recovery rehearsal remain integrator-owned gates.

The owner-provided ciphertext is retained exactly at `home/dot_config/private_credentials/encrypted_private_{fastmail-token,cloudflare-dns-token,cloudflare-workers-token}.age`. Checks validate its inventory/framing without an identity; authenticity, recipient access and plaintext equality are not inferred from framing. Synthetic age identities exercise actual built-in decryption separately. Ghostty remains a Mac cask/Dock application; its configuration/theme are chezmoi-owned. Herdr remains in both user package sets; its integration is owner-installed, never activation- or chezmoi-managed.

## Exercised gates

The completed implementation passed the following sequential Linux/remote-builder gate, including the final canonical Zed data, executable-path probe and platform secret-exclusion assertions:

```sh
nix fmt
nix fmt -- --fail-on-change
nix flake check --print-build-logs
nix build .#nixosConfigurations.korolev.config.system.build.toplevel
nix flake check --all-systems --print-build-logs
nix build --no-link --print-build-logs --impure --expr \
  'builtins.attrValues (builtins.getFlake "git+file:///home/user/src/github.com/glockyco/nix-config-chezmoi").checks.aarch64-darwin'
nix build .#darwinConfigurations.macbook-pro.system
```

All commands succeeded. The explicit foreign-system collection is necessary: this installed Nix evaluates both systems for `flake check --all-systems`, but builds the local system's checks only. The collection actually built the Darwin checks on `ssh-ng://glockyco@macbook-pro`, including rendered source, secret fixtures, Air/desktop SSH, container profile, resource/helper behavior, and formatting. Both system closures built without activation.

`openspec validate replace-home-manager-with-chezmoi --strict` passed. The repository OpenSpec contract check also passed; its informational pre-existing requirement-length warnings are not suppressed.

### Native Mac checkpoint

Commit `f753116` was copied as a Git bundle into a Mac temporary directory, cloned on `feat/replace-home-manager-with-chezmoi`, and checked using installed Nix through `ssh macbook-pro-batch 'zsh -lic …'`. The following commands ran sequentially and all exited 0:

```sh
nix fmt -- --fail-on-change
nix flake check --print-build-logs
nix run .#check-darwin-build-plans
nix build .#darwinConfigurations.macbook-pro.system
```

Formatting reported no changes. The native flake check built the changed checks/system and reused previously built helper checks. The build-plan guard reported **66 outputs, none reaching a forbidden source build**. The native Darwin derivation was `/nix/store/65lsq5y4hj10fdjz8f9hnh2gklz98qwg-darwin-system-26.05.c3e90c8.drv`, with output `/nix/store/0c61k44br595azi5970xds9xb2sx3fia-darwin-system-26.05.c3e90c8`.

An additional local sequential formatting/flake/Linux-system/all-systems/foreign-Darwin-checks/Darwin-system loop also passed. Its documentation-only working-tree state produced Linux output `/nix/store/bs7hb6cx2c4iik5j0j0q7kcppqa0c644-nixos-system-korolev-26.05.20261002.774debe` and Darwin derivation `/nix/store/x442bw52fxrx2s053f65n119kvfyhcj3-darwin-system-26.05.c3e90c8.drv`; these are not conflated with the clean committed checkpoint. Comparing the identical committed revision explicitly passed:

```sh
nix eval --raw --impure --expr \
  '(builtins.getFlake "git+file:///home/user/src/github.com/glockyco/nix-config-chezmoi?rev=f753116cce2eb6b3cd8c79b50b28eeb9ffb141f2").darwinConfigurations.macbook-pro.system.drvPath'
```

It returned the exact native Mac derivation `65lsq5y4hj10fdjz8f9hnh2gklz98qwg`. Documentation commits/dirty working trees change system configuration-revision metadata, so activation must build the final owner-reviewed revision rather than reuse a prior differently labeled closure.

The first SCP transfer failed because the batch endpoint rejected the SFTP subsystem (`subsystem request failed on channel 0`). It was not retried or hidden, and no SSH/server configuration was changed. Binary bundle transfer over the same SSH endpoint's preserved stdin succeeded instead. Both attempted Mac temporary directories and both local bundle directories were removed, including failure cleanup. This finding means future batch SFTP/SCP expectations need explicit integrator investigation; command transport/build access worked.

## Real-source and behavior coverage

- Per-host checks copy the real tracked source, initialize/reinitialize in isolated HOME/XDG directories, preserve checkout-root sourceDir and explicit host, reject unknown hosts/target overlap, and apply/verify twice with unchanged contents, modes and mtimes. A deliberately corrupted real Git template is rendered/applied successfully and then rejected by the effective configuration assertion.
- Shared TOML imports are typed/asserted in Nix; identity/path edits reach templates, invalid facts fail, and a no-role Darwin fixture has no optional app/container/Air setup. Cross-platform facts, not Home Manager aggregation, are the quality contract.
- Zed's common settings/theme/font facts now have one TOML declaration consumed by chezmoi and the existing Windows Nix adapter. The Mac resource manifest exports the independently derived Nix settings, and effective modified settings are compared leaf-by-leaf with that manifest.
- Installed user derivations are checked against the exact host package-set instance. Native zsh/direnv/nix-index integrations, login registration and fzf tty guarding retain their effective assertions. Detached-stdin login shells are exercised with installed user tools.
- Tern bundle PATH resolution is exercised by a unique executable inside a disposable, explicitly declared `Tern.app`; actual vendor application availability and interactive behavior remain live gates. Linux and Windows production-source exclusions are exercised with normal (not check-mode) selection, without an identity.
- Disposable Git repositories exercise global/work/GitHub identities and repository-local overrides. gh authentication, SSH private keys, history and OMP state remain unmanaged.
- `ssh -G` and pin fingerprint checks exercise interactive and batch endpoints without connecting: stdin/authentication, strict pins, timeout, PTY/master/control-path/persistence, Secretive/YubiKey separation, and separate root builder identity.
- Installed Neo/FileTypes/shortcut/font helpers are invoked only through allowlisted doubles in setup fixtures. Dry runs do not execute helpers; relevant helper/resource hashes rerun scripts; unchanged scripts skip; a helper failure stops apply. Real helper package behavior tests remain in the matrix.
- Pure packaged JSONC/Zed and Karabiner filters preserve undeclared keys/profiles/rules, initialize absent files, reject malformed input without replacement, deduplicate managed rules and preserve repeat-apply mtimes/private modes. Missing and duplicate pinned Karabiner descriptions fail evaluation.
- Colima checks parse the actual rendered YAML/environment and retain resources, architecture, mounts, client closure, Compose, immutable images and lifecycle/socket/agent prohibitions. Air's installed mount helper has offline behavior tests and the native agent retains Aqua/60-second settings.
- The installed darwin-switch override is behavior-tested for nonroot user apply, selected-generation command lookup, switch/apply failure propagation, apply ordering and closure diff; its root-refusal guard is present, but no actual root invocation was authorized or exercised. Fastmail's installed package uses the new default credential path and preserves explicit/environment overrides. Synthetic DNS/Workers helper consumers exercise success and clear missing-file failure without logging values.
- Secret inventory tests cover armored/binary age, malformed/truncated/plaintext/missing/nonprivate sources, exact names/attributes and path-only diagnostics; three synthetic secrets apply/verify idempotently with 0600 files/0700 directory. Production identities/ciphertexts are never used for decryption.

## Offline pre-cutover configuration comparison

The retained committed flake was evaluated with `nix eval --json --impure --expr` against `git+file://…?rev=73dc0132246ff531a9bbe5f8559213df4d3518f7`, selecting only generated nonsecret theme/configuration sources. A harmless runCommand input collection realized missing Ghostty theme/configuration artifacts through the Mac builder; it did not build or run old activation or secret decryption. Those immutable sources were compared with the actual new per-host rendered check outputs.

Both platforms' bat theme, delta theme, eza theme, fzf theme and zsh highlighting asset bytes match the retained outputs exactly. The Mac Zed and Ghostty theme assets match exactly too. Bat's theme arguments are equivalent after shell parsing (single versus double quote style); Ghostty's settings match as parsed key/value data. Each platform's complete generated Starship TOML data, including the powerline preset and truncation/duration overrides, matches exactly. Colima YAML text differs in layout; its exhaustive rendered semantic gate passes. Full upstream licenses and pinned provenance are retained under chezmoi source. This is an offline committed fixture comparison, not a claim that live application state was captured.

The old generated managed-target inventory also exposed implicit HM Git, direnv, Linux environment/fontconfig/tray files. `home/.chezmoiremove` declares only the superseded active configurations. The source check seeds immutable old symlinks, verifies destination removal and unchanged source contents. Inert cache/marker scaffolding is deliberately left for post-acceptance integrator cleanup.

## Responsibility-map review

Every row in the supplied `hm-inventory.md` is accounted for by the design's responsibility map, reviewed against the implementation. Portable binaries belong to shared/platform/role `users.users.<name>.packages`; native modules alone own shell plugins/direnv/nix-index; chezmoi alone owns portable files, SSH pins, browser manifests, app modify files and user setup. Native Darwin roles own system preferences, immutable resources, launchd, fonts, PostgreSQL and package installation; resource helpers do not write user destinations during system activation. Runtime application state/keys/authentication/history remain external. Change-1 OMP responsibilities stay removed. The additional darwin-switch package and implicit HM generated destinations are recorded explicitly; no Home Manager compatibility/import/state plumbing remains.

Current-code searches and module-import checks found no obsolete active Home Manager, sops-nix or Catppuccin input consumers. Historical archived references and migration documentation are evidence, not active owners.

## Findings corrected during implementation

Failed checks were treated as findings and fixed, not suppressed:

- Ruff rejected a lambda assignment; it became a named function. Nix rejected repeated dynamic user attributes; they were combined into one user declaration.
- A package assertion incorrectly required root/system Git on Linux, where the previous declaration was Darwin-only; installed user Git remains checked on both, and Darwin root/system Git remains checked. The old root builder check still expected user endpoints in system SSH; it now checks root-only builder state, while rendered checks retain every migrated user endpoint assertion.
- An individual Python store-file test lost its sibling module import; the test input now preserves the check directory. Synthetic age configuration needed a recognized `.toml` suffix.
- Init's prompt label did not match the documented CLI key; it now uses `host`. The config template needed explicit string conversion of chezmoi's destination AbsPath before overlap checking. Fixture source roots copied read-only needed explicit writable permissions for isolated init.
- The installed darwin-switch override was initially missing from the user package list; it is now installed and checked. ShellCheck caught export-with-command-substitution; the wrapper now assigns before exporting.
- No-role matching falsely treated the vendored Zed license as an app destination; assertions now match exact destination prefixes. Ignore patterns now use actual script target names rather than source attribute prefixes.
- PyYAML rejected Colima list indentation caused by template whitespace trimming; the real template preserves mount indentation and the semantic container check subsequently passed.
- Review found common Zed facts duplicated between the new template and the existing Windows adapter. They were extracted to shared TOML without changing Windows-specific behavior, and the rendered app configuration now checks against Nix's derived resource data.
- An attempted baseline build expression used JSON list syntax, then raw source values that were not derivations; a harmless input-collection derivation correctly realized only the selected nonsecret artifacts. A byte comparison flagged only bat quote style; semantic parsing confirmed equivalence rather than hiding an asset mismatch.

## Integrator procedure and unresolved live gates

Before either host's switch, complete tasks 1.1–1.2: retain the current native and HM generations against GC; capture every old managed destination's type, target and mode plus absent paths; create permission-preserving resolved-content backups in a local 0700 directory outside the checkout on encrypted storage. Include Zed/Karabiner UI files, existing chezmoi config/persistent state, user LaunchAgents and affected Mac preferences/layout/FileTypes destinations. Keep identities and existing decrypted credentials local; do not print, export or place them in the repository. Back up all paths listed in `.chezmoiremove` as well. Preserve Colima/PostgreSQL/runtime state without moving or rewriting it.

Mac first, with reviewed owner-assisted system-only activation:

```sh
cd "$HOME/.config/nix-darwin"
# After backups, unload the captured old HM mount agent by its recorded label.
sudo nix run .#darwin-rebuild -- switch --flake .#macbook-pro
chezmoi init --source "$HOME/.config/nix-darwin" --promptString host=macbook-pro
chezmoi --override-data '{"checkMode":true}' diff
chezmoi --override-data '{"checkMode":true}' apply --dry-run
# For each separately confirmed and backed-up HM symlink only:
chezmoi apply --exclude=scripts --force "$path"
# Unload captured old SOPS agent; retire old live definitions but retain backups.
chezmoi apply
chezmoi verify
```

Korolev, only after Mac live acceptance and the active user-manager prerequisite:

```sh
cd "$HOME/src/github.com/glockyco/nix-config"
systemctl is-active user@1000.service
sudo nixos-rebuild switch --flake .#korolev
chezmoi init --source "$HOME/src/github.com/glockyco/nix-config" --promptString host=korolev
chezmoi --override-data '{"checkMode":true}' diff
chezmoi --override-data '{"checkMode":true}' apply --dry-run
# For each separately confirmed and backed-up HM symlink only:
chezmoi apply --exclude=scripts --force "$path"
chezmoi apply
chezmoi verify
```

From the committed baseline, the common candidate file-to-regular replacements are `.zshenv`, `.zshrc`, `.config/bat/config`, `.config/bat/themes/Catppuccin Mocha.tmTheme`, `.config/eza/theme.yml`, `.config/gh/config.yml`, and `.config/starship.toml`. Mac adds `.ssh/config`, `.config/colima/default/colima.yaml`, `.config/ghostty/config`, `.config/ghostty/themes/catppuccin-mocha`, `.config/zed/themes/catppuccin.json`, and the two `Library/Application Support/BraveSoftware/Brave-Browser/External Extensions/{jinjaccalgkegednnccohejagnlnfdag,nngceckbapebfimnlniiiahkandclblb}.json` files. These are candidates from generated configuration, not an observed live symlink manifest: force only those confirmed by task 1.2. Air stays a symlink and app-owned Zed/Karabiner JSON stays a merge; neither merits blanket force. `.gitconfig`, managed pin files, theme helper files and the new credential files are new destinations, not old HM force candidates. Old XDG Git and other `.chezmoiremove` paths are reviewed removals, not force replacements.

Run all live gates in tasks 7–8, including actual Tern/UI/keyboard/handler/SSH/provider checks, repeat-apply mtimes and two-owner recovery. Use secret-excluding diff/dry-run only for preview, never for the real apply. `chezmoi verify` locally decrypts secrets and must stay in the owner-controlled Mac terminal. A system switch or passing build does not prove those gates. Optional Air unavailability must be recorded explicitly. Retain generations/backups until recovery and acceptance pass; do not publish, merge or archive prematurely.

## PR #63 pre-activation review fixes

The four review regressions were demonstrated against the still-unfixed source before restoring the intended implementation:

- Karabiner's new unit fixture failed for both an absent and an existing managed profile: the previously selected unmanaged profile remained selected. The merge now deselects other profiles only when the managed declaration is selected; unit, packaged-command and real-source fixtures preserve their unrelated UI state.
- The synthetic encryption check failed with `external age must not be invoked by chezmoi` and exit status 97 when a failing `age` executable was first on PATH. Both the init template and synthetic config now set `useBuiltinAge = true` at top level, before `[age]`. The stub remains first on PATH throughout chezmoi apply/verify/reapply and synthetic consumer rendering.
- The Mac real-source check failed with `apply widened private Brave ancestor permissions: Library`. Both manifests now live beneath `private_Library/private_Application Support/private_BraveSoftware/private_Brave-Browser/private_External Extensions`; target paths are unchanged. The fixture precreates every ancestor at 0700 and requires every mode to remain 0700 after apply. Destination-based ignore rules stay unchanged apart from a clarifying comment.
- After the ancestor fix, the Mac real-source check failed with `Tern CLI or local-bin precedence lost in zsh -l -c`. The declared bundle PATH now loads in `.zshenv` under the same Darwin/desktop guard. Interactive `.zshrc` re-prepends remain ahead of Homebrew, with `~/.local/bin` first. Both non-interactive and interactive login shells resolve a disposable declared bundle's `tern` and assert local-bin precedence.

After all four fixes, these requested gates ran sequentially and exited 0:

```sh
nix fmt -- --fail-on-change
openspec validate replace-home-manager-with-chezmoi --strict
nix flake check --print-build-logs
nix flake check --all-systems --print-build-logs
```

Formatting reported 0 changes; strict OpenSpec validation passed. As at the prior checkpoint, installed Nix's all-systems flake check evaluated Darwin but did not build foreign-system checks (`running 0 flake checks` after local checks were already built). The following additional command then exited 0 and actually built the complete Darwin check collection on the configured Mac builder, including the updated source render, Karabiner command and synthetic encryption checks:

```sh
nix build --no-link --print-build-logs --impure --expr \
  'builtins.attrValues (builtins.getFlake "git+file:///home/user/src/github.com/glockyco/nix-config-chezmoi").checks.aarch64-darwin'
```

The passing Mac source check output was `/nix/store/vj2v53bj8ywjmxxhbgbmq7s4yby0r8ip-check-macbook-pro-chezmoi`; its derivation was `/nix/store/pjjlnm148h5q8h892krnqm6s0rqg5l0c-check-macbook-pro-chezmoi.drv`. This evidence entry was added after the gates; it does not claim live activation or production secret access. No host activation, real-home apply, production decryption, push or publication was performed.

## Korolev live cutover (tasks 1.2, 8.1-8.4), 2026-10-07

Korolev went first, before the Mac. The hosts do not depend on each other, and the Mac's encrypted credentials and application settings carry more cutover risk, so its attended session follows the Korolev rehearsal.

Capture (1.2): system generation 54 (`7d2be25`) and Home Manager generation `/nix/store/p1mhpw66bw082nhgdvgqmsd9c1pfdgvp-home-manager-generation`, pinned by an indirect GC root in the 0700 directory `~/.local/state/hm-cutover-20261007-2041`. That directory holds the 14-link manifest (`hm-symlinks.tsv`, path and target), their dereferenced contents, and copies of `~/.ssh/config`, `known_hosts` and the Git and gh directories. No chezmoi config or state existed before.

Activation (8.1): `user@1000.service` was active and `sudo nixos-rebuild switch --flake 'git+file://…?rev=b5a2738…#korolev'` produced generation 55 and stopped `home-manager-user.service`. `chezmoi init --source ~/src/github.com/glockyco/nix-config --promptString host=korolev`, then `chezmoi --override-data '{"checkMode":true}' apply --dry-run` showed deletions only for the 14 backed-up Home Manager links. `chezmoi apply --force` and `chezmoi verify` exited 0. No failed system or user units.

Session (8.2), fresh login shells run from the Tern for Windows WSL session:

- `$path[1]` is `~/.local/bin` and `omp` resolves to the official binary; no startup errors or zle warnings in detached, interactive and pseudo-terminal shells.
- Interactive shells: HISTSIZE/SAVEHIST 100000, share/append/ignore-all-dups/ignore-space, autosuggestions, highlighting, zoxide, direnv with nix-direnv 3.1.2, eza aliases, Starship; fzf widgets only with a terminal (`^R` is `fzf-history-widget`). Non-interactive `zsh -l -c` reads no `.zshrc`, so it has none of these, as before.
- Tools: chezmoi, openspec, plannotator, herdr, uv, gh, markdown-oxide, nixd, pyright-langserver, svelteserver, texlab and typescript-language-server resolve from the user profile; Roslyn is absent.
- Git: global work address, the GitHub no-reply address below `~/src/github.com/`, local `user.email` overrides both. GitHub HTTPS through `gh auth git-credential`: private `glockyco/phd-thesis` `ls-remote` succeeded without a prompt. GitLab repositories use SSH and `ls-remote` succeeded. GitLab over HTTPS fails as before the cutover: the GPG password store holds only the Overleaf credential and no GitLab OAuth client is configured. The Git credential configuration equals the pre-cutover Home Manager file apart from store paths becoming PATH lookups.
- SSH: `macbook-pro` and `macbook-pro-batch` resolve to user `glockyco`, `macbook-pro.tail8768af.ts.net`, `~/.ssh/id_ed25519`, the pinned `builder-known-hosts`, no control master; the batch endpoint sets `BatchMode yes` and no TTY. `exit 23` propagated. `sudo tailnet-builder-check` built nonce derivation `tailnet-builder-probe-1791399669-416400-2246036-10910` on the Mac (arm64) and passed.

Repeat (8.3): the same-revision switch selected the same system path with no failed units; `chezmoi status` and `chezmoi diff` were empty before and after `chezmoi apply`, and `chezmoi verify` exited 0. Rootless Podman: Compose 5.4.0 against the user socket, a failing dependency stopped the job, a bind-mounted file belonged to `user`, and `docker compose down` cleaned up. `/mnt/s` listed with `mnt-s.automount` active. A fresh official OMP session opened `https://example.com/` in the managed browser with `relay: false`: title `Example Domain`, screenshot, no missing-library error. Non-loopback listeners belong only to systemd-resolved LLMNR, tailscaled, and the WSL DNS-tunneling address.

Recovery rehearsal (8.4): chezmoi config and state were set aside, the 14 manifest links recreated, and `sudo nixos-rebuild switch --rollback --no-reexec` selected generation 54, which started `home-manager-user.service` without collisions. On it `~/.zshrc` was Home Manager's link, chezmoi was absent, Git identities and user/root SSH to the Mac (exit 23) worked, and OMP's executable, plugin registry, cache and settings fingerprints were unchanged. Returning: the switch to `b5a2738` reselected generation 55, chezmoi config and state were restored, `chezmoi apply --force` on the manifest paths followed by `chezmoi apply` and `chezmoi verify` succeeded with an empty status, and OMP state was again unchanged.

The rehearsal exposed three Home Manager links that survive the cutover because nothing replaces or removes them: `.cache/.keep`, `.cache/nix-index/files` and `.local/state/.keep` (the Mac also has `Library/Fonts/.home-manager-fonts-version` and an empty `Library/Fonts/HomeManager`). Once the pinned generation is collected they dangle. The system nix-index wrapper bundles its database, so `.chezmoiremove` now retires all of them.

## Mac recovery capture and task-status reconciliation (2026-10-09)

Owner-reported Mac capture, recorded by the cutover runbook: the local backup is `~/.local/state/hm-cutover-20261007-2102`, with 21 manifest links, native system generation 131, and retained Home Manager generation `/nix/store/iqcvifcdwh4ik9bshlmj8myxj4d898g4-home-manager-generation` pinned against collection. Together with the Korolev capture above, this completes task 1.2; it does not establish Mac activation, production secret equality, application acceptance, or recovery rehearsal.

Task 1.1 is supported by the responsibility-map and current-code review above. Korolev's exercised live gates complete 8.1–8.3. Task 8.4 remains open because its Mac rehearsal is not recorded. Mixed tasks 3.5, 4.3, 6.2 and 6.5 retain their implementation-era status: live agent retirement/recovery retention, authorized main-spec synchronization and remaining generation/publication decisions are not inferred from the static gates. Task 4.2 and Mac tasks 7.1–7.8 require recorded local secret/live acceptance; task 8.5 requires both hosts' full acceptance and final retirement/archive.
