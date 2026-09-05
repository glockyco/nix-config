# Dependency Updates

Use this runbook for release acceptance, OMP version recovery, or external authorization repair.
Routine [updates](../../README.md#update), [release gates](../../README.md#develop), [activation](../../README.md#activate), and [Nix rollback](../../README.md#recover) have one README owner.
Keep the previous Nix generation until activation verification and every required smoke pass.

## Ownership and release order

The README identifies automated owners and schedules. Neither updater merges pull requests.
The [central controller](https://github.com/glockyco/dependency-automation#operations) owns manual dispatch, run inspection, and [App key rotation](https://github.com/glockyco/dependency-automation#key-rotation).
Target repositories hold no App credential. Do not enable a second Nix updater or Renovate's Nix manager.

Use the existing [plugin release procedure](https://github.com/glockyco/omp-agent-setup#release-flow) and [Erenshor dependency procedure](https://github.com/glockyco/erenshor-data-mining#dependency-maintenance).
Publish a verified plugin revision before advancing `personal-omp-plugin` here. Do not install it through OMP's mutable plugin manager.
After an OpenSpec update, regenerate adapters in the plugin repository with `nix run .#sync-openspec-adapters` before advancing its pin here.

For an artifact update, change the version, platform asset selection, and fixed hash together.
Use the [Markdown Oxide](../../packages/markdown-oxide.nix) or [Roslyn](../../packages/roslyn-language-server.nix) declaration.
Never accept changed bytes under an existing hash.
If the plugin selects a different server, publish its verified revision and change the wrapper package selection together.
Do not publish a plugin that selects an unavailable server or retain the previous server as a fallback.

## Release smoke

After activation or an OMP executable change, run `verify-personal-omp`.
It must report the observed OMP version, a plugin path under `/nix/store`, and `omp: current`.
For an `llm-agents`, plugin, wrapper, extension, or OMP executable change, start a fresh wrapped `omp` session in a disposable repository.
Ask it to report the loaded `@glockyco/personal-omp-plugin` source path and quote the personal commit policy.
Then request a `personal_commit` preview with these fields:

```text
action=preview
subject="chore: verify release smoke"
body="The release must prove that the immutable personal commit extension loads without changing repository state."
repo="."
```

The plugin path must be under `/nix/store`, the policy must apply, and preview must leave the repository unchanged.
A workflow-only or documentation-only change needs no model-backed smoke. It still needs every [release gate](../../README.md#develop).
On WSL, repeat the [managed-browser smoke](wsl-omp-bootstrap.md#managed-browser-smoke) after OMP updates, recovery, or browser ABI changes.

For language-server changes, use fresh wrapped sessions at fixed representative project roots on both supported systems.
OMP discovers root markers in its working directory, not child directories.
Supply project SDKs through each project's development environment. A server runtime does not supply the C# SDK.
Require diagnostics for every supported language, plus definition, references, and rename where supported.

For Markdown Oxide, require an unresolved-link diagnostic, a resolved link's definition, and its references.
Rename a note from its body, then verify the filename and referring links.
A rename at a link or heading selects a different target.

For Roslyn, keep OMP responsive during project loading. Record early results separately from authoritative post-load results.
After loading, require a compiler diagnostic, definition, references, and a rename that changes the declaration and its usage.
A missing server, unsupported operation, crash, lost edit, or persistent semantic failure fails acceptance.
Record initialization and post-rename diagnostic failures separately. Successful retries do not erase them.
Do not add sleeps, hidden retries, or timeout overrides to manufacture acceptance.

## OMP version recovery

Nix rollback preserves the platform-owned OMP executable and writable OMP state.
Use the platform installer to recover an earlier release, then repeat [Release smoke](#release-smoke).
Do not delete `~/.omp` or copy credentials, databases, or browser profiles from another host.

On Darwin, Homebrew's [`version-install`](https://docs.brew.sh/Manpage) extracts a release from the [official tap](https://github.com/can1357/homebrew-tap).
Replace `<version>` with the release number without a leading `v`:

```sh
brew unlink can1357/tap/omp
brew version-install can1357/tap/omp <version>
brew link --overwrite --force "omp@<version>"
verify-personal-omp
```

On WSL, use the explicit release tag at the wrapper's fixed target:

```sh
curl -fsSL https://omp.sh/install \
  | PI_INSTALL_DIR="$HOME/.local/lib/oh-my-pi" sh -s -- --binary --ref v<version>
verify-personal-omp
```

## Tailnet authorization recovery

Use this procedure when policy federation fails or its trust configuration changes.
Access to both GitHub repository settings and the Tailscale administration console is required.
The [workflow declaration](../../.github/workflows/tailnet-policy.yml) owns job inputs and deployment conditions, not provider authorization.

Configure separate validation and deployment identities with issuer `https://token.actions.githubusercontent.com`, separate generated audiences, and the shared `TS_TAILNET` value:

| Identity      | GitHub secrets                         | Exact Tailscale scopes                                                     |
| ------------- | -------------------------------------- | -------------------------------------------------------------------------- |
| PR validation | `TS_TEST_OAUTH_ID`, `TS_TEST_AUDIENCE` | `policy_file:read`, `devices:posture_attributes:read`, `devices:core:read` |
| Deployment    | `TS_OAUTH_ID`, `TS_AUDIENCE`           | `policy_file`, `devices:posture_attributes`, `devices:core:read`           |

Read-only validation exposes policy and device information. Public error logs can expose account details.
OIDC issuance alone grants no Tailscale API permission. The provider must enforce this scope separation.

Inspect the repository's subject configuration and immutable identifiers:

```sh
gh api repos/glockyco/nix-config/actions/oidc/customization/sub
gh api repos/glockyco/nix-config --jq '{id, created_at, owner_id: .owner.id}'
```

Compare each live job's actual subject and claims with the saved provider trust.
Do not assume legacy subject strings: GitHub supports immutable-ID subjects and custom templates.
Apply these restrictions with each identity's exact actual `sub`:

| Claim          | PR validation           | Deployment                                                                 |
| -------------- | ----------------------- | -------------------------------------------------------------------------- |
| `repository`   | `glockyco/nix-config`   | `glockyco/nix-config`                                                      |
| `event_name`   | `pull_request`          | `workflow_run`                                                             |
| `base_ref`     | `main`                  | Not applicable                                                             |
| `ref`          | Not constrained to main | `refs/heads/main`                                                          |
| `workflow_ref` | Not constrained to main | `glockyco/nix-config/.github/workflows/tailnet-policy.yml@refs/heads/main` |

Add `repository_id` and `repository_owner_id` from repository metadata where supported.
Use `workflow_ref`, not `job_workflow_ref`: these jobs do not use a reusable workflow.
Never permit a repository-wide wildcard deployment subject. A new GitHub environment requires a coordinated subject update.
Record only selected claims, scopes, issuer, and audience associations. Never log or persist bearer tokens or secret values.
Reopen the saved provider settings and compare them before acceptance.

For a fork PR without secrets, import reviewed changes onto a repository branch for authenticated validation.
Do not skip the required check or use `pull_request_target` to give PR-controlled code deployment authorization.

Before accepting repaired authorization:

1. Run real PR validation with the read-only identity and both native matrix checks.
1. Confirm that the validation token cannot write policy and that deployment rejects the PR token.
1. After review and merge, confirm successful native main checks followed by apply of their exact checked SHA.
1. Confirm that the live policy equals that SHA's rendered policy.
1. Confirm that failed checks and PR completions cannot deploy, and obsolete revisions cannot replace current policy.

Keep GitHub's supported queued concurrency setting even if a pinned local validator does not recognize it.
Require actual GitHub acceptance rather than filtering errors or weakening serialization.
GitHub and Tailscale share no transaction: main can advance after the freshness check, before the provider write.
An active checked apply can finish before a newer checked apply. Queue overflow and manual cancellation can omit intermediate revisions.

Treat console policy edits as emergency actions. Reconcile them through a reviewed PR, because the next GitOps apply replaces them.
See the provider's [scopes](https://tailscale.com/docs/reference/trust-credentials#scopes), [federation](https://tailscale.com/docs/features/workload-identity-federation), and [GitOps](https://tailscale.com/docs/integrations/github/gitops) documentation.
