# Tailnet policy authorization

The [tailnet-policy workflow](../../.github/workflows/tailnet-policy.yml) tests the generated policy in pull requests and applies it after `check` passes on `main`. It authenticates to Tailscale through GitHub OIDC, with issuer `https://token.actions.githubusercontent.com`, the shared `TS_TAILNET` value and two identities:

| Identity      | GitHub secrets                         | Tailscale scopes                                                           |
| ------------- | -------------------------------------- | -------------------------------------------------------------------------- |
| PR validation | `TS_TEST_OAUTH_ID`, `TS_TEST_AUDIENCE` | `policy_file:read`, `devices:posture_attributes:read`, `devices:core:read` |
| Deployment    | `TS_OAUTH_ID`, `TS_AUDIENCE`           | `policy_file`, `devices:posture_attributes`, `devices:core:read`           |

Policy edits in the Tailscale console are emergency changes. The next apply replaces them, so reconcile them through a PR.

## Repair the trust

When federation fails or its trust changes, compare the repository's subject configuration and identifiers with the trust saved in Tailscale:

```sh
gh api repos/glockyco/nix-config/actions/oidc/customization/sub
gh api repos/glockyco/nix-config --jq '{id, created_at, owner_id: .owner.id}'
```

Restrict each identity to its actual `sub` and these claims. Add `repository_id` and `repository_owner_id` where Tailscale supports them.

| Claim          | PR validation         | Deployment                                                                 |
| -------------- | --------------------- | -------------------------------------------------------------------------- |
| `repository`   | `glockyco/nix-config` | `glockyco/nix-config`                                                      |
| `event_name`   | `pull_request`        | `workflow_run`                                                             |
| `base_ref`     | `main`                | Not applicable                                                             |
| `ref`          | Unconstrained         | `refs/heads/main`                                                          |
| `workflow_ref` | Unconstrained         | `glockyco/nix-config/.github/workflows/tailnet-policy.yml@refs/heads/main` |

Use `workflow_ref`, not `job_workflow_ref`, because the jobs do not call a reusable workflow. Never allow a repository-wide wildcard subject for deployment, and never log tokens.

The repair is done when a PR's validation passes but cannot write the policy, deployment rejects the PR token, and after merge the apply job deploys exactly the checked commit.

Pull requests from forks get no secrets. Push reviewed fork changes to a branch of this repository instead of using `pull_request_target`.
