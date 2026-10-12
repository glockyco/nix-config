# nix-config

Configuration for an Apple Silicon MacBook Pro and Korolev, a Windows 11 work laptop. Nix configures the Mac, chezmoi manages user files on both, and a PowerShell 7 engine installs applications and settings on Windows. The flake also declares the tailnet policy and the [DNS zone](dns/dnsconfig.js).

## Hosts

| Host                | Platform                | Configured by                                             | Guide                                                                    |
| ------------------- | ----------------------- | --------------------------------------------------------- | ------------------------------------------------------------------------ |
| `macbook-pro`       | macOS, `aarch64-darwin` | [nix-darwin](hosts/macbook-pro/default.nix) and chezmoi   | This README                                                              |
| `korolev`           | Windows 11              | [PowerShell engine](windows/workstation.json) and chezmoi | [Korolev Windows](docs/operations/korolev-windows.md)                    |
| `korolev` NixOS-WSL | `x86_64-linux`          | [NixOS](hosts/korolev/default.nix)                        | Being retired. See the [WSL guide](docs/operations/wsl-omp-bootstrap.md) |

Host facts live in `hosts/<name>/host.nix`, typed by [modules/fleet/host.nix](modules/fleet/host.nix). Each `hosts/<name>/default.nix` selects roles from `modules/roles/`. Change a machine value in its host declaration and role policy in its role module.

## Who owns what

| State                                                    | Owner                                                   |
| -------------------------------------------------------- | ------------------------------------------------------- |
| macOS system, packages, language servers and services    | Nix (nix-darwin)                                        |
| User files and app settings on every host                | chezmoi, from [home/](home/)                            |
| Windows applications and user settings                   | The PowerShell engine, which chezmoi runs               |
| OMP and its plugins                                      | Their own installer and plugin manager, see [OMP](#omp) |
| Credentials, sessions, browser profiles and project data | The applications themselves                             |

[Shared TOML facts](home/.chezmoidata/) feed both the Nix host declarations and the chezmoi templates. Chezmoi writes regular files. The Zed and Karabiner filters keep settings they do not declare.

## Develop

### macOS

`nix develop` enters the pinned environment and installs the commit hook. The hook formats staged files and validates OpenSpec when files below `openspec/` are staged. `direnv allow` uses the same shell. Run the checks from the repository root, one Nix command at a time, because concurrent evaluations contend for the evaluation cache:

```sh
nix fmt -- --fail-on-change
openspec validate --all --strict
openspec validate --archived --strict
nix flake check --print-build-logs
nix run .#check-darwin-build-plans
nix build .#darwinConfigurations.macbook-pro.system
```

`check-darwin-build-plans` rejects toolchains and language servers that would build from source instead of coming from the cache. It needs store access outside the check sandbox, so it runs as an app.

### Windows

Use the checkout below `C:\Users\jglock\src`. Install the pinned formatters, hook and test modules once, then run the checks:

```powershell
pwsh -NoProfile -File .\windows\dev\bootstrap.ps1 -IncludeTestDependencies
pwsh -NoProfile -File .\windows\dev\engine-dependencies.ps1
pwsh -NoProfile -File .\windows\dev\format.ps1 -Check
pwsh -NoProfile -File .\windows\dev\ci.ps1
```

The tools live below the checkout's Git directory and are pinned in `windows/dev/dependencies.lock.json`. `ci.ps1` validates the declaration and runs the mocked engine tests and chezmoi fixtures. It never changes the real machine. The pre-commit hook runs the static checks, and both OpenSpec validations with the workstation's pinned CLI when files below `openspec/` are staged. Windows has no Nix, so the hook only names staged `.nix` files, and CI's Nix formatting check is their gate.

Before merging a change to `windows/` or to Windows files in `home/`, run the engine's dry run and `chezmoi apply` on Korolev from the PR branch. See [Korolev Windows](docs/operations/korolev-windows.md).

### CI

[CI](.github/workflows/check.yml) runs only the jobs a change affects: the Nix checks on Linux and macOS, `check (windows-latest)` and OpenSpec validation. Changes to `.github/` run every job.

## Activate

### macOS

Keep the clone at `~/.config/nix-darwin`. The first activation and chezmoi initialization:

```sh
sudo nix run .#darwin-rebuild -- switch --flake .#macbook-pro
chezmoi init --source "$HOME/.config/nix-darwin" --promptString host=macbook-pro
chezmoi apply
```

Later activations use `darwin-switch`. It prints the closure diff, switches the system and then runs `chezmoi apply`. A failed switch skips the apply. Run it without `sudo`, because it calls `sudo` itself. Agents run it in a terminal and the owner types the password. From Korolev:

```sh
ssh -t macbook-pro 'cd ~/.config/nix-darwin && darwin-switch'
```

Check user files with `chezmoi verify`. Never run chezmoi with `sudo`.

### Windows

See [Korolev Windows](docs/operations/korolev-windows.md).

## Network

Tailscale connects the Mac, Korolev, the personal Windows desktop and the borrowed MacBook Air. The policy is generated from [lib/tailnet-policy.nix](lib/tailnet-policy.nix). Pull requests test it, and the `tailnet-policy` workflow applies it after `check` passes on `main`. [Tailnet policy authorization](docs/operations/tailnet-policy.md) covers repairing the workflow's access to Tailscale.

SSH endpoints come from [home/private_dot_ssh/config.tmpl](home/private_dot_ssh/config.tmpl). They pin host keys and never fall back to passwords.

| Command                      | Result                                                                                                   |
| ---------------------------- | -------------------------------------------------------------------------------------------------------- |
| `ssh desktop`                | PowerShell on the personal desktop                                                                       |
| `ssh korolev`                | PowerShell on Korolev, from the Mac, while Korolev is on the office network or VPN                       |
| `ssh macbook-pro`            | A shell on the Mac, from Korolev                                                                         |
| `ssh <host>-batch 'exit 23'` | The same host for unattended commands, with stdin preserved, no terminal and an 8-second connect timeout |
| `sftp desktop-batch`         | File transfer. Windows paths take the form `/D:/Projects/ynab`                                           |

Windows App on the Mac connects to the desktop at `desktop.tail8768af.ts.net`. The desktop has one session, so connecting takes it over. [Personal desktop](docs/operations/desktop.md) covers its keys and OpenSSH updates. [Korolev remote access](docs/operations/korolev-remote-access.md) covers Korolev's SSH server.

The Air is borrowed and temporary. [Issue #17](https://github.com/glockyco/nix-config/issues/17) tracks its removal.

## OMP

On macOS, the official installer puts OMP in `~/.local/bin`. Install OMP and the [personal plugin](https://github.com/glockyco/omp-agent-setup):

```sh
curl -fsSL https://omp.sh/install | sh -s -- --binary
omp plugin marketplace add glockyco/omp-agent-setup
omp plugin install --scope user personal@glockyco
```

Update OMP and the plugin independently, then start a new session:

```sh
omp update
omp plugin marketplace update glockyco
omp plugin upgrade --scope user personal@glockyco
```

To return to an earlier OMP release, reinstall with `--binary --ref <tag>`. A bad plugin release is replaced by a newer one, never by editing the installed cache. On Windows, Tern installs and updates OMP, see [Korolev Windows](docs/operations/korolev-windows.md#tern-omp-and-plannotator).

## Containers

The Mac runs containers in Colima and Korolev in Docker Desktop. See [container runtime](docs/operations/container-runtime.md).

## Secrets

Chezmoi's built-in age decrypts the Mac-only [encrypted sources](home/dot_config/private_credentials/) with `~/.config/sops/age/keys.txt`. [credentials.toml](home/.chezmoidata/credentials.toml) lists the recipient and the credentials, which land in `~/.config/credentials/` with mode 0600. The plaintext persists across reboots, so keep the disk and local backups encrypted. Never commit, print or export the identity or the decrypted values. Linux and Windows skip these sources. There is no offline recovery recipient yet.

To preview a change without decrypting credentials, run `chezmoi --override-data '{"checkMode":true}' diff`. Never use that override for a real apply.

## DNS

[`dns/dnsconfig.js`](dns/dnsconfig.js) declares the `glockyco.com` zone. `nix flake check` validates it without a token, and any DNSControl warning fails the check. Checks and activation never publish the zone.

Publish only from the Mac, after reviewing the preview. Each command reads the token inside the development shell, so only DNSControl receives it:

```sh
cd dns
nix develop .. --command bash -c 'CLOUDFLARE_API_TOKEN="$(< ~/.config/credentials/cloudflare-dns-token)" exec dnscontrol preview'
nix develop .. --command bash -c 'CLOUDFLARE_API_TOKEN="$(< ~/.config/credentials/cloudflare-dns-token)" exec dnscontrol push'
```

Only the owner runs `push`, and only when the preview shows the intended changes and nothing else. A project that needs the token calls the `use_cloudflare_dns` direnv function from its `.envrc`.

## Update

[Dependency automation](https://github.com/glockyco/dependency-automation) opens Nix input PRs every Saturday and Renovate updates GitHub Actions. Neither merges nor activates anything. [Dependency operations](docs/operations/dependency-updates.md) covers OpenSpec, Plannotator and other manual updates. For a manual Nix update, run `nix flake update`, or `nix flake update <input>` for one input, then review the diff and run the checks.

## Recover

Keep the previous generation until the checks and a smoke test pass. On the Mac:

```sh
sudo darwin-rebuild --list-generations | cat
sudo darwin-rebuild --rollback
```

A system rollback does not restore user files. To roll them back, check out the earlier revision, review `chezmoi diff` and run `chezmoi apply`. OMP and its plugins recover through their own commands, see [OMP](#omp). For Windows, see [When something goes wrong](docs/operations/korolev-windows.md#when-something-goes-wrong).
