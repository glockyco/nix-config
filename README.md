# nix-config

Declarative configuration for two machines and three operating-system layers. `macbook-pro` is an Apple Silicon Mac that runs Determinate Nix and nix-darwin. `korolev` is an `x86_64` WSL machine, and this repository defines both its NixOS host and a rendered WinGet Configuration document. Both Nix hosts import the same Home Manager user scope.

`hosts/` is one directory per machine, owning that machine's name, user, and the
values that differ per machine, such as the commit identity and `EDITOR`. Each
host directory produces one entry point: `hosts/macbook-pro/` a
`darwinConfigurations` attribute that `darwin-rebuild` activates, and
`hosts/korolev/` a `nixosConfigurations` attribute that `nixos-rebuild`
activates.

`modules/darwin/` and `modules/nixos/` are system scope for their own platform. `modules/home/` is the user scope both Nix hosts share. `modules/windows/` renders one WinGet Configuration document, narrow Zen-policy and native-Neo Administrator scripts, and their review files; Nix builds that artifact but never applies it. `modules/shared/` holds platform-free settings used by more than one renderer. `packages/` holds local derivations.

`modules/home/` holds the user-scope modules any host can import. `modules/home/darwin/`
holds those that need a macOS interface, and only the Darwin host imports them. A module
belongs in the second directory when it names `launchd`, LaunchServices, `osascript`,
`~/Library`, a Homebrew-supplied binary, or `darwin-rebuild`.

No global toolchains: project flakes use `direnv`. Symbolic PathFinder needs JDK 8; current JPF needs JDK 11.

## Use

```sh
darwin-switch                           # macbook-pro: apply, then diff the closure
sudo darwin-rebuild switch --flake .    # macbook-pro: apply, without the diff
nix flake check                         # build, and verify formatting, without applying
                                        # checks only this system; CI covers the others
nix flake update                        # bump inputs
nix fmt                                 # format the tree; see ./treefmt.nix
```

The WSL machine and its Windows layer have their own installation and update procedure. Build the Windows artifact with `nix build .#windows-configuration`, then follow the [WSL runbook](docs/operations/wsl-omp-bootstrap.md) to preview and apply it from Windows. DSC converges resources in place; unlike nix-darwin and NixOS, it has no generation or transactional rollback. Every document resource uses user scope except the official Zen package, whose installer requests elevation. Two Administrator scripts own only Zen's Program Files policy file and the checksum-pinned native Neo keyboard driver. No user setting resolves into the Administrator profile.

`omp` is a Nix wrapper around the `llm-agents` package and the independently pinned
`personal-omp-plugin` flake. Do not run `omp update` or install the personal plugin
through OMP's mutable plugin manager. Update either input deliberately:

```sh
nix flake update llm-agents
# or: nix flake update personal-omp-plugin
nix flake check
darwin-switch
omp --version
```

Home Manager reconciles Herdr and runs a local OMP/plugin verifier on every activation.
Use the [dependency-update runbook](docs/operations/dependency-updates.md) for automation, manual updates, activation, the conditional real-session smoke, and rollback.

Use the [container runtime runbook](docs/operations/container-runtime.md) for Colima startup, acceptance, shutdown, upgrades, recovery, and profile recreation.

## MacBook Air SSH

The temporary MacBook Air has two SSH aliases. Use `air` for an interactive
session. It inherits the shared control master and its one-hour persistence.
Use `air-batch` for unattended commands and protocol clients such as `rsync`.
This alias does not allocate a terminal, prompt for authentication, or create a
control socket. It keeps standard input available for protocol data. A direct
command that does not supply input must detach it explicitly:

```sh
ssh -n air-batch true
```

After a configuration activation, run the bounded acceptance command with the
reviewed Docker executable on the Air:

```sh
AIR_BATCH_DOCKER=/Applications/Docker.app/Contents/Resources/bin/docker \
  air-batch-check
```

Each probe has a 15-second deadline. The command checks detached-input command
completion, exact remote failure status, a read-only `rsync` transfer, read-only
Docker access, and the absence of a persistent master. It removes its local
temporary directory after success or failure and does not write to the Air.
A failure prints recovery commands. Start with these checks:

```sh
ssh -n air-batch true
ssh -G air-batch
ssh -n air-batch /Applications/Docker.app/Contents/Resources/bin/docker info
```

The Docker path is explicit because the Air's non-interactive shell does not
provide Docker on `PATH`.

## Release gates

Run the inactive-generation gates before activation:

```sh
nix fmt -- --fail-on-change
nix flake check --print-build-logs
nix run .#check-darwin-build-plans
nix build .#darwinConfigurations.macbook-pro.system
```

After activation, start Colima and run the real container boundary gate:

```sh
colima start
container-runtime-check
```

Cloudflare projects opt into the SOPS-managed deployment token explicitly in
their `.envrc`; it is never exported to the global shell:

```sh
use flake
use cloudflare_workers
```

Only enable this in trusted projects. The token can edit Workers, D1, Queues,
and Worker routes across all Cloudflare accounts and zones.

Fresh-machine bootstrap, before `darwin-rebuild` exists and while the host has its factory name:

```sh
sudo nix run .#darwin-rebuild -- switch --flake .#macbook-pro
```

Delete `/etc/nix/nix.custom.conf` if Determinate left it; nix-darwin will not overwrite unmanaged `/etc` files.

## Architecture

The canonical cross-repository design for OMP, Herdr, OpenSpec, language
servers, project environments, and the planned frontend and memory experiments
is [Personal OMP Environment Architecture](docs/architecture/personal-omp-environment.md).
Resume multi-session work from its current-state table, then read the named
repository's active OpenSpec change.

## Manual steps

macOS cannot declare these:

- Add *Deutsch (Neo 2)* under Input Sources, then restart; Apple TN2056 and neo-layout.org require a fresh login session after layout installation.
- Approve Karabiner's driver extension, Input Monitoring and login items.
- Confirm the default-app prompts on first switch.
- Paste the Rectangle Pro licence code into the app and grant it Accessibility.
- Grant LaunchBar Accessibility and confirm its search shortcut is `⌘Space`. `defaults.nix` frees
  the key from Spotlight, but LaunchBar cannot sync a hotkey, so check it per machine. Avoid Option
  for any rebinding: Neo 2 emits it to build layers 3 and 4, and hotkey masks cannot tell left from
  right. `⌃Space` and `⌃⌥Space` switch input sources.
- Authenticate `omp` via `/login`.
- Generate this machine's age key before the first switch, then add its public half to `.sops.yaml`:
  `age-keygen -o ~/.config/sops/age/keys.txt && age-keygen -y ~/.config/sops/age/keys.txt`.
  Without it `sops-nix` cannot decrypt and the launchd agent fails.
- On the MacBook Air, enable SMB File Sharing for `joaichberger`. On this Mac, connect once to
  `smb://joaichberger@MacBook-Air-von-ISYS.local/Macintosh%20HD` and save the password in
  Keychain. Home Manager then reconnects the share and exposes the Air's home directory at `~/Air`;
  the credential never enters Nix.

## DNS

`glockyco.com` sends through Fastmail while its DNS lives at Cloudflare.
`dns/dnsconfig.js` is the source of truth for the zone; the zone-scoped token
is encrypted in `secrets/cloudflare.yaml`. From the repository root, enter the
pinned development shell and opt into the token before reviewing the diff:

```sh
nix develop
use_cloudflare_dns
dnscontrol preview --creds=dns/creds.json --config=dns/dnsconfig.js
dnscontrol push --creds=dns/creds.json --config=dns/dnsconfig.js
```

Always `preview` before `push`. This deliberately sits outside activation: a
`darwin-rebuild switch` must never mutate external shared state, and mail on
this domain is the recovery channel for every other account.

The record set is documented in `dns/dnsconfig.js` rather than repeated here,
because a second copy is a second thing to get wrong. Three constraints the
zone file cannot enforce on its own:

- The DKIM `CNAME`s must stay grey-clouded. Proxying one replaces the answer
  with Cloudflare's, so the key never reaches the verifier.
- Keep exactly one SPF record. Two is a permanent error, not a merge.
- The `100::` `AAAA` records belong to Workers and Cloudflare marks them
  read-only, which is why `dnsconfig.js` lists them as `IGNORE` rather than
  managing them.

## Gotchas

- Determinate owns `/etc/nix/nix.conf`: use `determinateNix.customSettings`; `nix.settings` is inert and `nix.gc` throws. `determinate-nixd` handles GC. `nix.registry` is inert too -- pin flake references through `determinateNix.registry`.
- `karabiner.json` and the Neo bundle are **copied**, not symlinked: Karabiner rewrites its config and macOS rejects keylayouts through store symlinks. UI changes revert on switch; edit the module.
- `homebrew.onActivation.cleanup = "uninstall"`: dropping a cask uninstalls it.
- SSH keys stay out: Secure Enclave via Secretive, YubiKey for recovery; neither is exportable.
- Secrets are committed **encrypted** under `secrets/`. The age private key is per machine, lives at `~/.config/sops/age/keys.txt` and is never committed; a second machine gets its own key and is added to `.sops.yaml` as another recipient. Decrypted values appear at `~/.config/sops-nix/secrets/` and never touch the repository.
- `secrets/` is for credentials a **program** reads: every entry there has a consumer, and the test for a new one is naming it. Account passwords and TOTP seeds go in Bitwarden instead. Break-glass material — two-factor recovery codes, the Bitwarden master password, a backup of the age key — goes offline and off this machine: it has no consumer, and `.sops.yaml` lists a single recipient, so anything encrypted to it dies with the host, which is the exact failure it exists for. Where it lives is deliberately not written down here.
- Terminal.app's font is an archived `NSFont`, not a string; `modules/home/apple-terminal.nix` applies it. Terminal rewrites preferences on quit, so quit and reopen after a switch if it was open.
- macOS caches installed layouts in `$(getconf DARWIN_USER_CACHE_DIR)/com.apple.IntlDataCache.le{,.kbdx}`; bundle changes do not invalidate the cache. Delete both files and restart if a layout change does not take effect.
