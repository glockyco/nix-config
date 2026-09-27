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
