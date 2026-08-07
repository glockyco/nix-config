# nix-config

Declarative macOS workstation. Determinate Nix + nix-darwin + Home Manager, Apple Silicon.

`modules/darwin/` is system scope, `modules/home/` is user scope, `packages/` is
local derivations. File names say what they do.

No language toolchains here on purpose — those live in per-project flakes with
`direnv`. Symbolic PathFinder wants JDK 8 and current JPF wants JDK 11, so a
global JDK would be wrong for both.

## Use

```sh
sudo darwin-rebuild switch --flake .    # apply
nix flake check                         # build without applying
nix flake update                        # bump inputs
nix fmt                                 # format
```

Bootstrapping a fresh machine, before `darwin-rebuild` exists and while the host
still has its factory name:

```sh
sudo nix run .#darwin-rebuild -- switch --flake .#macbook-pro
```

Delete `/etc/nix/nix.custom.conf` first if the Determinate installer left one —
nix-darwin won't overwrite files in `/etc` it didn't write.

## Manual steps

macOS won't let these be declared:

- Reboot, then add *Deutsch (Neo 2)* under Input Sources.
- Approve Karabiner's driver extension, Input Monitoring and login items.
- `softwareupdate --install-rosetta --agree-to-license` for CrossOver.
- Confirm the default-app prompts on first switch.
- `omp` auth via `/login`.

## Gotchas

- Determinate owns `/etc/nix/nix.conf`. Use `determinateNix.customSettings`;
  `nix.settings` is inert and `nix.gc` throws. GC is `determinate-nixd`'s job.
- `karabiner.json` and the Neo bundle are **copied**, not symlinked — Karabiner
  rewrites its config, and macOS won't load a keylayout through a store symlink.
  UI changes to Karabiner are reverted on switch; edit the module.
- `homebrew.onActivation.cleanup = "uninstall"` — dropping a cask uninstalls it.
- SSH keys aren't here and can't be: Secure Enclave via Secretive, YubiKey for
  recovery. Neither is exportable.
