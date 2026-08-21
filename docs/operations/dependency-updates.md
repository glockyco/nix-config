# Dependency Updates

## Ownership

| Repository             | Dependency class                               | Owner                   | Schedule                  |
| ---------------------- | ---------------------------------------------- | ----------------------- | ------------------------- |
| `omp-agent-setup`      | `package.json`, `bun.lock`, and GitHub Actions | Renovate                | Saturday, `Europe/Vienna` |
| `omp-agent-setup`      | Nix inputs in `flake.lock`                     | `dependency-automation` | Saturday, 04:00 UTC       |
| `nix-config`           | GitHub Actions                                 | Renovate                | Saturday, `Europe/Vienna` |
| `nix-config`           | Nix inputs in `flake.lock`                     | `dependency-automation` | Saturday, 04:00 UTC       |
| `erenshor-data-mining` | Nix inputs and the matching pnpm assertion     | `dependency-automation` | Saturday, 04:00 UTC       |

Renovate's Nix manager stays disabled in all three repositories. The protected `glockyco/dependency-automation` control plane is the only automated writer for each `flake.lock`. Neither system merges pull requests.

## Automation identity

The private `glockyco-dependency-updater` GitHub App is installed only on `omp-agent-setup`, `nix-config`, and `erenshor-data-mining`. Its repository permissions are:

- Metadata: read
- Contents: read and write
- Pull requests: read and write

Only `glockyco/dependency-automation` stores:

- Actions variable `DEPENDENCY_UPDATER_CLIENT_ID`
- Actions secret `DEPENDENCY_UPDATER_PRIVATE_KEY`

Each matrix job uses these values to create a token scoped to one target repository. The token expires after one hour and is revoked when the job ends. Target repositories store no App credential and run no local Nix scheduler. Do not put the private key in Git, Nix, SOPS, a password manager, shell history, or a local environment file.

To rotate the key:

1. Generate a new private key in the GitHub App settings.
1. Replace `DEPENDENCY_UPDATER_PRIVATE_KEY` in `dependency-automation`.
1. Run one update for each managed repository and confirm token creation.
1. Delete the old key in the GitHub App settings.

## Automatic pull requests

The control plane uses `automation/update-nix-dependencies` in every target repository. `repositories.json` declares each command as an argument array and allowlists every path it may change. A run with no change exits without a pull request. A changed lock must create or refresh one App-authored pull request and start normal target CI.

Trigger every managed update:

```sh
gh workflow run update-nix-dependencies.yml --repo glockyco/dependency-automation
```

Trigger one repository:

```sh
gh workflow run update-nix-dependencies.yml \
  --repo glockyco/dependency-automation \
  -f repository=erenshor-data-mining
```

Inspect the latest runs and open pull requests:

```sh
gh run list --workflow update-nix-dependencies.yml \
  --repo glockyco/dependency-automation --limit 5

gh pr list --repo glockyco/omp-agent-setup --head automation/update-nix-dependencies
gh pr list --repo glockyco/nix-config --head automation/update-nix-dependencies
gh pr list --repo glockyco/erenshor-data-mining --head automation/update-nix-dependencies
```

Before merge, inspect `flake.lock`, the updater log, and the dependency release notes. Also inspect the matching `package.json` change in Erenshor when the Nix-provided pnpm version changes.

| Repository             | Required checks                             |
| ---------------------- | ------------------------------------------- |
| `omp-agent-setup`      | `check (macos-15)`, `check (ubuntu-latest)` |
| `nix-config`           | `check (macos-15)`, `check (ubuntu-latest)` |
| `erenshor-data-mining` | `CI Success`                                |

Main also requires a current pull-request branch and linear history. The policy applies to administrators. Force-push and branch deletion are disabled.

## Manual Erenshor update

From `erenshor-data-mining`:

```sh
nix flake update
nix run .#sync-pnpm-version
nix develop --command uv run erenshor test dependency-state
nix develop --command uv run erenshor test ci
```

Use this path to repair an updater branch or diagnose one input locally. Commit `flake.lock` and `package.json` together when the Nix-provided pnpm version changes.

## Manual plugin update

From `omp-agent-setup`:

```sh
nix flake update
nix develop --command bun install --frozen-lockfile
nix develop --command bun run ci
nix flake check --print-build-logs
```

Use this path when diagnosis needs one local update or when the scheduled workflow is unavailable. Commit `flake.lock` in the same pull request. Do not publish an untested plugin revision.

## Manual workstation update

From `nix-config`, update all inputs:

```sh
nix flake update
git diff -- flake.lock
nix fmt -- --fail-on-change
nix flake check --print-build-logs
nix build .#darwinConfigurations.macbook-pro.system
```

For a plugin-only release after `omp-agent-setup` is published:

```sh
nix flake update personal-omp-plugin
git diff -- flake.lock
nix flake check --print-build-logs
nix build .#darwinConfigurations.macbook-pro.system
```

For an OMP, Herdr, or OpenSpec update, update the shared package source:

```sh
nix flake update llm-agents
git diff -- flake.lock
nix flake check --print-build-logs
nix build .#darwinConfigurations.macbook-pro.system
```

An OpenSpec update can change the generated workflow adapters. They live in the personal plugin, so regenerate them in `glockyco/omp-agent-setup` with `nix run .#sync-openspec-adapters`, then advance `personal-omp-plugin` here.

OpenSpec 1.9 adds strict task-numbering and scenario checks plus `validate --archived`. The flake gate runs both active-contract and archived-task validation.

Inspect selected versions and revisions:

```sh
nix eval --raw .#packages.aarch64-darwin.personal-omp.upstreamOmp.version
nix eval --raw .#packages.aarch64-darwin.openspec.version
nix flake metadata --json | jq -r '.locks.nodes["personal-omp-plugin"].locked.rev'
```

Do not run `omp update`. Do not install the personal plugin through OMP's mutable plugin manager.

## Activation and smoke

Merging changes does not update the workstation. Activate deliberately:

```sh
darwin-switch
```

Read the activation output. `verifyPersonalOmp` must report:

- the expected OMP version;
- a personal plugin path under `/nix/store`;
- `omp: current` from Herdr.

For an `llm-agents`, personal plugin, wrapper, or extension behavior change, start a fresh wrapped OMP session. Ask it to report the loaded `@glockyco/personal-omp-plugin` source path, quote the personal policy, and call `personal_commit` with `action=preview`. The path must be under `/nix/store`, the policy must be available, and preview must not change the repository.

A workflow-only or documentation-only change does not need a model-backed smoke. It still needs both repository checks.

## Rollback

Keep the previous Nix generation until activation and every required smoke pass. List generations without a pager:

```sh
sudo darwin-rebuild --list-generations | cat
```

Restore the immediately previous generation:

```sh
sudo darwin-rebuild --rollback
```

Or select a retained generation:

```sh
sudo darwin-rebuild --switch-generation <number>
```

Then run `omp --version`, `herdr integration status`, and any required real-session smoke again. Rollback changes immutable package paths. It does not copy, restore, or delete OMP-owned authentication, preferences, sessions, history, caches, logs, or databases.

## Policy inspection

Inspect remote protection:

```sh
gh api repos/glockyco/omp-agent-setup/branches/main/protection
gh api repos/glockyco/nix-config/branches/main/protection
gh api repos/glockyco/erenshor-data-mining/branches/main/protection
```

Inspect Renovate detection through each repository's Dependency Dashboard. If a flake input appears there, first confirm that `nix.enabled` is still `false`; do not accept overlapping updater ownership.
