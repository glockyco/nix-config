# Repository Guidance

This repository owns the Apple Silicon workstation configuration. It also owns the immutable OMP wrapper, the personal plugin pin, Home Manager activation, and Nix-generation rollback.

## Sources of truth

- Architecture and runtime boundaries: [`docs/architecture/personal-omp-environment.md`](docs/architecture/personal-omp-environment.md)
- Dependency updates and release procedure: [`docs/operations/dependency-updates.md`](docs/operations/dependency-updates.md)
- Accepted behavior: [`openspec/specs/`](openspec/specs/)
- Active implementation work: [`openspec/changes/`](openspec/changes/)

Use OpenSpec for permanent behavior changes. Read all artifacts for the active change before you edit implementation files. Validate the change with `openspec validate <change> --strict` and archive it only after all acceptance gates pass.

## Boundaries

Nix owns executable and plugin store paths. OMP owns writable authentication, configuration, sessions, history, caches, logs, and databases. Do not make activation write or restore that mutable state. Do not install Nix inside CrossOver bottles.

Project repositories own their development environments, build commands, and game-specific deployment commands. This repository can install CrossOver and create an empty bottle, but it does not authenticate Steam, update games, install mod loaders, deploy mods, or launch games during activation.

## Release gates

Run the native commands from the repository root:

```sh
nix fmt -- --fail-on-change
nix flake check --print-build-logs
nix run .#check-darwin-build-plans
nix build .#darwinConfigurations.macbook-pro.system
```

`check-darwin-build-plans` is separate from `nix flake check` because it reads
build plans, and a check derivation has no store access. It fails when an output
reaches a source-built .NET package or a Swift compiler, which Nixpkgs does not
cache for `aarch64-darwin`: one such dependency once cost this repository a five
hour CI run.

Use `darwin-switch` only after review and merge. Read its activation output. For an OMP or plugin behavior change, also run the real wrapped-session smoke in the architecture document. Keep the previous generation until all applicable gates pass.

Do not add an update wrapper. Renovate owns GitHub Actions. The official flake updater owns Nix inputs. Both create review-only pull requests.
