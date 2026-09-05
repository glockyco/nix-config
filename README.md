# nix-config

Personal workstation configuration for an Apple Silicon MacBook Pro and NixOS under WSL 2. The flake also renders a separately applied Windows configuration and manages [DNS](dns/dnsconfig.js).

## System overview

| Host          | Platform         | Configuration                               |
| ------------- | ---------------- | ------------------------------------------- |
| `macbook-pro` | `aarch64-darwin` | [nix-darwin](hosts/macbook-pro/default.nix) |
| `korolev`     | `x86_64-linux`   | [NixOS/WSL](hosts/korolev/default.nix)      |

Nix owns the host configuration and OMP wrapper, plugin, and language tools. Homebrew on macOS and the official installer on WSL own the OMP executable. OMP owns its writable authentication, configuration, sessions, and databases; activation and Nix rollback do not replace them. Project repositories own their development environments.

[![System overview: pinned inputs and shared and platform-specific modules compose the macOS and NixOS/WSL environments. Windows configuration is applied separately. The OMP detail shows the Nix-managed wrapper, plugin, and language servers interacting with the externally managed executable and writable state.](docs/images/system-overview.webp)](docs/images/system-overview.webp)

## Network

Tailscale connects the managed hosts, personal Windows desktop, and temporary MacBook Air. Korolev can initiate connections but does not accept inbound connections.

[![Tailscale overview: Korolev can initiate connections to the MacBook Pro, Windows desktop, and temporary MacBook Air. Those three peers can initiate connections to one another. Service cards distinguish verified SSH access from pending file-access checks and unverified desktop authentication.](docs/images/tailscale-overview.webp)](docs/images/tailscale-overview.webp)

## Develop

With Nix and flakes installed, enter the pinned environment. It installs the commit hook; `direnv allow` uses the same shell.

```sh
nix develop
```

Run release gates from the repository root, using each host's installed Nix:

```sh
nix fmt -- --fail-on-change
nix flake check --print-build-logs
```

Run these additional gates on the Mac:

```sh
nix run .#check-darwin-build-plans
nix build .#darwinConfigurations.macbook-pro.system
```

The build-plan guard needs Darwin store access outside a check sandbox. It rejects uncached source-built toolchains and language servers. [CI](.github/workflows/check.yml) checks both platforms; a local flake check checks only its own system. With the Mac connected to the tailnet, Korolev can build both systems:

```sh
nix flake check --all-systems --print-build-logs
```

Permanent behavior changes use [OpenSpec](openspec/). [Agent guidance](AGENTS.md) explains the repository workflow.

## Activate

Review and merge first. Keep the previous generation and read activation output. For Mac networking changes, retain a local administrator terminal for recovery.

On the Mac, keep this clone at `~/.config/nix-darwin`. First activation:

```sh
sudo nix run .#darwin-rebuild -- switch --flake .#macbook-pro
```

Later activations use `darwin-switch`, which also prints the closure diff. On Korolev, activate from the committed repository:

```sh
sudo nixos-rebuild switch --flake .#korolev
```

Run `verify-personal-omp` afterward. It reports the OMP version, plugin store path, and current Herdr integration. After OMP or plugin behavior changes, also complete the [release smoke](docs/operations/dependency-updates.md#release-smoke).

For a new Windows machine, follow [WSL and Windows provisioning](docs/operations/wsl-omp-bootstrap.md). It covers image import, credentials, the separate Windows apply, and recovery. Run one WSL distribution at a time; confirm `systemctl is-active user@1000.service` reports `active` before activation.

For local containers on the Mac, use the [container lifecycle and recovery procedure](docs/operations/container-runtime.md). Activation does not start or delete the VM.

## Update

The central [dependency automation](https://github.com/glockyco/dependency-automation) opens review-only Nix-input PRs every Saturday. Renovate updates GitHub Actions. Neither merges or activates hosts. [Dependency operations](docs/operations/dependency-updates.md) covers external authorization and release recovery.

For a manual Nix update, choose one command, review the diff, then run the gates above:

```sh
nix flake update                       # all inputs
nix flake update personal-omp-plugin   # plugin only
```

OMP updates need no repository change or Nix activation. On macOS:

```sh
brew upgrade can1357/tap/omp
```

On WSL, use the same official binary installation command for first install and updates:

```sh
curl -fsSL https://omp.sh/install \
  | PI_INSTALL_DIR="$HOME/.local/lib/oh-my-pi" sh -s -- --binary
```

Run the verifier and applicable release smoke before accepting the update.

## Recover

Keep the previous generation until all applicable gates and smoke checks pass. List and restore Nix generations on the affected host:

```sh
# macOS
sudo darwin-rebuild --list-generations | cat
sudo darwin-rebuild --rollback

# Korolev
sudo nixos-rebuild list-generations | cat
sudo nixos-rebuild switch --rollback --no-reexec
```

Then repeat verification. Nix rollback restores immutable tools, not OMP versions, credentials, tailnet enrollment, or application data. For a rejected OMP release, use [platform version recovery](docs/operations/dependency-updates.md#omp-version-recovery). Windows configuration has no generation rollback.
