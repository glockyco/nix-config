# nix-config

Nix flake for two personal workstations: an Apple Silicon MacBook Pro under nix-darwin, and a NixOS host under WSL 2 on an `x86_64` Windows work machine. Each host is a system configuration that imports Home Manager as a module. Both hosts select the same portable user modules and supply their own identity values.

The flake also renders a reviewable Windows declaration for the work machine, and it manages the DNS records for `glockyco.com`.

## Hosts

| Output                             | System           | Activation                                    |
| ---------------------------------- | ---------------- | --------------------------------------------- |
| `darwinConfigurations.macbook-pro` | `aarch64-darwin` | `darwin-switch`                               |
| `nixosConfigurations.korolev`      | `x86_64-linux`   | `sudo nixos-rebuild switch --flake .#korolev` |

One table in `flake.nix` binds each system to its host. The supported systems, the per-system package set, and the checks derive from that table.

## Ownership

| Owner              | State                                                                                                                                                 |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| This flake         | Host closures, the `omp` wrapper, the personal plugin pin, Herdr, OpenSpec, language servers, `verify-personal-omp`, the rendered Windows declaration |
| Platform installer | The OMP executable: Homebrew at `/opt/homebrew/bin/omp` on Darwin, the official installer at `~/.local/lib/oh-my-pi/omp` on WSL                       |
| OMP                | Authentication, `~/.omp/agent/config.yml`, sessions, history, caches, logs, databases                                                                 |
| Windows            | Windows Terminal, WSL enablement, employer policy, native applications, the editor                                                                    |
| Project repository | Its development shell, build commands, and deployment commands                                                                                        |

Activation does not install, update, or restore the OMP executable. It does not read or write OMP-owned state. Nix does not execute Windows resources. See [the architecture document](docs/architecture/personal-omp-environment.md) for the complete boundary and the decision log.

## Layout

| Path                 | Content                                                                                         |
| -------------------- | ----------------------------------------------------------------------------------------------- |
| `flake.nix`          | Inputs, the host table, host outputs, packages, checks, and the development shell               |
| `hosts/`             | One directory per host with its identity values                                                 |
| `modules/darwin/`    | nix-darwin system scope                                                                         |
| `modules/nixos/`     | NixOS system scope for WSL                                                                      |
| `modules/home/`      | Portable Home Manager modules. `modules/home/darwin/` holds the Darwin-only user modules        |
| `modules/shared/`    | Data shared by the Nix hosts and the Windows declaration, such as Zed settings and Zen policies |
| `modules/windows/`   | The WinGet Configuration document and the two Administrator scripts                             |
| `packages/`          | The OMP wrapper, the verifiers, and the check programs                                          |
| `docs/architecture/` | Cross-repository architecture, ownership, and decisions                                         |
| `docs/operations/`   | Runbooks for korolev provisioning, the container runtime, and dependency updates                |
| `docs/plans/`        | Tracked planning records. `docs/plans/INDEX.md` states their status                             |
| `openspec/`          | Accepted specifications and active changes                                                      |
| `dns/`               | DNSControl configuration for `glockyco.com`                                                     |
| `secrets/`           | SOPS-encrypted values for the Darwin host                                                       |

## Develop

Enter the development shell:

```sh
nix develop
```

`.envrc` enters the same shell through direnv. The shell installs the lefthook pre-commit hook. The hook runs `treefmt --fail-on-change` on staged files through the pinned shell.

Run the release gates from the repository root:

```sh
nix fmt -- --fail-on-change
nix flake check --print-build-logs
nix run .#check-darwin-build-plans
nix build .#darwinConfigurations.macbook-pro.system
```

`nix flake check` checks the current system only. CI runs one macOS leg and one Linux leg, and each leg uses the Nix implementation that its host runs. `check-darwin-build-plans` reads build plans, which a check derivation cannot do. It fails when a Darwin output reaches a source-built .NET package or a Swift compiler.

Permanent behavior changes use OpenSpec. Read the artifacts of the active change before you edit implementation files.

## Activate

### macbook-pro

`darwin-switch` expects the clone at `~/.config/nix-darwin`. For the first activation, `darwin-rebuild` is not on `PATH` yet:

```sh
sudo nix run .#darwin-rebuild -- switch --flake .#macbook-pro
```

For every later activation:

```sh
darwin-switch
verify-personal-omp
```

`darwin-switch` prints an `nvd` diff of the closure. `verify-personal-omp` prints the observed OMP version, the plugin path under `/nix/store`, and `omp: current` from Herdr.

### korolev

Follow [the provisioning runbook](docs/operations/wsl-omp-bootstrap.md) for the image build, the import, and the cutover. Activate from a committed tree:

```sh
sudo nixos-rebuild switch --flake .#korolev
verify-personal-omp
```

Run one WSL distribution at a time. A second distribution with the same user ID cannot start its user manager, and the activation fails.

### Windows layer

Build the declaration in NixOS and copy the result to a writable Windows directory:

```sh
nix build .#windows-configuration
```

Apply the result with `winget configure` as the interactive user. Step 12 of the provisioning runbook states the preview, apply, and post-apply test commands. WinGet has no generation rollback.

## Update

### OMP

An OMP update does not change this repository and does not need Nix activation. The wrapper uses the updated executable with the same immutable plugin.

On Darwin:

```sh
brew upgrade can1357/tap/omp
verify-personal-omp
```

On WSL:

```sh
curl -fsSL https://omp.sh/install \
  | PI_INSTALL_DIR="$HOME/.local/lib/oh-my-pi" sh -s -- --binary
verify-personal-omp
```

### Nix inputs

The `glockyco/dependency-automation` control plane opens a review-only pull request for `flake.lock` every Saturday. Renovate owns GitHub Actions. Neither system merges. [The dependency-update runbook](docs/operations/dependency-updates.md) states the manual commands, the required checks, and the credential rotation.

## Roll back

Keep the previous generation until every gate and the real wrapped-session smoke pass.

On Darwin:

```sh
sudo darwin-rebuild --list-generations | cat
sudo darwin-rebuild --rollback
```

On korolev:

```sh
sudo nixos-rebuild list-generations | cat
sudo nixos-rebuild switch --rollback --no-reexec
```

A rollback restores the wrapper, plugin, Herdr, OpenSpec, and language-server paths. It does not change the OMP executable or OMP-owned state. Recover an OMP release through its platform installer.

## Documentation

- [Personal OMP environment architecture](docs/architecture/personal-omp-environment.md)
- [Provision the korolev NixOS WSL host](docs/operations/wsl-omp-bootstrap.md)
- [Container runtime](docs/operations/container-runtime.md)
- [Dependency updates](docs/operations/dependency-updates.md)
- [Planning index](docs/plans/INDEX.md)
- [Accepted specifications](openspec/specs/)
- [Repository guidance for agents](AGENTS.md)
