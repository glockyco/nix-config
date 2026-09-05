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

| Repository             | Required checks                                     |
| ---------------------- | --------------------------------------------------- |
| `omp-agent-setup`      | `check (macos-15)`, `check (ubuntu-latest)`         |
| `nix-config`           | `check (macos-15)`, `check (ubuntu-latest)`, `test` |
| `erenshor-data-mining` | `CI Success`                                        |

Main also requires a current pull-request branch and linear history. The policy applies to administrators. Force-push and branch deletion are disabled.

GitHub accepted the `nix-config` main protection settings on 2026-09-05. All three required checks are bound to the GitHub Actions app, ID `15368`. The `test` check is the PR policy validation job, not the deployment job. Strict status checks require an up-to-date PR branch. Main also requires a pull request and resolved review conversations.

The repository has one owner, so the required approval count is zero. Owner review remains procedural, not an independently enforced approval. Before merge, the owner must inspect the complete diff, workflow changes, and check results. Administrator enforcement blocks normal bypass, but an administrator can still change protection settings.

## Tailnet policy release

### Source behavior

`.github/workflows/tailnet-policy.yml` validates every PR to main without path filters. The `test` job uses `TS_TEST_OAUTH_ID` and `TS_TEST_AUDIENCE`, with no fallback to deployment credentials. Missing credentials fail the required check. Each PR has its own cancellable concurrency group.

The `apply` job follows a successful `check` workflow completed from a push to main in this repository. PR checks, failed checks, and checks from another repository cannot authorize apply. Checkout uses that run's exact `head_sha`, with credential persistence disabled. The job renders the policy from that checked revision rather than downloading an upstream workflow artifact.

Apply jobs share one concurrency group with `cancel-in-progress: false` and `queue: max`. Immediately before the provider write, the job queries current main under `set -euo pipefail`. It applies only when main equals the checked SHA. An obsolete revision is skipped; an API error fails the job.

Serialization prevents overlapping writes and automatic cancellation of an active apply. It does not guarantee deployment of every intermediate revision. GitHub queues up to 100 pending jobs; overflow and manual cancellation remain possible. Main can advance after the freshness query because GitHub and Tailscale do not share a transaction. The active checked apply can finish before a newer checked apply.

### Provider authorization

Both identities use issuer `https://token.actions.githubusercontent.com`, separate generated audiences, and the shared `TS_TAILNET` value. GitHub grants `contents: read` by default and `id-token: write` separately to each job. OIDC issuance does not grant Tailscale API permissions. Provider scopes and claim restrictions enforce the read/write boundary, not the action's `test` input.

| Purpose       | Repository inputs                      | Exact Tailscale scopes                                                     |
| ------------- | -------------------------------------- | -------------------------------------------------------------------------- |
| PR validation | `TS_TEST_OAUTH_ID`, `TS_TEST_AUDIENCE` | `policy_file:read`, `devices:posture_attributes:read`, `devices:core:read` |
| Deployment    | `TS_OAUTH_ID`, `TS_AUDIENCE`           | `policy_file`, `devices:posture_attributes`, `devices:core:read`           |

`policy_file:read` permits policy reads, previews, and validation, but not a live policy write. `policy_file` adds the live write operation. Read-only validation still exposes policy and device information. Provider errors in public workflow logs can expose account details.

Configure each identity with its exact actual subject and all corresponding claim restrictions:

| Claim          | PR validation                        | Deployment                                                                 |
| -------------- | ------------------------------------ | -------------------------------------------------------------------------- |
| `sub`          | Actual pull-request subject          | Actual main-branch subject                                                 |
| `repository`   | `glockyco/nix-config`                | `glockyco/nix-config`                                                      |
| `event_name`   | `pull_request`                       | `workflow_run`                                                             |
| `base_ref`     | `main`                               | Not applicable                                                             |
| `ref`          | Not constrained to main              | `refs/heads/main`                                                          |
| `workflow_ref` | Not constrained to the main revision | `glockyco/nix-config/.github/workflows/tailnet-policy.yml@refs/heads/main` |

Add `repository_id` and `repository_owner_id` restrictions from repository metadata where supported. Use `workflow_ref`, not `job_workflow_ref`, because these jobs do not use a reusable workflow. Do not permit a repository-wide wildcard subject on the deployment identity.

Inspect the subject configuration and immutable repository metadata before configuring provider trust:

```sh
gh api repos/glockyco/nix-config/actions/oidc/customization/sub
gh api repos/glockyco/nix-config --jq '{id, created_at, owner_id: .owner.id}'
```

Legacy default subjects are `repo:glockyco/nix-config:pull_request` and `repo:glockyco/nix-config:ref:refs/heads/main`. They are examples, not verified subjects for this repository. GitHub can use immutable-ID subject formats or custom subject templates. Inspect the existing Tailscale trust configuration and compare each live job's actual `sub` and restricted claims before accepting federation. Record only the selected claims, scope names, issuer, and audience association; never log or persist a bearer token or secret value. Adding a GitHub environment changes the subject and requires a coordinated trust update.

Fork PRs normally cannot access these repository secrets. Import reviewed fork changes onto a repository branch for authenticated validation. Do not skip the required check or use `pull_request_target` to run PR-controlled code with deployment authorization.

### External acceptance

On 2026-09-05, the authenticated Tailscale console saved both separate identities with the scopes above. The deployment subject is `repo:glockyco@11704293/nix-config@1327005249:ref:refs/heads/main`; the PR subject is `repo:glockyco@11704293/nix-config@1327005249:pull_request`. Both restrict `repository_id` to `1327005249` and `repository_owner_id` to `11704293`, in addition to the claim table. Their persisted settings were reopened and inspected. All four identity/audience references were set in GitHub secrets; `TS_TAILNET` was retained.

This proves configured provider restrictions, not live token exchange or deployment. PR write-denial, successful validation with the read-only identity, and actual checked-main deployment remain acceptance gates. Secret names alone do not establish those results.

The pinned `actionlint` rejects `concurrency.queue`. GitHub's [current concurrency documentation](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency) supports `queue: max` with active cancellation disabled. Keep the supported setting and require actual GitHub acceptance; do not filter validator errors or weaken the queue to manufacture a clean lint result.

Before accepting the release path:

1. Provision the read-only identity and its `TS_TEST_*` inputs with the exact scopes and claims above.
1. Restrict the existing deployment identity to its separate scopes, audience, subject, and claims.
1. Confirm that PR-issued credentials cannot authorize policy writes or authenticate as the deployment identity.
1. Run a real PR validation and record the successful GitHub Actions `test` check alongside both native matrix checks.
1. After review and merge, record successful native main checks followed by apply of their exact checked SHA.
1. Confirm that the live policy equals that SHA's rendered policy.
1. Confirm that failed checks and PR check completions cannot deploy, and that obsolete revisions cannot replace current policy.

The Tailscale console's prevent-edits setting points to this repository, but an authorized administrator can override it. Treat such edits as break-glass actions and reconcile them through a reviewed PR. A later GitOps apply replaces console changes.

Provider details: [Tailscale scopes](https://tailscale.com/docs/reference/trust-credentials#scopes), [federation](https://tailscale.com/docs/features/workload-identity-federation), and [GitOps](https://tailscale.com/docs/integrations/github/gitops). GitHub details: [OIDC claims](https://docs.github.com/en/actions/reference/security/oidc), [workflow_run security](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_run), and [concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency).

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

For a Herdr or OpenSpec update, update the shared package source:

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
nix eval --raw .#packages.aarch64-darwin.openspec.version
nix flake metadata --json | jq -r '.locks.nodes["personal-omp-plugin"].locked.rev'
```

Do not install the personal plugin through OMP's mutable plugin manager.

## Manual language-server artifact update

`packages/markdown-oxide.nix` downloads the official [Markdown Oxide releases](https://github.com/Feel-ix-343/markdown-oxide/releases). `packages/roslyn-language-server.nix` downloads Microsoft's official platform tool packages from [NuGet](https://www.nuget.org/profiles/roslyn-language-server). Both package files contain explicit asset selections for `aarch64-darwin` and `x86_64-linux`.

Change a package's version, platform asset name or runtime identifier, and fixed hash together. Never update only a URL or accept a changed artifact under an existing hash. Verify `markdown-oxide --version` and Roslyn initialization on both supported systems.

A Markdown server update also crosses the personal-plugin release boundary:

1. Change the Markdown server definition in `omp-agent-setup`.
1. Run the plugin checks and the representative Markdown smoke with the candidate workstation package.
1. Publish the verified plugin revision.
1. Pin that revision in `nix-config` in the same commit that changes the wrapper package selection.

Do not publish a plugin revision that selects a server the wrapper does not provide. Do not retain the previous server as an alias or fallback.

After a Markdown Oxide or Roslyn update, use fresh wrapped OMP sessions on both `aarch64-darwin` and `x86_64-linux`. In a fixed Markdown project, require an unresolved-link diagnostic, follow a resolved link to its definition, find its references, and rename its target. In a fixed C# project, require a compiler diagnostic, go to a symbol definition, find its references, and rename it. A missing server or unsupported operation fails the smoke.

## Manual OMP update

OMP updates do not change the repository or require Nix activation. The existing Nix wrapper immediately uses the updated platform executable with the same immutable personal plugin.

On Darwin, install or update the official formula:

```sh
brew install can1357/tap/omp
brew update
brew upgrade can1357/tap/omp
verify-personal-omp
```

Homebrew can recover an earlier release from the official tap history. Replace `<version>` with the release number without a leading `v`:

```sh
brew unlink can1357/tap/omp
brew version-install can1357/tap/omp <version>
brew link --overwrite --force "omp@<version>"
verify-personal-omp
```

On NixOS/WSL, install or update the official prebuilt binary at the wrapper's fixed target:

```sh
curl -fsSL https://omp.sh/install \
  | PI_INSTALL_DIR="$HOME/.local/lib/oh-my-pi" sh -s -- --binary
verify-personal-omp
```

To recover an earlier WSL release, include its tag. This command writes the same target and does not build from source:

```sh
curl -fsSL https://omp.sh/install \
  | PI_INSTALL_DIR="$HOME/.local/lib/oh-my-pi" sh -s -- --binary --ref v<version>
verify-personal-omp
```

After each OMP update or recovery, run the real wrapped-session smoke below. Nix generation rollback does not change the platform-owned OMP executable.

## Activation and smoke

Merging changes does not update the workstation. Activate deliberately:

```sh
darwin-switch
```

Read the activation output, then run the explicit verifier:

```sh
verify-personal-omp
```

It must report:

- the observed platform-owned OMP version;
- a personal plugin path under `/nix/store`;
- `omp: current` from Herdr.

For an `llm-agents`, personal plugin, wrapper, or extension behavior change, start a fresh wrapped OMP session. Ask it to report the loaded `@glockyco/personal-omp-plugin` source path, quote the personal policy, and call `personal_commit` with `action=preview`. The path must be under `/nix/store`, the policy must be available, and preview must not change the repository.

A workflow-only or documentation-only change does not need a model-backed smoke. It still needs both native matrix checks and the policy `test` check.

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

Then run `verify-personal-omp` and any required real-session smoke again. Rollback changes the immutable wrapper, plugin, Herdr, OpenSpec, and language-server paths. It does not change the platform-owned OMP executable or copy, restore, or delete OMP-owned runtime state. Use the platform recovery command above to change the OMP version.

## Policy inspection

Inspect remote protection:

```sh
gh api repos/glockyco/omp-agent-setup/branches/main/protection
gh api repos/glockyco/nix-config/branches/main/protection
gh api repos/glockyco/erenshor-data-mining/branches/main/protection
```

Inspect Renovate detection through each repository's Dependency Dashboard. If a flake input appears there, first confirm that `nix.enabled` is still `false`; do not accept overlapping updater ownership.
