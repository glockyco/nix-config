# nix-darwin workstation

Declarative configuration for an Apple Silicon Mac running Determinate Nix.

## Layout

```
flake.nix                     inputs, the darwinConfiguration, overlay, checks, devShell

modules/darwin/               system scope
  system.nix                  platform, state version, hostname, user, firewall, Touch ID sudo
  nix.nix                     Determinate Nix module and /etc/nix/nix.custom.conf
  defaults.nix                macOS preferences (system.defaults)
  fonts.nix                   Nerd Fonts
  homebrew.nix                nix-homebrew plus the cask list
  home-manager.nix            Home Manager wired in as a nix-darwin module

modules/home/                 user scope
  shell.nix                   zsh, history, starship, direnv/nix-direnv
  cli.nix                     fzf, zoxide, ripgrep, fd, bat, eza
  git.nix                     git identity and delta
  gh.nix                      GitHub CLI
  ssh.nix                     Secure Enclave agent, FIDO2-capable OpenSSH
  packages.nix                omp, herdr
  typst.nix                   Typst and the tinymist language server
  ghostty.nix                 terminal appearance
  zed.nix                     editor settings, omp wired in over ACP
  neo2.nix                    Neo keyboard layout bundle installation
  karabiner.nix               generated karabiner.json with the Neo2 rules
  default-apps.nix            LaunchServices bindings for text and source files
  screenshots.nix             screenshot directory
  crossover.nix               Steam CrossOver bottle

packages/
  neo-keyboard-layouts.nix    the Neo macOS layout bundle, from the official Neo git
```

Language toolchains are deliberately absent. They belong in per-project
flakes with `direnv`, not here -- Symbolic PathFinder needs JDK 8 while
current Java PathFinder needs JDK 11, and a single global JDK would be wrong
for both.

## Bootstrapping a fresh machine

With Determinate Nix installed but nix-darwin not yet activated,
`darwin-rebuild` is not on `PATH` and the host still has its factory name, so
the configuration has to be named explicitly exactly once:

```sh
sudo nix run .#darwin-rebuild -- switch --flake .#macbook-pro
```

That switch renames the host to `macbook-pro`, after which the short form
below works. If `/etc/nix/nix.custom.conf` already exists from the Determinate
installer, delete it first -- nix-darwin refuses to overwrite files in `/etc`
it did not write.

## Everyday use

```sh
sudo darwin-rebuild switch --flake .    # apply
nix flake check                         # evaluate and build without applying
nix flake update                        # bump every input
nix fmt                                 # format
```

`nixpkgs`, `nix-darwin` and `home-manager` are pinned to the 26.05 release train.
Moving to the next release means editing the three URLs in `flake.nix` and
`home.stateVersion` in `modules/home/default.nix` together.

## Manual steps after the first activation

These cannot be granted or performed declaratively.

1. **Reboot.** Required by Apple TN2056 and by the Neo documentation before a
   newly installed keyboard layout behaves correctly.
2. **Add the layout**: System Settings, Keyboard, Input Sources, `+`, under
   German pick *Deutsch (Neo 2)*. Adding it declaratively would mean overwriting
   `AppleEnabledInputSources`, which would drop the other input sources.
3. **Approve Karabiner-Elements**: System Settings, Privacy & Security, allow
   the `org.pqrs` driver extension, then grant Input Monitoring and add the
   login items. macOS requires a human for all three.
4. **Install Rosetta 2** if you use CrossOver: `softwareupdate --install-rosetta
   --agree-to-license`. CrossOver 26's wineloader is still x86_64, so bottle
   creation fails with "Bad CPU type in executable" without it. A licence has to
   be accepted, so this is not automated.
5. **Confirm default-app changes.** macOS 26 prompts once per file type when
   `modules/home/default-apps.nix` rebinds handlers to Zed.
6. **Authenticate omp** once with `/login` inside a session. Credentials live in
   `~/.omp/agent/` and are deliberately not managed here.

## Things worth knowing

- **Determinate Nix owns `/etc/nix/nix.conf`.** `nix.settings` and
  `nix.extraOptions` do nothing; use `determinateNix.customSettings`.
- **`karabiner.json` is generated.** Karabiner rewrites the file in place, so it
  is copied out of the store rather than symlinked, and changes made in the
  Karabiner UI are reverted on the next switch. Edit `enabledRules` in
  `modules/home/karabiner.nix` instead.
- **The Neo bundle is copied, not linked.** macOS does not load keyboard layouts
  through a symlink into the Nix store.
- **Homebrew taps are mutable**, so Homebrew resolves casks through its JSON API
  and `nix flake update` does not move cask versions. `homebrew.onActivation.cleanup`
  is `"uninstall"`: a cask removed from `modules/darwin/homebrew.nix` is removed
  from the machine on the next switch.
- **SSH keys are not in here and cannot be.** The day-to-day key lives in this
  Mac's Secure Enclave via Secretive and is non-exportable by construction; a
  FIDO2 resident key on a YubiKey is the recovery path. Neither can be backed
  up into a repository, which is the point.
- **`nix.gc` is unusable here.** It throws under Determinate because
  `nix.package` is inaccessible when `nix.enable` is off. Garbage collection is
  already handled by `determinate-nixd`, which collects on disk pressure.
