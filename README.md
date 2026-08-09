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
- Authenticate `omp` via `/login`.
- Generate this machine's age key before the first switch, then add its public half to `.sops.yaml`:
  `age-keygen -o ~/.config/sops/age/keys.txt && age-keygen -y ~/.config/sops/age/keys.txt`.
  Without it `sops-nix` cannot decrypt and the launchd agent fails.

### Mail domain

`glockyco.com` sends through Fastmail but its DNS lives at Cloudflare, so these
records are applied through the Cloudflare API rather than nix-darwin. The
zone-scoped token is encrypted in `secrets/cloudflare.yaml`.

| Type  | Name             | Value                                                | Proxy    |
| ----- | ---------------- | ---------------------------------------------------- | -------- |
| CNAME | `fm1._domainkey` | `fm1.glockyco.com.dkim.fmhosted.com`                 | DNS only |
| CNAME | `fm2._domainkey` | `fm2.glockyco.com.dkim.fmhosted.com`                 | DNS only |
| CNAME | `fm3._domainkey` | `fm3.glockyco.com.dkim.fmhosted.com`                 | DNS only |
| TXT   | `_dmarc`         | `v=DMARC1; p=none; rua=mailto:glockyco@fastmail.com` | --       |
| TXT   | `@`              | `v=spf1 include:spf.messagingengine.com ~all`        | --       |

Proxying a DKIM record replaces the answer with Cloudflare's, so the key never
reaches the verifier: those three must stay grey-clouded. Keep one SPF record
only. Start DMARC at `p=none` and read the reports before tightening, in case
something legitimate sends as the domain. Leave `A`, `AAAA`, `NS` and `MX`
alone -- the apex serves the `personal-website` Worker and
`dashboard.glockyco.com` is a Worker custom domain.

## Gotchas

- Determinate owns `/etc/nix/nix.conf`: use `determinateNix.customSettings`; `nix.settings` is inert and `nix.gc` throws. `determinate-nixd` handles GC. `nix.registry` is inert too -- pin flake references through `determinateNix.registry`.
- `karabiner.json` and the Neo bundle are **copied**, not symlinked: Karabiner rewrites its config and macOS rejects keylayouts through store symlinks. UI changes revert on switch; edit the module.
- `homebrew.onActivation.cleanup = "uninstall"`: dropping a cask uninstalls it.
- SSH keys stay out: Secure Enclave via Secretive, YubiKey for recovery; neither is exportable.
- Secrets are committed **encrypted** under `secrets/`. The age private key is per machine, lives at `~/.config/sops/age/keys.txt` and is never committed; a second machine gets its own key and is added to `.sops.yaml` as another recipient. Decrypted values appear at `~/.config/sops-nix/secrets/` and never touch the repository.
- Terminal.app's font is an archived `NSFont`, not a string; `modules/home/apple-terminal.nix` applies it. Terminal rewrites preferences on quit, so quit and reopen after a switch if it was open.
- macOS caches installed layouts in `$(getconf DARWIN_USER_CACHE_DIR)/com.apple.IntlDataCache.le{,.kbdx}`; bundle changes do not invalidate the cache. Delete both files and restart if a layout change does not take effect.
