# Role separation baseline

The parent commit is `298da8220d6633f8c194fb91da92bab04dabc8ef`.
The SHA-256 of `flake.lock` is `f0d738d46e2fb144cae9e471f53a89f2c1a4772f9b65cd72f6bb44b983ef2871`.
The parent includes the owner's WSL Git credential change; the earlier Korolev derivation is not this baseline.

`/tmp/fleet-drv.nix` calls `extendModules` for each host and forces the same `system.configurationRevision` with `lib.mkForce`.
Two consecutive `nix eval --impure --json -f /tmp/fleet-drv.nix` calls returned identical results:

| Host          | Pinned `system.build.toplevel.drvPath`                                                        |
| ------------- | --------------------------------------------------------------------------------------------- |
| `macbook-pro` | `/nix/store/5yif3pzimw7gk54pxnmz2i9868zrqd9c-darwin-system-26.05.c3e90c8.drv`                 |
| `korolev`     | `/nix/store/ll3vw2hxd8j2xj8nvhrin7532xvja5qn-nixos-system-korolev-26.05.20260903.a5cc6f2.drv` |

`nix build .#windows-configuration --no-link --print-out-paths` returned `/nix/store/smc4vlqga3lvrcpss5f84yq5mn7haxpx-windows-workstation-configuration`.
`shasum -a 256 /nix/store/smc4vlqga3lvrcpss5f84yq5mn7haxpx-windows-workstation-configuration/*` returned:

| File                           | SHA-256                                                          |
| ------------------------------ | ---------------------------------------------------------------- |
| altsnap-package.json           | 868d51eddc97c86314cc5d169c71261bda0a39f7dd840fcfed9b71338242dd45 |
| altsnap-settings.json          | 574ce4c1b36bedb8ea18ad19eafb59ca8e1e9ec21351e563ecd87cec23689e93 |
| apply-kbdneo.ps1               | 872e36b8c5eefcf8a5b13b94f7aa626cc59a8d1846513b2e0168056835b5e325 |
| apply-zen-policies.ps1         | 0e25199c5dd1e22e37347520ee66f48abf8870520819ce44dca2a690b69e3a6e |
| configuration.winget           | bbe0310b0cd4ad2c89c933e8df49c63c378a1751964bbfad2f39741efe2e1e98 |
| fork-wslgit.json               | 113fca19dbc0948e099e5af1fea859fc72bb437c859fcee1afdebf334e835003 |
| kbdneo.json                    | 8b4f20e2305ea346a13fdbaef5b1e620e22485a24b5272d69f92d535463aac6a |
| power-toys-settings.json       | 1e0b9870a16e54cabbf874aeabebfc7da5adaed2d72a948a4ea1e52f5ef0872d |
| reneo-settings.json            | 47227a71c139b6deb2e51cfa5f80af983f7a4d4d90ce5f1067068d80045e6ce7 |
| start-reneo-elevated.ps1       | 6885707577d59aded209933fdc9fbb2510dab6ef511b8176f62e94fc4fe5dbaf |
| terminal-settings.json         | 23676aaa3fddac50e235291b1fcaf4272c0b8fdef1b7ba430d19262309ba535a |
| zed-catppuccin-theme.json      | 2dccb9fb3ff888e646407b4f84d400304553e0d9a9688ac75d0f9fcd3f8bdf6a |
| zed-keymap.json                | d2fee38c50c624ce07fa50bde1dadc4ad9fc09927ae7e6fb20b4efc1f2e5bd1b |
| zed-settings.json              | f25265765de273f5e57b28b36cc0915efa8ce70524573e2d4e60b326453618f0 |
| zen-catppuccin-logo.svg        | b41be8bf6c8659c532a0b1b984488696073adb31aec7a089211d4f4a7ecd9a83 |
| zen-catppuccin-userChrome.css  | 98ba97510bf2ecd8636686238242cb0f2e43552e2bb93c520818ed89da92189b |
| zen-catppuccin-userContent.css | 297a3c45e624792892482ab45552625b2765e6d44947e878fe5c5731eb7cd44a |
| zen-catppuccin.json            | 5c24f09462836fd70b5c0f8527e09f998e12a329f05c568764bf04015707f1a7 |
| zen-policies.json              | 3a46acc9e10964ac66b4fd33d5fb94c9a6a5d9aa0945ec83d72f174e91aae310 |

`nix eval --impure --json -f /tmp/role-baseline-facts.nix` evaluated the following facts without decrypting secrets:

- SSH settings include `air` and `air-batch` for `joaichberger@macbook-air`, plus `desktop` and `desktop-batch` for `User@desktop` with the immutable desktop host pin and an eight-second batch timeout. The Air batch uses no control master and retains stdin.
- The Air agent uses `/nix/store/5fijr0p54hiv2yfqicb1pmsjcnkzjzgy-mount-air-share`, starts at login and every 60 seconds, and logs under `/Users/glockyco/Library/Logs`. The `~/Air` link source is `/nix/store/r6xpcdy1z2kfzlr6zxrq7xbb565x32ff-hm_joaichberger`.
- The Colima profile is `/nix/store/c7riddq7vbf8a6xmz66hzk39rz7g02z0-colima-default-profile.yaml`. It declares 8 CPU, 16 GiB memory, 150 GiB disk, `aarch64`, and a writable `/Users/glockyco` mount.
- The system screenshot location and Home Manager activation use `/Users/glockyco/Pictures/Screenshots`.
- Mac Git uses `Johann Glock` and `11704293+glockyco@users.noreply.github.com`; Korolev uses `Johann Glock`, `johann.glock@scch.at`, and a `gitdir:~/src/github.com/` include with the no-reply address. Its Git credential helper remains Git Credential Manager with GPG storage and a generic Overleaf provider.
- Determinate Nix has `nix.enable = false`, pinned `nixpkgs` registry, and trusted users `root` and `glockyco`. Korolev has its pinned registry, channels enabled, and `nix.gc.automatic = false` and `nix.optimise.automatic = false`.
- PostgreSQL uses `/var/lib/postgresql/17` and version `17.11`.
- SOPS uses `secrets/fastmail.yaml` and runtime files for `token`, `cloudflare-dns-token`, and `cloudflare-workers-token` under `/Users/glockyco/.config/sops-nix/secrets/`. No decrypted value entered this record.

## Typed host declarations

After adding host facts, `nix eval --impure --json -f /tmp/fleet-drv.nix` returned the two baseline derivations unchanged. `nix eval --impure --json -f /tmp/role-standalone-hosts.nix` evaluated only `modules/fleet/host.nix` and each `hosts/<name>/host.nix`; it returned `macbook-pro` as `aarch64-darwin`/`darwin`/`glockyco` and `korolev` as `x86_64-linux`/`nixos`/`user`.

`nix eval --impure --json -f /tmp/role-host-probes.nix` returned `true` for both complete declarations and `false` for omitted `host.name`, `host.system`, `host.kind`, `host.username`, `host.git.authorName`, `host.git.defaultEmail`, `host.git.githubNoReplyEmail`, `host.darwin.applications[].rationale`, `host.darwin.containerProfile.{cpu,memory,disk}`, and mount location or writable flag. Duplicate non-null casks, application paths, and Dock positions each returned `false`. Zero CPU, memory, and disk each returned `false`. The probe did not modify a declaration or evaluate a full host configuration.

## Nix policy

The pinned Determinate module has `determinateNix.determinateNixd.garbageCollector.strategy` with `automatic` or `disabled`, and forces `nix.enable = false`. The pinned nix-darwin GC and optimiser require `nix.enable = true`; its `auto-optimise-store` warning says Darwin stores can be corrupted. There is no supported weekly Determinate schedule or optimiser option. The design and requirement now state this limit.

After the shared policy adapters, `nix eval --impure --json` reported the same pinned registry source for both hosts, Darwin `customSettings.nix-path = ""`, Determinate GC `automatic`, Darwin `nix.enable = false`, and trusted users `[ "root" "glockyco" ]`. Korolev reported `nix.channel.enable = false`, `nix.gc.automatic = true`, `nix.optimise.automatic = true`, and `dates = [ "weekly" ]` for both. Its builder list remains `[ "macbook-pro" ]`. `systemd.timers.nix-gc.timerConfig.OnCalendar` and `systemd.timers.nix-optimise.timerConfig.OnCalendar` both returned `[ "weekly" ]`.

An evaluation of the pre-policy commit `eee0db9d60f77d7e1374bce33b83bede5c281c09` and the working tree returned the same Korolev account values: `home = "/home/user"`, `isNormalUser = true`, `createHome = true`, and `programs.nano.enable = true`. The pinned nixpkgs default enables Nano and derives a normal user's home from `/home`; the pinned NixOS-WSL module declares the account normal.

The policy evaluation returned `/nix/store/10qazdw2ggj4w5rx6i6gnp7afbkf81kr-darwin-system-26.05.c3e90c8.drv` for the Mac and `/nix/store/mm8a4yvh841ll499vd8pb8d6wgzfljj3-nixos-system-korolev-26.05.20260903.a5cc6f2.drv` for Korolev. These are intentional policy differences from section 1. `nix run nixpkgs#nix-diff -- <old-korolev.drv> <new-korolev.drv>` found the weekly `nix-gc` and `nix-optimise` timer units, removed channel paths and channel activation, and changed the registry record to include pinned revision metadata. The changed NixOS environment derives from those policy settings; Nano and the user's evaluated home remain unchanged. Compare Mac built closures with `nvd diff` at the final build gate.

## Explicit role selection

The Mac imports `desktop`, `postgresql`, `container-client`, and `air-client`; Korolev imports `wsl-workstation`. Neither `modules/darwin/default.nix` nor `modules/nixos/default.nix` imports a role. The desktop role now owns GUI system and user modules; the PostgreSQL role contains the unchanged service and idempotent `install -d` activation. Air-only SSH and SMB modules live in `air-client`. The WSL role carries the owner's GPG agent, Git Credential Manager, `pass`, GPG shell environment, WSL integrations, remote builder, and rootless Podman.

`nix eval --impure --json -f /tmp/fleet-drv.nix` returned the post-policy Mac and Korolev derivations unchanged after the combined role cutover. A temporary package-order drift changed the Mac derivation; `nix-diff` identified reordered Home Manager packages. Explicit Home Manager package ordering restored its exact post-policy derivation path. The Air SSH settings, launchd agent, symlink, Colima source, screenshots, Git settings, and PostgreSQL directory/version were equal to section 1 in a before/after JSON comparison. The SOPS source store path reflects the changed dirty flake source; the declared secret names and runtime paths remain equal.

`nix build .#checks.aarch64-darwin.moduleImports --no-link --print-out-paths` passed with all role directories. Adding a temporary `modules/roles/darwin/desktop/unlisted-probe.nix` made the executable reject `roles/darwin/desktop/unlisted-probe.nix`; removing it made the executable pass. A synthetic Darwin host importing only `modules/fleet`, `modules/darwin`, and its typed host declaration returned no Homebrew casks, Dock apps, PostgreSQL service, Colima profile, desktop SSH alias, or Air alias.

## Host consumers and removable checks

With typed values in system and Home Manager modules, both post-policy role derivations remained identical until the intentional switch and XDG helper changes. The default generated application inventory is 21 casks and nine Dock applications, followed by the small spacer; `persistent-others` is empty. A temporary `extendModules` probe changed the declared screenshot path to `/Users/glockyco/Pictures/Probe`: the system default and Home Manager activation both followed it. The same probe changed Bitwarden's cask, bundle path, and Dock position; the generated cask set removed `bitwarden`, added `bitwarden-probe`, and moved `/Applications/Bitwarden Probe.app` to the last application slot. Changing Korolev's evaluated ghq root to `/home/user/code` changed its Git include to `gitdir:~/code/github.com/`. The temporary overrides were not written to the declarations.

The declared Colima values generated the same `/nix/store/c7riddq7vbf8a6xmz66hzk39rz7g02z0-colima-default-profile.yaml` bytes. The package host platform supplied `qemuArch = "aarch64"`. A temporary CPU override to 12 changed both the profile source and configuration-check derivation; the original scoped Mac container configuration check built successfully.

The Darwin desktop now owns the nix-homebrew shell path fragment. Its generated path still comes from `config.home.profileDirectory`, and the Mac pinned derivation matched the post-policy path. Korolev's pinned derivation changed from `/nix/store/mm8a4yvh841ll499vd8pb8d6wgzfljj3-nixos-system-korolev-26.05.20260903.a5cc6f2.drv` to `/nix/store/0cp2f7gic9fqjf4y8rpxrbsvnyf8x8ia-nixos-system-korolev-26.05.20260903.a5cc6f2.drv`. `nix-diff` isolated the removal of the Darwin-specific `typeset -U path PATH` and Home Manager bin-path adjustment from Korolev's generated `.zshrc`.

Moving `EnterprisePoliciesEnabled` to the Darwin Zen module and removing the Windows renderer compensation returned the same Windows output path as section 1. Recomputed SHA-256 values matched all 19 baseline files. The shared Zen policy now has no macOS-only enablement key.

The packaged `darwin-switch` now embeds `/Users/glockyco/.config/nix-darwin` and `/nix/store/achz6kc1p0hm5y3ca61w1ky4jfjk63qr-darwin-rebuild/bin/darwin-rebuild`; line 12 of the built script invokes that absolute executable after `sudo`. It has no `PATH` lookup for `darwin-rebuild`. The generated Cloudflare Workers and DNS direnv function texts matched the prior evaluated strings byte-for-byte; their files now use `xdg.configFile`. Their `token_file` paths still come from `config.sops.secrets`.

The scoped Air command fixture built successfully. No `host.remote.air`, stable SMB mount, or derived Docker executable was added. The Air role retains `/Volumes/Macintosh HD-1/Users/joaichberger`, and the package still requires `AIR_BATCH_DOCKER`. Separate Air and desktop SSH checks both built successfully. Air package and check selection follows the evaluated Air SSH alias; the desktop check remains separately wired.

`nix build .#checks.aarch64-darwin.secretEncryption --no-link --print-out-paths` passed its fixture cases and tracked encrypted files. A temporarily staged `secrets/probe.yaml` with `nested[0].name` in plaintext made it fail with `secrets/probe.yaml: nested[0].name: plaintext data scalar`. Removing the temporary file and index entry restored the passing check. An in-memory SOPS round trip for each of `cloudflare-workers.yaml`, `cloudflare.yaml`, and `fastmail.yaml` used the Mac recipient and the Mac age key; each decrypted output had the same SHA-256 as its input plaintext. Only success booleans were reported. The prior ciphertext remains unchanged until the owner supplies the offline public recipient.

On 2026-09-26 the Air answered a tailnet ping. Its SSH batch alias authenticated, and `/usr/local/bin/docker` was executable on the Air. The first bounded `air-batch-check` run used its default 15-second command limit and timed out on the detached-stdin command amid variable SSH latency. With the supported `AIR_BATCH_COMMAND_TIMEOUT=45`, the full unchanged package passed its resolved-policy, detached command, remote status 23, read-only rsync transfer, Docker path, Linux Docker inspection, and master-absence probes. The locally installed `~/Air` symlink resolved to `/Volumes/Macintosh HD-1/Users/joaichberger`, and `stat` confirmed the current SMB directory was mounted. No remote Docker or SMB setting was changed.

## Air role boundary

With the Air role selected, `packages.aarch64-darwin` has `air-batch-check`, and the Mac checks include `airBatchCommand` and `macbook-pro-air-batch-configuration`. `packages.x86_64-linux` has no `air-batch-check`.

`/tmp/air-removal-probe.sh` works in scratch worktrees of `542be05` and leaves the main checkout unchanged.

- `deselect` removes only the Air role import from `hosts/macbook-pro/default.nix` and keeps `packages/air-batch-check/`. The Mac exports no `air-batch-check`, and its check list has no Air gate. The desktop, tailnet, personal-OMP, container, tailnet-policy, policy-rejection, fleet-surface, module-import, and secret-encryption checks build with exit 0. The policy still owns `tag:macbook-air`, because the peer entry is separate from the role.
- `delete` removes the complete deletion set: `modules/roles/darwin/air-client/` (`default.nix`, `network-shares.nix`, `ssh.nix`), `packages/air-batch-check/` (`package.nix`, `tests.nix`), `checks/air-batch-config-check.nix`, the Air role import in `hosts/macbook-pro/default.nix`, the `hasAirClient` export condition in `flake-modules/packages.nix`, the `air-batch-configuration` and `airBatchCommand` branches in `flake-modules/checks.nix`, and the `macbook-air` entry in `modules/shared/tailnet-peers.nix`. `git grep` then finds no Air reference outside `docs/`, `openspec/`, and `README.md`. The same durable checks build with exit 0, and the policy owns only `tag:desktop`, `tag:korolev`, and `tag:macbook-pro`. Issue #17 also removes the Air lines from `README.md` and `docs/operations/container-runtime.md`.

The first full-deletion attempt exposed a defect unrelated to the Air: the typed Git email facts reached the tailnet renderer's email guard, so `nix build .#tailnet-policy` failed. Commit `fcd58b4` restricts the renderer to host name, user name, and tailnet facts. The policy stays `/nix/store/ydbn9dyb204vbmascj5lc2ci7a3sw74p-tailnet-policy`, and its `policy.hujson` SHA-256 stays `151e3fd8cb9e0b26de7aea26c5ca98167bfb0998fcf5fde6364aee4e288c4279`.

## Final pinned comparison

At `542be05`, `nix eval --impure --json -f /tmp/fleet-drv.nix` returned Mac `/nix/store/z0q1kf1xga9npaakd831f99dkkinqz5w-darwin-system-26.05.c3e90c8.drv` and Korolev `/nix/store/0cp2f7gic9fqjf4y8rpxrbsvnyf8x8ia-nixos-system-korolev-26.05.20260903.a5cc6f2.drv`.

`nix run nixpkgs#nvd -- diff /nix/store/k6n3wj7cpmdksg1vyy3r6swpqj0lcc1q-darwin-system-26.05.c3e90c8 /nix/store/yfg19cddh44phbkvx5xqha5caw4xnkvn-darwin-system-26.05.c3e90c8` compares the built section 1 Mac system with the final one. It reports one more `darwin-rebuild` reference (the packaged `darwin-switch` now names the pinned executable) and renamed Home Manager derivations for the two Cloudflare direnv helpers, whose file text is unchanged. The closure grows from 5,854 to 5,855 paths (+16, -15, +10.5 KiB). The Determinate settings change (automatic garbage collection, empty `nix-path`) is inside the changed system files.

`nix run nixpkgs#nix-diff --` from the section 1 Korolev derivation to the final one shows the intended NixOS policy: new `unit-nix-gc.timer` and `unit-nix-optimise.timer`, a changed `etc-nix-registry.json`, `NIX_PATH` reduced from `nixpkgs=flake:nixpkgs:/nix/var/nix/profiles/per-user/root/channels` to `nixpkgs=flake:nixpkgs`, removal of the root channel file and the per-user channel `NIX_PATH` fragment, and removal of the Darwin-only `typeset -U path PATH` adjustment from `.zshrc`. The remaining differing derivations (`system-path`, `dbus-1`, `etc`, units, activation) only carry these inputs. Owner task 7.4 builds that closure on Korolev.

Task 7.1 stays open: the Mac closure has an `nvd` explanation, but the Korolev explanation is derivation-level until owner task 7.4 builds that closure.

## Mac gates

| Command                                                            | Exit | Key evidence                                                                                                                                                                              |
| ------------------------------------------------------------------ | ---- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `nix fmt -- --fail-on-change`                                      | 0    | `formatted 101 files (0 changed)`                                                                                                                                                         |
| `openspec validate separate-platform-baseline-from-roles --strict` | 0    | `Change 'separate-platform-baseline-from-roles' is valid`                                                                                                                                 |
| `nix flake check --print-build-logs`                               | 0    | Every `aarch64-darwin` check passed, including `secretEncryption`, both Air checks, the desktop check, and `openspecContracts` (34 items). Linux was omitted as incompatible on this Mac. |
| `nix run .#check-darwin-build-plans`                               | 0    | `45 outputs, none reaching a forbidden source build.`                                                                                                                                     |
| `nix build .#darwinConfigurations.macbook-pro.system`              | 0    | Built without activation.                                                                                                                                                                 |

## Final review

Outside `docs/plans/` and `openspec/`, every Air reference is in the deletion set, `README.md`, or `docs/operations/container-runtime.md`. The Air role's `default.nix` lists that set for issue #17. `packages/windows-configuration/` has no Zen `removeAttrs` compensation; its one `removeAttrs` drops release data from `passthru.declaration`. Homebrew casks and Dock applications derive from `host.darwin.applications`, and no module under `modules/` repeats a host name, user name, home path, time zone, or locale literal. Every relative link in `README.md`, `AGENTS.md`, `docs/operations/`, and the OMP update skill resolves.
