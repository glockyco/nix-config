## Context

`broaden-github-git-identity` chose the checkout path as the only identity signal and listed remote-based selection as a non-goal. Its risks section accepted that a GitHub repository cloned outside `~/src/github.com/` keeps the SCCH default. Agents now routinely clone repositories into scratch directories for isolated work, so that accepted risk turned into commits with the work address in public GitHub history.

## Goals / Non-Goals

**Goals:**

- Select the no-reply address for every repository whose remote is on github.com, independent of its location.
- Keep the path condition for repositories in the GitHub tree that have no remote yet.
- Keep the SCCH address as the global default and repository-local overrides as the highest precedence.

**Non-Goals:**

- Change the Mac's identity, which uses the no-reply address globally.
- Change authentication, transport rewrites or credential helpers.

## Decisions

### Add remote conditions beside the path condition

Git's `includeIf "hasconfig:remote.*.url:<pattern>"` includes a file when any configured remote URL matches. Three patterns cover the URL forms that reach github.com: `https://github.com/**`, the scp-like `git@github.com:*/**` and `ssh://git@github.com/**`. A lookalike host such as `github.com.example` does not match. Remote URLs are matched as configured, before `insteadOf` rewrites, so the SSH forms stay listed even though Korolev fetches over HTTPS.

The path condition stays because a repository created with `git init` below `~/src/github.com/` has no remote until its first push, and its first commit must already use the no-reply address. Replacing the global default with the no-reply address was rejected because SCCH work repositories outside any GitHub remote would then need their own condition.

### Verify effective identities in the existing fixture

The chezmoi fixture already creates disposable repositories and reads Git's effective `user.email`. It gains repositories outside the GitHub tree with GitHub remotes in each URL form and one with a gitlab.scch.at remote, so the test checks Git's real include evaluation.

## Risks / Trade-offs

- A repository outside the GitHub tree that has both a GitHub remote and an SCCH remote uses the no-reply address. A repository-local override handles that exception.
- Git versions before 2.36 ignore `hasconfig` conditions and fall back to the path rule.
