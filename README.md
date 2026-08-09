# nix-config

Declarative macOS config: Determinate Nix, nix-darwin, Home Manager, Apple Silicon.

`hosts/` is one directory per machine, owning that machine's name and user.
`modules/darwin/` is system scope, `modules/home/` user scope, and `packages/` local derivations.

No global toolchains: project flakes use `direnv`. Symbolic PathFinder needs JDK 8; current JPF needs JDK 11.

## Use

```sh
darwin-switch                           # apply, then diff the closure
sudo darwin-rebuild switch --flake .    # apply, without the diff
nix flake check                         # build, and verify formatting, without applying
                                        # checks only this system; CI covers the others
nix flake update                        # bump inputs
nix fmt                                 # format the tree; see ./treefmt.nix
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

## Manual steps

macOS cannot declare these:

- Add *Deutsch (Neo 2)* under Input Sources, then restart; Apple TN2056 and neo-layout.org require a fresh login session after layout installation.
- Approve Karabiner's driver extension, Input Monitoring and login items.
- Confirm the default-app prompts on first switch.
- Paste the Rectangle Pro licence code into the app and grant it Accessibility.
- Set the Alfred and LaunchBar activation hotkeys, and grant both Accessibility. Neither app can
  sync a hotkey, so this is per machine. **Bind them with Control and no other modifier family.**
  Neo 2 does not merely consume keys, it synthesises them: the generated `karabiner.json` emits
  `left_option` as a modifier 143 times and `left_shift` 162 times to produce layer 3 and 4
  symbols, and takes `right_option` as a mandatory modifier 62 times. Control appears on neither
  side, so it is the only family that cannot collide. Avoid `⌃Space` and `⌃⌥Space` as well: those
  switch input sources, and Neo 2 is registered as one. The stock defaults, Alfred's `⌥Space` and
  LaunchBar's `⌘Space`, are both unusable here.
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
